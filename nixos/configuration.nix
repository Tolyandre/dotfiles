# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
    ./backup.nix
    ./caddy/caddy.nix
    ./dotnet/dotnet.nix
    ./guacamole.nix
    ./mysql.nix
    ./networking.nix
    ./nextcloud.nix
    ./ocis.nix
    ./immich.nix
    ./open-webui.nix
    ./podman.nix
    ./postgresql.nix
    ./seafile.nix
    ./shell.nix
    ./camera.nix
    ./elo-web-service.nix
  ];

  # Bootloader.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable = true;
    devices = [ "nodev" ];
    efiSupport = true;
    useOSProber = true;
    gfxmodeEfi = "1600x1200,auto";
    theme = pkgs.catppuccin-grub;
    extraEntries = ''
      menuentry "UEFI" {
        fwsetup
      }
    '';
  };

  boot.kernelParams = [
    "nvme_core.default_ps_max_latency_us=0"
    "quiet"
    "splash"
    # Fix Hogwarts Legacy
    "clearcpuid=umip"
  ];

  # Set your time zone.
  time.timeZone = "Europe/Samara";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ru_RU.UTF-8";
    LC_IDENTIFICATION = "ru_RU.UTF-8";
    LC_MEASUREMENT = "ru_RU.UTF-8";
    LC_MONETARY = "ru_RU.UTF-8";
    LC_NAME = "ru_RU.UTF-8";
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_PAPER = "ru_RU.UTF-8";
    LC_TELEPHONE = "ru_RU.UTF-8";
    LC_TIME = "ru_RU.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager = {
    sddm.enable = true;
    autoLogin.enable = false;
    # autoLogin.user = "game";
  };
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    # options = "grp:alt_shift_toggle";
    options = "grp:win_space_toggle";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    startWhenNeeded = true;
    settings = {
      PasswordAuthentication = false;
      AllowUsers = [ "toly" ];
      PermitRootLogin = "no";
    };
  };
  services.fail2ban.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.toly = {
    isNormalUser = true;
    description = "Anatoley";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      kdePackages.kate
      kdePackages.sddm-kcm # Configuration module for SDDM
    ];
  };

  users.users.game = {
    isNormalUser = true;
    description = "Game";
    packages = with pkgs; [
      lutris
    ];
  };

  # for lutris-0.5.19
  nixpkgs.config.permittedInsecurePackages = [
    "mbedtls-2.28.10"
  ];

  programs.firefox.enable = true;
  programs.direnv.enable = true;
  programs.steam.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bitwarden-desktop
    dbeaver-bin
    dig
    go
    google-chrome
    htop
    jq
    kdePackages.filelight
    kdePackages.partitionmanager
    libreoffice
    mc
    mission-center
    mpv
    neofetch
    nil
    nix-tree
    nixfmt-rfc-style
    nodejs
    nvme-cli
    nvtopPackages.amd
    obsidian
    partclone
    pciutils
    pnpm
    podman
    popcorntime
    qbittorrent
    qdirstat
    seafile-client
    telegram-desktop
    traceroute
    vlc
    vscode.fhs
    wineWowPackages.stable
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    rebootWindow = {
      lower = "06:00";
      upper = "07:00";
    };
  };

  # Automatic Garbage Collection
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  # home-manager
  home-manager.users.toly =
    { pkgs, ... }:
    {
      home.packages = [
        pkgs.atool
        pkgs.httpie
      ];

      programs.bash.enable = true;

      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "25.05";

      programs.git = {
        enable = true;
        userName = "Anatoley Buranov";
        userEmail = "2414704+Tolyandre@users.noreply.github.com";
      };

    };

  security.sudo = {
    enable = true;
    extraConfig = "Defaults        timestamp_timeout=120";
  };

  fileSystems."/mnt/win11" = {
    device = "/dev/disk/by-label/win11";
    fsType = "ntfs";
    options = [ "nofail" ];
  };

  fileSystems."/mnt/data" = {
    # for some reason this btrfs partition does not exists by-label, but exists by-uuid
    device = "/dev/disk/by-uuid/6831b904-2714-4940-bdf9-f4147cbdd6f5";
    options = [
      "rw"
      "exec"
      "user"
    ];
  };

  fileSystems."/home" = {
    depends = [ "/mnt/data" ];
    device = "/mnt/data/home";
    fsType = "none";
    options = [
      "bind"
      "exec"
    ];
  };

  fileSystems."/mnt/seagate" = {
    device = "/dev/disk/by-label/seagate";
    options = [
      "rw"
      "exec"
      "user"
      "nofail"
    ];
  };

  hardware.bluetooth.enable = true;
}
