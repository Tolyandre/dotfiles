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

        # Precise (non-overlapping) matchers so /elo, /elo-stage, /elo-web-service
        # and /elo-web-service-stage never swallow one another.
        @elo-api path /elo-web-service /elo-web-service/*
        handle @elo-api {
          uri strip_prefix /elo-web-service
          reverse_proxy http://${config.services.elo-web-service.instances."elo-web-service".settings.address}
        }

        @elo-stage-api path /elo-web-service-stage /elo-web-service-stage/*
        handle @elo-stage-api {
          uri strip_prefix /elo-web-service-stage
          reverse_proxy http://${config.services.elo-web-service.instances."elo-web-service-stage".settings.address}
        }

        # Static frontends (Next.js export). try_files reproduces GitHub Pages'
        # clean-URL behaviour (/players -> players.html).
        @elo-ui path /elo /elo/*
        handle @elo-ui {
          uri strip_prefix /elo
          root * ${config.services.elo-frontend.instances."elo".out}
          try_files {path} {path}.html {path}/index.html /index.html
          file_server
        }

        @elo-stage-ui path /elo-stage /elo-stage/*
        handle @elo-stage-ui {
          uri strip_prefix /elo-stage
          root * ${config.services.elo-frontend.instances."elo-stage".out}
          try_files {path} {path}.html {path}/index.html /index.html
          file_server
        }

        handle /music* {
          reverse_proxy 127.0.0.1:${toString config.services.navidrome.settings.Port}
        }

        root * /dotfiles-repo/nixos-desktop/caddy
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
