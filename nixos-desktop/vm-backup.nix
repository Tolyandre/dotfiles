{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Read-only, crash-consistent snapshot of the VM images subvolume, recreated
  # by preStart before each restic run. restic reads from it, so a running VM
  # cannot produce a torn image; the copy on the seagate is the real backup.
  # The latest snapshot also stays around between runs as a same-disk
  # point-in-time rollback (delete a VM by accident -> restore from
  # /mnt/data/.snapshots/vms-current without touching the seagate).
  snapshot = "/mnt/data/.snapshots/vms-current";
  repo = "/mnt/seagate/Backup/restic/vms";
  btrfs = "${pkgs.btrfs-progs}/bin/btrfs";
  restic = "${pkgs.restic}/bin/restic";

  # Passwordless repository: restic 0.18 supports unencrypted repos via
  # --insecure-no-password, which must be passed to EVERY command, so the
  # declarative services.restic.backups module (which insists on a password
  # file) cannot express this. Privacy comes from filesystem permissions
  # instead: the repo directory is root-only (0700, enforced in preStart),
  # same as the images in /mnt/data/vms (see vm.nix). This protects against
  # other local accounts, NOT against theft of the USB drive itself.
  flag = "--insecure-no-password --repo ${repo}";
in
{
  # VM images live on btrfs (see vm.nix), so each nightly backup is:
  #   btrfs snapshot (instant, crash-consistent) -> restic -> USB HDD.
  # The seagate is ext4; restic adds block-level incrementals, checksums and
  # retention on top of it. Only VM storage is covered here; the rsnapshot
  # backup in backup.nix keeps running for everything else and can be migrated
  # to restic later.
  systemd.services."restic-backups-vms" = {
    description = "Nightly restic backup of VM images to the seagate";
    # Seagate is a nofail mount: if it's unplugged the service fails cleanly
    # and the next timer run (or Persistent catch-up) retries.
    unitConfig.RequiresMountsFor = "/mnt/data /mnt/seagate";

    environment.RESTIC_CACHE_DIR = "/var/cache/restic-backups-vms";
    serviceConfig = {
      Type = "oneshot";
      CacheDirectory = "restic-backups-vms";
      CacheDirectoryMode = "0700";
    };

    preStart = ''
      # Drop the previous snapshot. It is read-only, so flip it back first;
      # both no-ops on the very first run.
      ${btrfs} property set ${snapshot} ro false 2>/dev/null || true
      ${btrfs} subvolume delete ${snapshot} 2>/dev/null || true
      ${btrfs} subvolume snapshot -r /mnt/data/vms ${snapshot}

      # Keep the repo root-only regardless of the seagate's default perms.
      mkdir -p ${repo}
      chmod 700 ${repo}
      ${restic} ${flag} cat config > /dev/null 2>&1 || ${restic} ${flag} init
    '';

    script = ''
      # don't let a suspend interrupt a long backup
      INH() {
        ${pkgs.systemd}/bin/systemd-inhibit --mode=block --who=restic --what=sleep --why="Scheduled VM backup" "$@"
      }
      INH ${restic} ${flag} backup ${snapshot}
      INH ${restic} ${flag} unlock
      INH ${restic} ${flag} forget --prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6
      INH ${restic} ${flag} check
    '';
  };

  systemd.timers."restic-backups-vms" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # after rsnapshot's daily (02:50), before the 06:00-07:00 reboot window
      OnCalendar = "04:00";
      Persistent = true;
    };
  };

  # Wrapper for manual restic use against the VM repo (runs as root only).
  #
  #   sudo systemctl start restic-backups-vms                # run a backup now
  #   sudo restic-vms snapshots                              # list backup sets
  #   sudo restic-vms restore latest --target /tmp/restore   # restore everything
  #   sudo restic-vms restore latest \
  #     --include /mnt/data/.snapshots/vms-current/win.qcow2 --target /tmp/restore
  #   sudo restic-vms mount /mnt/tmp                         # browse as a filesystem
  #                                                          # (Ctrl-C to exit)
  #   sudo restic-vms check --read-data                      # full integrity scan (slow)
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "restic-vms" ''
      exec ${restic} ${flag} "$@"
    '')
  ];
}
