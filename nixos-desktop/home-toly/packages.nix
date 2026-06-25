{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.atool
    pkgs.gh
    pkgs.httpie
    # IntelliJ IDEA: единая сборка JetBrains (бесплатный режим = бывшая Community;
    # idea-community удалён в 26.05 после слияния редакций). Не в кэше nixos —
    # тянется напрямую с серверов JetBrains (download+распаковка, не компиляция).
    pkgs.jetbrains.idea
  ];

  programs.bash.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
