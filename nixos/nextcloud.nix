{ config, pkgs, ... }:
{
  imports = [
    "${
      fetchTarball {
        url = "https://github.com/onny/nixos-nextcloud-testumgebung/archive/fa6f062830b4bc3cedb9694c1dbf01d5fdf775ac.tar.gz";
        sha256 = "0gzd0276b8da3ykapgqks2zhsqdv4jjvbv97dsxg0hgrhb74z0fs";
      }
    }/nextcloud-extras.nix"
  ];

  # TODO: secrets
  environment.etc."nextcloud-admin-pass".text = "PWD";

  services.nextcloud = {
    settings =
      let
        prot = "https";
        host = "nextcloud.toly.is-cool.dev";
        dir = "";
      in
      {
        overwriteprotocol = prot;
        overwritehost = host;
        overwritewebroot = dir;
        overwrite.cli.url = "${prot}://${host}${dir}/";
        htaccess.RewriteBase = dir;
      };

    enable = false;
    webserver = "caddy";
    package = pkgs.nextcloud31;
    https = true;
    hostName = "nextcloud.toly.is-cool.dev";
    config.adminpassFile = "/etc/nextcloud-admin-pass";
    config.dbtype = "sqlite";
  };
}
