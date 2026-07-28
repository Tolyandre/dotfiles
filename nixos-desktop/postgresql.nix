{ config, pkgs, ... }:
let
  # All backups land here (same path the old postgresqlBackup used).
  backupLocation = "/mnt/seagate/Backup/postgresql";
  # How many days of dated dumps to keep; older files are pruned each run.
  retentionDays = 14;
in
{
  # postgres is a dependency for immich
  services.postgresql = {
    enable = true;
  };

  # After a glibc upgrade the OS collation version (e.g. 2.42) no longer matches
  # the version recorded when the cluster's databases were created (e.g. 2.40).
  # PostgreSQL then refuses `CREATE DATABASE` (which clones template1), which
  # breaks `postgresql-setup.service` whenever a NEW database is provisioned
  # (e.g. adding the elo stage instance). Refresh the *template* databases'
  # recorded collation version before setup runs so new-database creation keeps
  # working. This is idempotent (a no-op once versions already match) and only
  # touches the empty system/template databases — data-bearing databases must be
  # REINDEXed before refreshing and are intentionally left out here.
  systemd.services.postgresql-refresh-collation = {
    description = "Refresh template/system DB collation versions";
    after = [ "postgresql.service" ];
    before = [ "postgresql-setup.service" ];
    requiredBy = [ "postgresql-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      ExecStart = ''
        ${config.services.postgresql.package}/bin/psql -v ON_ERROR_STOP=1 -d postgres \
          -c "ALTER DATABASE template1 REFRESH COLLATION VERSION;" \
          -c "ALTER DATABASE postgres REFRESH COLLATION VERSION;"
      '';
    };
  };

  /*
    How to create user and reset password:

    sudo -u postgres psql
    CREATE ROLE dbeaver WITH LOGIN;
    ALTER ROLE dbeaver WITH SUPERUSER;
    ALTER ROLE dbeaver WITH PASSWORD 'ваш_пароль';
  */

  # Ensure the backup dir exists, owned by postgres, mode 0700 (idempotent;
  # does not delete existing contents — the old all.sql.gz stays put).
  systemd.tmpfiles.rules = [ "d ${backupLocation} 0700 postgres postgres -" ];

  /*
    PostgreSQL backup strategy
    ==========================
    Replaces the built-in services.postgresqlBackup, which produced a single
    `all.sql.gz` via `pg_dumpall` with only current + `.prev` retention and no
    way to restore a single database.

    Nightly this service produces, under ${backupLocation}:
      - globals-<date>.sql.gz   roles/tablespaces via `pg_dumpall --globals-only`
      - <db>-<date>.dump        every non-system DB via `pg_dump -Fc` (custom format)

    Why `pg_dump -Fc` (custom format):
      - single compressed file restored with `pg_restore` (no extra gzip needed)
      - parallel restore for large DBs:   pg_restore -j 4 <db>-<date>.dump
      - selective restore via TOC:        pg_restore -l  (list)  /  -L (use list)
      - restore into a DIFFERENT name:    pg_restore -d <newname> --no-owner
      - filter by table/schema:           pg_restore --table=... --schema=...

    Each dump is written to a `.in-progress` file and atomically renamed on
    success, so a failed run never replaces a good previous backup. A failed
    database is skipped (others still get backed up); the service exits
    non-zero so failures are visible in `systemctl status` / journalctl.
    Dumps older than ${toString retentionDays} days are pruned each run.

    ---- Restore recipes (run as the postgres OS user) ----

    # Restore DB `mydb` into a NEW database `mydb_copy`:
      sudo -u postgres createdb mydb_copy
      sudo -u postgres pg_restore --no-owner --role=postgres -d mydb_copy \
        ${backupLocation}/mydb-2026-07-26.dump

    # Restore DB `mydb` to the SAME name (drop + recreate):
      sudo -u postgres pg_restore --create --clean --if-exists -d postgres \
        ${backupLocation}/mydb-2026-07-26.dump

    # Restore a single table:
      sudo -u postgres pg_restore --table=mytable -d mydb \
        ${backupLocation}/mydb-2026-07-26.dump

    # List a dump's contents (table of contents), no restore:
      sudo -u postgres pg_restore -l ${backupLocation}/mydb-2026-07-26.dump

    # Selective restore: list -> edit (prefix `;` to skip lines) -> restore:
      sudo -u postgres pg_restore -l ${backupLocation}/mydb-2026-07-26.dump > toc.list
      sudo -u postgres pg_restore -L toc.list -d mydb

    # Restore roles/tablespaces (globals):
      zcat ${backupLocation}/globals-2026-07-26.sql.gz | sudo -u postgres psql
  */
  systemd.services.postgresql-backup = {
    description = "PostgreSQL per-database backup (pg_dump -Fc)";
    requires = [ "postgresql.target" ];
    after = [ "postgresql.service" ];

    # Nightly, same time the old postgresqlBackup used.
    startAt = "*-*-* 01:15:00";

    serviceConfig = {
      Type = "oneshot";
      User = "postgres";
      Group = "postgres";
      # Dumps contain real data — keep them readable only by postgres.
      UMask = "0077";
    };

    path = [
      config.services.postgresql.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.gzip
    ];

    script = ''
      set -uo pipefail

      date="$(date +%F)"
      failed=0

      # Clear any .in-progress leftovers from a previously interrupted run.
      find "${backupLocation}" -maxdepth 1 -type f -name '*.in-progress' -delete 2>/dev/null || true

      # 1. Global objects (roles, tablespaces). `pg_dump` per-DB does NOT
      #    capture these, so we keep a small gzipped SQL dump alongside.
      globals_inprogress="${backupLocation}/globals-$date.sql.gz.in-progress"
      if pg_dumpall --globals-only | gzip -c > "$globals_inprogress"; then
        mv "$globals_inprogress" "${backupLocation}/globals-$date.sql.gz"
      else
        echo "WARNING: globals dump failed; continuing with per-DB dumps" >&2
        rm -f "$globals_inprogress"
        failed=1
      fi

      # 2. Every non-system database (excludes templates and the default
      #    `postgres` DB). To exclude specific DBs, add them to the WHERE.
      dbs="$(psql -At -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname <> 'postgres' ORDER BY datname;")"

      for db in $dbs; do
        echo "Dumping database: $db"
        db_inprogress="${backupLocation}/$db-$date.dump.in-progress"
        if pg_dump -Fc -Z 6 -f "$db_inprogress" "$db"; then
          mv "$db_inprogress" "${backupLocation}/$db-$date.dump"
        else
          echo "WARNING: failed to dump '$db' (previous backup retained)" >&2
          rm -f "$db_inprogress"
          failed=1
        fi
      done

      # 3. Retention: prune dumps and globals older than ${toString retentionDays}
      #    days — but ONLY on a fully successful run. If anything failed we keep
      #    every old file so there is always a known-good backup to fall back to.
      if [ "$failed" -eq 0 ]; then
        find "${backupLocation}" -maxdepth 1 -type f -name '*.dump' -mtime +${toString retentionDays} -delete
        find "${backupLocation}" -maxdepth 1 -type f -name 'globals-*.sql.gz' -mtime +${toString retentionDays} -delete
      else
        echo "Skipping retention prune because the run had failures (old backups preserved)" >&2
      fi

      exit $failed
    '';
  };
}
