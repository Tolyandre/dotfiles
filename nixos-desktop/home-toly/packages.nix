{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.atool
    pkgs.httpie
  ];

  programs.bash.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
