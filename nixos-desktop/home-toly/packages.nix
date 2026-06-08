{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.atool
    pkgs.gh
    pkgs.httpie
  ];

  programs.bash.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
