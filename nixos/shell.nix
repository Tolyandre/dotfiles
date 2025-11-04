{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "my-update" ''
      HTTPS_PROXY="socks5://127.0.0.1:20170"
      HTTP_PROXY="socks5://127.0.0.1:20170"
      nixos-rebuild switch --upgrade
    '')
  ];
}
