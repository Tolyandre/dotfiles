{ config, pkgs, ... }:
{
  # To validate this configuration, run:
  # sudo rsnapshot configtest
  # sudo rsnapshot -t daily

  # show disk usage:
  # sudo rsnapshot du

  services.rsnapshot = {
    enable = true;
    cronIntervals = {
      # At 02:50
      daily = "50 02 * * *";
    };

    # Note that tabs are required to separate option arguments, and
    # directory names require trailing slashes.
    extraConfig = ''
      # Run detail (rotation steps, per-backup-point rsync warnings, completion
      # status). Fatal errors and the final status ALSO go to syslog and show up
      # in the journal under tag rsnapshot[<pid>]; without this file the per-run
      # detail only lands in root's cron mail. /var/log instead of the seagate
      # so failures still get logged when the nofail USB mount is unplugged.
      # ~30 lines/day at the default loglevel 3; no logrotate needed.
      logfile	/var/log/rsnapshot.log

      snapshot_root	/mnt/seagate/Backup/rsnapshots/
      retain	daily	30

      backup	/home/game/.wine/drive_c/users/	game/
      backup	/home/game/.local/share/lutris	game/

      backup	/mnt/data/immich/backups	immich/
      backup	/mnt/data/immich/library	immich/
      backup	/mnt/data/immich/profile	immich/
      backup	/mnt/data/immich/upload	immich/

      backup	/var/lib/ocis	ocis/

      backup	/mnt/data/media_lib/	media_lib/

      # Whole home dir, including Trash. Exclude caches, toolchains and other
      # reproducible/large dirs. Patterns are anchored to the source root with
      # a leading "/" so they only match at the top of /home/toly.
      # Excludes are grouped: requested, language toolchains/registries,
      # editor extensions, then anything named node_modules anywhere.
      # NOTE: rsnapshot has NO line continuation; each backup point must be a
      # single physical line. Extra per-point options are ONE tab-separated
      # field holding COMMA-separated key=value pairs: rsnapshot reads only
      # the 4th tab field as the option string (and re-splits on whitespace),
      # so tab-separated excludes silently turn into bogus rsync source paths
      # (rsync exit 23, "transferred partially", every night).
      backup	/home/toly/	toly/	exclude=/.cache,exclude=/.local/share/Steam,exclude=/go,exclude=/.bun,exclude=/.cargo,exclude=/.npm,exclude=/.nuget,exclude=/.dotnet,exclude=/.gradle,exclude=/.m2,exclude=/.thumbnails,exclude=node_modules

      backup	/my-secrets	my-secrets/
    '';
  };
}
