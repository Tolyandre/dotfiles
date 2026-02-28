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

      backup	/home/toly/Documents/	toly/
      backup	/home/toly/Downloads/	toly/
      backup	/home/toly/Repo/	toly/

      backup	/my-secrets	my-secrets/
    '';
  };
}
