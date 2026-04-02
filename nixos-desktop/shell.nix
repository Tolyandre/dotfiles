{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "my-update-elo" ''
      set -e

      export HTTPS_PROXY="socks5://127.0.0.1:20170"
      export HTTP_PROXY="socks5://127.0.0.1:20170"

      nix flake update elo --flake /dotfiles-repo

      nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop

      echo ""
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '')

    (writeShellScriptBin "my-update" ''
      set -e

      export HTTPS_PROXY="socks5://127.0.0.1:20170"
      export HTTP_PROXY="socks5://127.0.0.1:20170"

      nix-channel --update
      nix flake update --flake /dotfiles-repo

      nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop

      echo ""
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '')
  ];
}


