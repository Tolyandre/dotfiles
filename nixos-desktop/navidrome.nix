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
}