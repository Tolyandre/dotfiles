{
  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.networkmanager.ensureProfiles.profiles = {
    # https://github.com/janik-haag/nm2nix
    "My NixOS wired connection" = {
      connection = {
        autoconnect-priority = "-100";
        id = "My NixOS wired connection";
        type = "ethernet";
        uuid = "39c2911e-c3ba-40fd-ab36-ed1580dfad4e";
      };
      ethernet = { };
      ipv4 = {
        method = "auto";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        address1 = "2a00:4580:100:7e84:6abc:9075:9ba4:83c7/64";
        gateway = "fe80::";
        method = "manual";
      };
      proxy = { };
    };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  programs.nekoray = {
    enable = true;
    tunMode.enable = true;
  };

  services.v2raya.enable = true;
}
