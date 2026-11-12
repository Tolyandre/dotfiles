# Run any program through the Amnezia VPN inside a persistent network
# namespace "awg", leaving host routing untouched. The desktop client
# (desktop.nix) stays fully independent; this tunnel uses its own device
# key — the server allows one active session per key.
#
# Usage: `run-with-vpn <command> [args…]` — one sudo password prompt, runs
# as the calling user with their full environment, blocks until exit:
#   run-with-vpn code
#   run-with-vpn firefox --profile /home/toly/.firefox-vpn
#   run-with-vpn curl https://ifconfig.me
# Electron/Chromium apps (VSCode, Chrome) MUST use the wrapper: they crash
# with SIGTRAP when spawned directly by systemd. Children of the launched
# process inherit the namespace; single-instance apps hand off to a running
# host instance (close it first or use a separate profile); xdg-open still
# runs in the host session.
#
# Tunnel config: secrets/amnezia/awg0.conf.sops in the dotfiles-secrets
# repo (age recipient in its README):
#   sops --encrypt --input-type binary --output-type binary \
#     --age "$PUBLIC_AGE_RECIPIENT" awg0.conf > secrets/amnezia/awg0.conf.sops
# The Endpoint MUST be the domestic entry ru-mh-w-01.blncvpn4u.cc:51119 —
# the panel's lt2.blncvpn4u.cc points at a range this ISP cannot reach
# directly. The awg-endpoint-refresh timer tracks the entry hostname's IP
# rotation automatically.
#
# Check: sudo ip netns exec awg dig +short myip.opendns.com @208.67.222.222
{
  config,
  pkgs,
  unstable,
  secrets,
  ...
}:

