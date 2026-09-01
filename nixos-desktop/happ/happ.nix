# To update: set version to the new release tag, then get the new hash with:
# nix-prefetch-url --type sha256 https://github.com/Happ-proxy/happ-desktop/releases/download/<version>/Happ.linux.x64.deb
# Releases: https://github.com/Happ-proxy/happ-desktop/releases
{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation rec {
  pname = "happ-desktop";
  version = "4.1.3";

  src = pkgs.fetchurl {
    url = "https://github.com/Happ-proxy/happ-desktop/releases/download/${version}/Happ.linux.x64.deb";
    sha256 = "MuVD7HlLw2XmCbTU91jPUrsxPwY7l7q7gomcIJ6a8CI=";
  };

  nativeBuildInputs = with pkgs; [
    dpkg
    autoPatchelfHook
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = with pkgs; [
    stdenv.cc.cc.lib
    glib
    dbus
    libGL
    libx11
    libsm
    libice
    libxext
    libxi
    libxtst
    e2fsprogs
    fontconfig
    freetype
    libgpg-error
    qt6.qtwayland
    openssl
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/happ
    mkdir -p $out/share/applications
    mkdir -p $out/bin

    dpkg -x $src .
    cp -r opt/happ/* $out/happ/

    if [ -d "usr/share" ]; then
      cp -r usr/share/* $out/share/
    fi

    wrapProgram $out/happ/bin/Happ \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.openssl ]}" \
      --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

    wrapProgram $out/happ/bin/happd \
      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.openssl ]}" \
      --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

    ln -s $out/happ/bin/Happ $out/bin/happ

    runHook postInstall
  '';
}
