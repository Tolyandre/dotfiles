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
    # ZCode (ADE от Z.ai), репак официального .deb. Бинарник zcode — это
    # patched Electron (как у форков VS Code), системный electron из nixpkgs
    # подключить нельзя и он НЕ тянется — дублирования с pkgs.electron нет.
    # Библиотеки (gtk/nss/...) — из нашего nixpkgs через overlays.shared-nixpkgs.
    pkgs.llm-agents.zcode
  ];

  programs.bash.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
