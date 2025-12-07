{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.atool
    pkgs.httpie
  ];

  programs.bash.enable = true;
}
