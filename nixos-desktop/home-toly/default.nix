{
  pkgs,
  llm-agents,
  ...
}:
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

  # Пакеты llm-agents.nix (zcode и др.) собираются против ЭТОГО же nixpkgs
  # (overlays.shared-nixpkgs), а не против собственного пина numtide —
  # библиотечные зависимости (gtk3, nss, ...) шарятся с системой и не тянут
  # второй экземпляр nixpkgs в closure. Сам Electron всё равно внутри .deb
  # (см. комментарий в packages.nix), pkgs.electron из nixpkgs не используется.
  nixpkgs.overlays = [ llm-agents.overlays.shared-nixpkgs ];

  home.stateVersion = "25.05";
}
