# Upstream PipeWire SPA module that provides an `xrdp-sink` (and source) so an
# xrdp session can redirect its audio to the RDP client. This is the PipeWire
# equivalent of `pulseaudio-module-xrdp`; it is NOT in nixpkgs (verified at the
# flake's pinned nixpkgs rev), hence the local derivation.
#
# Build is autotools and needs only libpipewire-0.3 / libspa-0.2 (both shipped in
# `pipewire.dev`). The module's `--with-module-dir` must NOT point at the
# read-only pipewire store path; we install into our own output and merge the
# module dir at runtime via PIPEWIRE_MODULE_DIR (see xrdp-audio-session.nix).
{
  stdenv,
  lib,
  fetchFromGitHub,
  autoreconfHook,
  autoconf,
  automake,
  libtool,
  pkg-config,
  pipewire,
}:

stdenv.mkDerivation rec {
  pname = "pipewire-module-xrdp";
  version = "0.2";

  src = fetchFromGitHub {
    owner = "neutrinolabs";
    repo = "pipewire-module-xrdp";
    rev = "v${version}";
    sha256 = "16aqcsqfnr6jqk8rkgkydgip33089dmy5wwiszb2y5vi38kjjjzd";
  };

  nativeBuildInputs = [
    autoreconfHook
    autoconf
    automake
    libtool
    pkg-config
    pipewire.dev
  ];

  buildInputs = [
    pipewire
  ];

  # Install the .so into our own output instead of pipewire's read-only module
  # dir. Runtime composition is handled by the xrdp-audio-session wrapper.
  # Redirect the XDG autostart file into the output too; we don't use it (the
  # xrdp-audio-session wrapper calls load_pw_modules.sh directly), but the
  # default /etc/xdg is read-only in the sandbox.
  configureFlags = [
    "--with-module-dir=$(out)/lib/pipewire-0.3"
    "--with-xdgautostart-dir=$(out)/etc/xdg/autostart"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "PipeWire SPA module providing an xrdp audio sink/source";
    homepage = "https://github.com/neutrinolabs/pipewire-module-xrdp";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
  };
}
