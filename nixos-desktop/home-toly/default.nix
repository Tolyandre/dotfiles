{ pkgs, ... }:
{
  imports = [
    ./dosbox.nix
    ./git.nix
    ./packages.nix
    ./podman.nix
  ];

  # home-manager собирает собственный экземпляр nixpkgs, на который системный
  # nixpkgs.config.allowUnfree не распространяется. Нужно для unfree-пакетов в
  # home.packages (например jetbrains.idea).
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "25.05";
}
