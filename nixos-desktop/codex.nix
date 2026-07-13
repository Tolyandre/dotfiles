{ pkgs, unstable, ... }:
let
  codexWithProxy = pkgs.writeShellScriptBin "codex" ''
    exec env http_proxy=http://127.0.0.1:2080 https_proxy=http://127.0.0.1:2080 no_proxy=127.0.0.1,localhost ${unstable.codex}/bin/codex "$@"
  '';
in
{
  environment.systemPackages = [
    codexWithProxy
  ];
}
