{ config, pkgs, ... }:
{
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
        retain	daily	6
        backup	/home/game/.wine/drive_c/users/	game/
        backup	/home/game/.local/share/lutris	game/
      '';
  };
}
