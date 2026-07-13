{ pkgs, unstable, ... }:
let
  opencodeWithProxy = pkgs.writeShellScriptBin "opencode" ''
    exec env http_proxy=http://127.0.0.1:2080 https_proxy=http://127.0.0.1:2080 no_proxy=127.0.0.1,localhost ${unstable.opencode}/bin/opencode "$@"
  '';
in
{
  environment.systemPackages = [
    opencodeWithProxy
  ];
}