{
  sops.secrets."amnezia/awg0.conf" = {
    sopsFile = "${secrets}/secrets/amnezia/awg0.conf.sops";
    format = "binary";
    owner = "root";
    mode = "0400";
  };

  # `run-with-vpn <command> [args…]` — run anything inside the awg
  # namespace from a normal shell: blocks until exit, forwards console
  # output, accepts arguments. REQUIRED for Electron/Chromium apps (VSCode,
  # Chrome): they crash with SIGTRAP when spawned from a systemd unit, but
  # work fine through this wrapper.
  # Runs on behalf of the CALLING user with their FULL environment
  # (sudo -E preserves it, runuser switches uid without resetting it), so
  # apps see the same session bus, Wayland socket and theme as a native
  # terminal launch — VSCode's keyring detection included.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "run-with-vpn" ''
      if [ "$EUID" -ne 0 ]; then
        exec sudo -E "$(readlink -f "$0")" "$@"
      fi
      # SUDO_USER = who invoked sudo (unset when run directly as root, in
      # which case stay root — no invented default user).
      exec ip netns exec awg runuser -u "''${SUDO_USER:-root}" -- "$@"
    '')
  ];

  # Masquerade namespace traffic on any egress interface (the host is
  # multi-homed: eno1 + wlp10s0), so the rule matches by source only.
  # Deliberately NOT networking.nat: its fwmark-based implementation rewrites
  # packet marks (MARK --set-xmark 0x1) in PREROUTING, erasing the tunnel's
  # protective fwmark 0xca6c before the routing decision. That let the desktop
  # client's full-tunnel policy rules capture namespace traffic into amn0 and
  # blackholed the handshake (the 2026-11-13 outage). Plain source MASQUERADE
  # never touches marks, so namespace traffic keeps its exemptions under any
  # desktop client state.
  networking.firewall.extraCommands = ''
    iptables -w -t nat -A POSTROUTING -s 10.200.0.0/24 -j MASQUERADE 2>/dev/null || true
    iptables -w -t filter -A nixos-filter-forward -i awg-host -j ACCEPT 2>/dev/null || true
  '';
  networking.firewall.extraStopCommands = ''
    iptables -w -t nat -D POSTROUTING -s 10.200.0.0/24 -j MASQUERADE 2>/dev/null || true
  '';

  # Forwarding normally comes via networking.nat's boot sysctl; set it
  # explicitly so the namespace never depends on another module's mkDefault
  # chain (runtime guard: see awg-endpoint-refresh below).
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;

  # Persistent network namespace with a veth uplink to the host. The tunnel's
  # catch-all routes live only inside this namespace; host routing (and the
  # desktop client's amn0) is untouched.
  systemd.services.awg-netns = {
    description = "Persistent 'awg' network namespace with veth uplink";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.iproute2 ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      if ! ip netns list | cut -d' ' -f1 | grep -qx awg; then
        ip netns add awg
      fi
      if ! ip link show awg-host >/dev/null 2>&1; then
        ip link add awg-host type veth peer name awg-peer
        ip link set awg-peer netns awg
        ip address add 10.200.0.1/24 dev awg-host
      fi
      ip link set awg-host up
      ip netns exec awg ip link set lo up
      if ! ip netns exec awg ip address show dev awg-peer | grep -q 10.200.0.2; then
        ip netns exec awg ip address add 10.200.0.2/24 dev awg-peer
      fi
      ip netns exec awg ip link set awg-peer up
      # Default route to the host; the LAN route keeps the host's resolver and
      # local services reachable from inside the namespace.
      ip netns exec awg ip route replace default via 10.200.0.1
      ip netns exec awg ip route replace 192.168.88.0/24 via 10.200.0.1
      # Traffic arriving from the namespace must always use the host main
      # table. Without this rule the desktop client's full-tunnel policy rules
      # ("not fwmark 51820 table 51820" -> dev amn0) capture forwarded
      # namespace packets whenever the desktop VPN is connected: the NixOS nat
      # module marks awg-host traffic 0x1 in PREROUTING, erasing the tunnel's
      # protective fwmark 0xca6c before the routing decision, so handshake
      # packets disappear into the desktop tunnel and the server's replies
      # come back to a dead NAT port. Priority 100 preempts the desktop
      # daemon's rules (32764+). This made run-with-vpn die whenever the
      # desktop VPN was up (diagnosed 2026-11-13).
      ip rule show | grep -q "iif awg-host" ||
        ip rule add iif awg-host lookup main priority 100
    '';

    preStop = ''
      ip rule del iif awg-host lookup main priority 100 2>/dev/null || true
      ip netns del awg || true
    '';
  };

  # AmneziaWG tunnel inside the namespace. Uses the userspace amneziawg-go
  # from unstable (same 3.1.x generation as the desktop client and the
  # server); awg-quick falls back to it automatically because no amneziawg
  # kernel module is loaded. (A kernel module exists in stable nixpkgs, but
  # it is the older 1.x generation and must match the running kernel.)
  systemd.services.awg-tunnel = {
    description = "AmneziaWG tunnel inside the awg network namespace";
    after = [
      "awg-netns.service"
      "network-online.target"
    ];
    wants = [ "network-online.target" ];
    requires = [ "awg-netns.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [
      unstable.amneziawg-tools
      unstable.amneziawg-go
      pkgs.iproute2
    ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      RuntimeDirectory = "amnezia-netns";
    };

    # awg-quick would push DNS= from the config through resolvconf, which
    # inside a netns rewrites the SHARED host /etc/resolv.conf. Strip DNS
    # lines; the namespace instead resolves via the host (LAN route above).
    preStart = ''
      grep -v '^[[:space:]]*DNS[[:space:]]*=' \
        ${config.sops.secrets."amnezia/awg0.conf".path} \
        > /run/amnezia-netns/awg0.conf
      chmod 0600 /run/amnezia-netns/awg0.conf
    '';

    script = ''
      exec ip netns exec awg awg-quick up /run/amnezia-netns/awg0.conf
    '';

    preStop = ''
      ip netns exec awg awg-quick down /run/amnezia-netns/awg0.conf || true
    '';
  };

  # The Amnezia server's IP is dynamic (the config uses a DDNS hostname):
  # the desktop client re-resolves on every connect, but amneziawg-go pins
  # the address resolved at startup, so the tunnel dies whenever the server
  # moves. This watchdog re-resolves via the LAN resolver and updates the
  # peer endpoint in place (no tunnel restart, no dropped sessions).
  systemd.services.awg-endpoint-refresh = {
    description = "Re-resolve AmneziaWG server endpoint (dynamic IP)";
    after = [ "awg-tunnel.service" ];
    wants = [ "awg-tunnel.service" ];
    path = [
      unstable.amneziawg-tools
      pkgs.iproute2
      pkgs.bind.dnsutils
    ];

    serviceConfig.Type = "oneshot";

    script = ''
      # Self-heal forwarding: on this host net.ipv4.ip_forward was found reset
      # to 0 at runtime (2026-11-13), which silently blackholed the whole
      # namespace — packets reached PREROUTING but died before FORWARD, so the
      # tunnel sent handshakes that never left the machine. The boot sysctl
      # covers reboots; this guards against a recurrence between them.
      echo 1 > /proc/sys/net/ipv4/ip_forward
      conf=/run/amnezia-netns/awg0.conf
      [ -f "$conf" ] || exit 0
      # `ip netns list` prints "awg (id: 0)" — match the name column only.
      ip netns list | cut -d' ' -f1 | grep -qx awg || exit 0

      # Skip refresh while the peer is healthy: the entry hostname resolves to
      # several A records (GeoDNS round-robin), so re-setting the endpoint on
      # every run relocates the NAT mapping and forces a needless rehandshake
      # every ~30 s. Only step in when no handshake succeeded for 3 minutes.
      hs=$(ip netns exec awg awg show awg0 latest-handshakes \
        | tr -s '[:blank:]' ' ' | cut -d' ' -f2 | head -n1)
      [ -n "$hs" ] && [ "$hs" -gt 0 ] || hs=0
      [ $(( $(date +%s) - hs )) -lt 180 ] && exit 0

      endpoint=$(sed -n 's/^[[:space:]]*Endpoint[[:space:]]*=[[:space:]]*//p' "$conf" | head -n1)
      host=''${endpoint%:*}
      port=''${endpoint##*:}
      key=$(sed -n 's/^[[:space:]]*PublicKey[[:space:]]*=[[:space:]]*//p' "$conf" | head -n1)
      [ -n "$host" ] && [ -n "$port" ] && [ -n "$key" ] || exit 0
      # Static IPv4 endpoint: nothing to refresh.
      [[ $host =~ ^[0-9.]+$ ]] && exit 0

      new=$(dig +short @192.168.88.1 "$host" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)
      [ -n "$new" ] || exit 0

      # `awg show` separates key and endpoint with a TAB; normalize blanks
      # before cutting, otherwise the whole line becomes field 2 and the
      # comparison below never matches (endpoint was re-set every run).
      cur=$(ip netns exec awg awg show awg0 endpoints | tr -s '[:blank:]' ' ' | cut -d' ' -f2 | cut -d: -f1 | head -n1)
      if [ "$new" != "$cur" ]; then
        echo "awg0 endpoint $cur -> $new"
        ip netns exec awg awg set awg0 peer "$key" endpoint "$new:$port"
      fi
    '';
  };

  systemd.timers.awg-endpoint-refresh = {
    description = "Periodically re-resolve AmneziaWG server endpoint";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30s";
    };
  };
}
