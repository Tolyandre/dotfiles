{ config, pkgs, ... }:
{
  services.seafile = {
    enable = true;

    adminEmail = "tolyandre@yandex.ru";
    initialAdminPassword = "change this later!";

    ccnetSettings.General.SERVICE_URL = "https://nextcloud.toly.is-cool.dev";

    seafileSettings = {
      fileserver = {
        host = "unix:/run/seafile/server.sock";
      };
    };

    dataDir = "/mnt/data/seafile";
  };
}
