{ config, pkgs, ... }:
{
  services.caddy = {
    enable = true;

    extraConfig = ''
      https://nextcloud.toly.is-cool.dev {
        reverse_proxy http://localhost:${toString config.services.ocis.port}
      }

      http://,
      https://toly.is-cool.dev
      {
        handle /guacamole* {
          reverse_proxy http://localhost:${toString config.services.tomcat.port}
        }

        handle_path /elo-web-service* {
          reverse_proxy http://${config.services.elo-web-service.config.address}
        }

        root * /dotfiles-repo/nixos/caddy
        handle_path /index.html
        file_server
      }

      https://open-webui.toly.is-cool.dev
      {
        reverse_proxy ${config.services.open-webui.host}:${toString config.services.open-webui.port}
      }

      https://immich.localhost,
      https://661606e8c73b.sn.mynetname.net,
      https://immich.toly.is-cool.dev
      {
        reverse_proxy ${config.services.immich.host}:${toString config.services.immich.port}
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
