{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "my-update" ''
      set -e

      export HTTPS_PROXY="socks5://127.0.0.1:20170"
      export HTTP_PROXY="socks5://127.0.0.1:20170"

      nix-channel --update
      nix flake update /dotfiles-repo

      nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop

      echo ""
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '')
  ];
}


