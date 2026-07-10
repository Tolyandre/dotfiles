{ pkgs, unstable, ... }:
let
  codexWithProxy = pkgs.writeShellScriptBin "codex" ''
    exec env HTTP_PROXY=http://127.0.0.1:2080 HTTPS_PROXY=http://127.0.0.1:2080 NO_PROXY=127.0.0.1,localhost ${unstable.codex}/bin/codex "$@"
  '';
in
{
  environment.systemPackages = [
    codexWithProxy
  ];
}
