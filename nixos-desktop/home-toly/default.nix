{ pkgs, ... }:
{
  imports = [
    ./dosbox.nix
    ./git.nix
    ./packages.nix
    ./podman.nix
  ];

  home.stateVersion = "25.05";
}
