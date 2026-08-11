# The two FreeRDP virtual-channel addins guacd loads at runtime:
#   libguac-common-svc-client.so  — shared by RDPDR, RDPSND, etc.
#   libguacai-client.so           — audio input
#
# FreeRDP 3 finds addins by scanning a path computed from FREERDP_INSTALL_PREFIX,
# which is HARDCODED in libfreerdp3.so at freerdp's build time (the nix store
# path of the freerdp derivation itself). So the addins must live in
# `$freerdp/lib/freerdp3/` — nowhere else is scanned, regardless of symlinks or
# LD_LIBRARY_PATH. guacd logs "failed to load guac-common-svc plugin for
# FreeRDP" and RDPSND (audio) never comes up when they're missing.
#
# nixpkgs' guacamole-server installs these into its own $out/lib (wrong place).
# We build the addins here against the *unoverlaid* freerdp (to avoid a cycle:
# guacamole-server depends on freerdp), then the freerdp overlay in
# guacamole.nix drops them into freerdp's scanned dir.
#
# We reuse guacamole-server's own autotools build (it already produces the
# addins correctly with the right rpath) but re-point --with-freerdp-plugin-dir
# to lib/freerdp3 so the addins land in the directory we then copy out of. We
# discard the rest of the build (guacd binary, client libs) — the real
# guacamole-server derivation provides those.
{
  lib,
  guacamole-server,
}:

guacamole-server.overrideAttrs (old: {
  configureFlags =
    lib.lists.remove "--with-freerdp-plugin-dir=${placeholder "out"}/lib" (old.configureFlags or [ ])
    ++ [ "--with-freerdp-plugin-dir=${placeholder "out"}/lib/freerdp3" ];

  # Drop nixpkgs' postInstall (which symlinks all of freerdp's libs into $out/lib
  # and wraps guacd). We only need the addins that autotools just installed into
  # $out/lib/freerdp3/ via the configure flag above.
  postInstall = ''
    mkdir -p $out/lib/freerdp3
  '';
})
