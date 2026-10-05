{ config, pkgs, elo, ... }:
let
  # The homepage's elo links are substituted from the instances' typed
  # basePath options, so renaming a mount path updates the links too.
  homepage = pkgs.linkFarm "caddy-homepage" [
    {
      name = "index.html";
      path = pkgs.replaceVars ./index.html {
        elo_base_path = config.services.elo-frontend.instances."elo".basePath;
        elo_stage_base_path = config.services.elo-frontend.instances."elo-stage".basePath;
      };
    }
  ];
in
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

        # elo prod + stage: backend reverse-proxy + static frontend, generated
        # by elo.lib.caddySite (precise, non-overlapping path matchers).
        ${elo.lib.caddySite {
          backendAddress = config.services.elo-web-service.instances."elo-web-service".settings.address;
          frontendRoot = config.services.elo-frontend.instances."elo".out;
        }}

        ${elo.lib.caddySite {
          name = "elo-stage";
          basePath = "/elo-stage";
          apiPath = "/elo-web-service-stage";
          backendAddress = config.services.elo-web-service.instances."elo-web-service-stage".settings.address;
          frontendRoot = config.services.elo-frontend.instances."elo-stage".out;
        }}

        handle /music* {
          reverse_proxy 127.0.0.1:${toString config.services.navidrome.settings.Port}
        }

        root * ${homepage}
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
