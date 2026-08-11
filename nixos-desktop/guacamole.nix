{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:

let
  # A clean, overlay-free nixpkgs import, used to build the guac channel addins
  # without triggering the overlay fixed-point recursion (freerdp overlay ->
  # addins -> guacamole-server -> freerdp). The addins are ABI-stable against a
  # freerdp point release, so building them against the unoverlaid freerdp and
  # loading them from the overlaid one is fine.
  cleanPkgs = import pkgs.path {
    localSystem = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
  guac-channel-addins = import ./guacamole/guac-channel-addins.nix {
    inherit lib;
    guacamole-server = cleanPkgs.guacamole-server;
  };

  # xrdp audio redirection.
  #
  # The PC runs PipeWire system-wide (see pipewire.nix, systemWide = true) so
  # both `toly` and `game` reach the PC speakers from local logins. NixOS's
  # built-in `services.xrdp.audio.enable` can't be used here: it loads a native
  # PulseAudio module (`pulseaudio-module-xrdp`), but this box has
  # `services.pulseaudio.enable = false` and PA modules cannot be loaded into
  # pipewire-pulse. Upstream's pipewire-module-xrdp is the correct module but is
  # not packaged in nixpkgs, so we build it locally.
  #
  # To keep remote audio isolated (phone hears only its own session; never the
  # other account's sound), the window-manager wrapper below starts a private,
  # ephemeral PipeWire instance per xrdp session — with no ALSA backend — and
  # loads the xrdp sink into that. The shared system-wide daemon is left
  # untouched, so local logins keep playing to the PC speakers.
  pipewire-module-xrdp = pkgs.callPackage ./guacamole/pipewire-module-xrdp.nix { };
  xrdp-audio-session = pkgs.callPackage ./guacamole/xrdp-audio-session.nix {
    inherit pipewire-module-xrdp;
    inherit (pkgs) wireplumber;
  };
in
{
  # FreeRDP channel addins (guac-common-svc, guacai) — nixpkgs packaging bug.
  #
  # guacd loads RDP virtual channels (rdpsnd = audio output, rdpdr = drive
  # redirection) through FreeRDP "addin" .so files. FreeRDP 3 finds them by
  # calling freerdp_get_library_install_path(), which returns a path HARDCODED
  # at FreeRDP's own build time (FREERDP_INSTALL_PREFIX baked into the .so) and
  # appends `/lib/freerdp3`. So FreeRDP only ever scans
  # `$freerdp/lib/freerdp3/`, regardless of guacd's LD_LIBRARY_PATH or any
  # symlinks. (Verified by disassembling libfreerdp3.so — the store path is a
  # literal string in .rodata.)
  #
  # nixpkgs' guacamole-server installs the guac addins into *guacamole-server*'s
  # `$out/lib`, which FreeRDP never looks at. guacd then logs "failed to load
  # guac-common-svc plugin for FreeRDP" and RDPSND never comes up — so remote
  # sound is silently dropped. The fix: drop the addins into freerdp's own
  # `$out/lib/freerdp3/`, the one path FreeRDP actually scans.
  nixpkgs.overlays = [
    (_final: prev: {
      freerdp = prev.freerdp.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/lib/freerdp3
          cp -r ${guac-channel-addins}/lib/freerdp3/* $out/lib/freerdp3/
        '';
      });
    })
  ];

  sops.secrets."guacamole_user_mapping.xml" = {
    sopsFile = builtins.toString secrets + "/secrets/guacamole_user_mapping.xml.sops";
    path = "/run/secrets/guacamole/guacamole_user_mapping.xml";
    owner = "tomcat";
    mode = "0400";
    format = "binary";
  };

  services.guacamole-server = {
    enable = true;
    host = "127.0.0.1";
    port = 4822;
  };

  services.guacamole-client = {
    enable = true;
    enableWebserver = true;
    settings = {
      guacd-port = 4822;
      guacd-hostname = "127.0.0.1";
    };
    userMappingXml = config.sops.secrets."guacamole_user_mapping.xml".path;
  };

  services.tomcat = {
    port = 41096;
  };

  services.xrdp.enable = true;
  # The wrapper boots an isolated PipeWire for the session (so audio goes to the
  # RDP client / phone) and then execs the real startplasma-x11. For non-xrdp
  # invocations it falls through to plain Plasma, so local logins are unaffected.
  services.xrdp.defaultWindowManager = "${xrdp-audio-session}/bin/startplasma-x11-xrdp";
}
