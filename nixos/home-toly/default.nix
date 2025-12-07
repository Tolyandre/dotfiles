{ pkgs, ... }:
{
  imports = [
    ./dosbox.nix
    ./git.nix
    ./packages.nix
  ];

  home.stateVersion = "25.05";
}
