{
  unstable,
  ...
}:

{
  # AmneziaVPN needs its root daemon to manage tunnels. Upstream installs the
  # daemon on first launch via pkexec, which cannot work on NixOS, and the GUI
  # then fails with "Error 103: AmneziaServiceNotRunning". So we run the daemon
  # as a system service from the same package as the GUI (versions must
  # match). The unit mirrors lib/systemd/system/AmneziaVPN.service shipped in
  # the package; nixpkgs bakes absolute store paths for
  # openvpn/amneziawg/iptables into the binaries, so no extra PATH setup is
  # needed.
  environment.systemPackages = [ unstable.amnezia-vpn ];

  systemd.services.AmneziaVPN = {
    description = "AmneziaVPN Service";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.StartLimitIntervalSec = 0;

    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 1;
      ExecStart = "${unstable.amnezia-vpn}/bin/AmneziaVPN-service";
    };
  };
}
