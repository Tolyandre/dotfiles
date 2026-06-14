{ config, pkgs, ... }:
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

  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    location = "/mnt/seagate/Backup/postgresql";
  };
}
