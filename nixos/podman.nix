{ config, pkgs, ... }:
{
  virtualisation = {
    podman = {
        enable = true;
        dockerCompat = true;
      };

    containers = {
      policy = {
        default = [ { type = "insecureAcceptAnything"; } ];
        transports = {
          docker-daemon = {
            "" = [ { type = "insecureAcceptAnything"; } ];
          };
        };
      };
      registries = {
        search = [
          "docker.io"
          "quay.io"
        ];
      };
    };
  };
}