{ config, pkgs, ... }:

{
  services.navidrome = {
    enable = true;

    settings = {
      Address = "127.0.0.1";
      Port = 4533;

      MusicFolder = "/mnt/seagate/Music/Долго_хранящееся/";
      DataFolder = "/var/lib/navidrome";

      BaseURL = "https://toly.is-cool.dev/music";
    };
  };

  # This allows to add a new librery in UI inside the specified path
  # https://github.com/navidrome/navidrome/issues/4595#issuecomment-4359353132
  systemd.services.navidrome.serviceConfig.BindReadOnlyPaths = [
    "/mnt/seagate/Music"
  ];
}
