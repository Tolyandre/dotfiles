{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "my-update-elo" ''
      set -e

      export https_proxy="http://127.0.0.1:2080"
      export http_proxy="http://127.0.0.1:2080"
      export no_proxy="localhost,127.0.0.1"

      nix flake update elo --flake /dotfiles-repo

      nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop

      echo ""
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '')

    (writeShellScriptBin "my-update" ''
      set -e

      export https_proxy="http://127.0.0.1:2080"
      export http_proxy="http://127.0.0.1:2080"
      export no_proxy="localhost,127.0.0.1"

      nix-channel --update
      nix flake update --flake /dotfiles-repo

      nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop

      echo ""
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '')
  ];
}
