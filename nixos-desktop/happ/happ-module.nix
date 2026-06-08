{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.happ;
  happ-package = pkgs.callPackage ./happ.nix { };
in
{
  options.services.happ = {
    enable = mkEnableOption "Happ proxy client and background TUN daemon";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      happ-package
      pkgs.net-tools
      pkgs.lsb-release
    ];

    # Happ has hardcoded /opt/happ paths in its binaries — copy from the Nix store at activation.
    system.activationScripts.setupHapp = stringAfter [ "stdio" ] ''
      mkdir -p /opt
      rm -rf /opt/happ
      cp -r ${happ-package}/happ /opt/happ
      chmod -R 777 /opt/happ
    '';

    # TUN mode requires loose reverse-path filtering.
    networking.firewall.checkReversePath = "loose";
    networking.firewall.trustedInterfaces = [ "tun0" ];

    # happd manages TUN interfaces and must run as root.
    systemd.services.happd = {
      description = "Happ Process Control Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [
        iproute2
        iptables
        procps
        net-tools
      ];

      serviceConfig = {
        Type = "simple";
        User = "root";
        Group = "root";
        ExecStart = "/opt/happ/bin/happd";
        Restart = "on-failure";
        RestartSec = "5s";
        NoNewPrivileges = false;
        TimeoutStopSec = "10s";
        KillMode = "mixed";
        KillSignal = "SIGTERM";
      };
    };
  };
}
