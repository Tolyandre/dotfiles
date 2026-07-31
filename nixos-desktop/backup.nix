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
      # single physical line with arguments separated by tabs.
      backup	/home/toly/	toly/	exclude=/.cache	exclude=/.local/share/Steam	exclude=/go	exclude=/.bun	exclude=/.cargo	exclude=/.npm	exclude=/.nuget	exclude=/.dotnet	exclude=/.gradle	exclude=/.m2	exclude=/.thumbnails	exclude=node_modules

      backup	/my-secrets	my-secrets/
    '';
  };
}
