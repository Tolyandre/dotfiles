{ config, pkgs, ... }:
{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };

    # see also nixos/home-toly/podman.nix
    containers = {
      enable = true;
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

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
