{ config, pkgs, ... }:

let
  # старый nixpkgs, где freerdp2 ещё есть
  oldpkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-23.11.tar.gz";
    sha256 = "1f5d2g1p6nfwycpmrnnmc2xmcszp804adp16knjvdkj8nz36y1fg";
  }) {};
in
{
  nixpkgs.overlays = [
    (self: super: {
      guacamole-server = super.guacamole-server.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ super.pkg-config ];
        buildInputs = (old.buildInputs or []) ++ [ oldpkgs.freerdp ];
        configureFlags = (old.configureFlags or []) ++ [ "--with-freerdp" ];
      });
    })
  ];

  services.guacamole-server = {
    enable = true;
    host = "localhost";
    port = 4822;
    userMappingXml = /my-secrets/guacamole_user_mapping.xml;
  };

  services.guacamole-client = {
    enable = true;
    enableWebserver = true;
    settings = {
      guacd-port = 4822;
      guacd-hostname = "localhost";
    };
  };

  services.tomcat = {
    port = 41096;
  };

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11"; # does not work
}