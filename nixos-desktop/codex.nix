{ pkgs, ... }:
let
  codexWithProxy = pkgs.writeShellScriptBin "codex" ''
    exec env HTTP_PROXY=http://127.0.0.1:2080 HTTPS_PROXY=http://127.0.0.1:2080 ${pkgs.codex}/bin/codex "$@"
  '';
in
{
  environment.systemPackages = [
    codexWithProxy
  ];
}
