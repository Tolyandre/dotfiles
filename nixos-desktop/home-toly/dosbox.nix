{ config, pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "dosbox" ''
      exec ${pkgs.dosbox}/bin/dosbox -conf ~/.config/dosbox/override.conf "$@"
    '')
  ];

  xdg.configFile."dosbox/override.conf".text = ''
    [sdl]
    windowresolution = 1800x2400
    output=opengl

    [autoexec]
    mount c /mnt/data/games/dosbox
    C:
    cd kb2
  '';
}
