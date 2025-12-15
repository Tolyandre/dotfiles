{ config, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.ocis
    pkgs.owncloud-client
  ];

  # maintainance note:

  # Before init or reset password, stop the service:
  # sudo systemctl stop ocis.service

  # init
  # sudo rm /var/lib/ocis/config/ocis.yaml
  # sudo -u ocis OCIS_CONFIG_DIR=/var/lib/ocis/config OCIS_BASE_DATA_PATH=/var/lib/ocis ocis init

  # Reset admin password:
  # sudo -u ocis OCIS_CONFIG_DIR=/var/lib/ocis/config OCIS_BASE_DATA_PATH=/var/lib/ocis ocis idm resetpassword

  services.ocis = {
    enable = true;
    address = "localhost";
    port = 9200;
    stateDir = "/var/lib/ocis";
    configDir = "/var/lib/ocis/config";
    environment = {
      PROXY_TLS = "false";
      OCIS_URL = "https://nextcloud.toly.is-cool.dev";
      OCIS_EXCLUDE_RUN_SERVICES = "notifications";
    };
  };
}
