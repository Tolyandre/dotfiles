{
  config,
  pkgs,
  unstable,
  ...
}:

{
  home.packages = [
    pkgs.atool
    unstable.devenv
    pkgs.gh
    pkgs.httpie
    pkgs.jetbrains.idea
    pkgs.llm-agents.zcode
  ];

  programs.bash.enable = true;

  # devenv auto-activation (https://devenv.sh/auto-activation/).
  programs.bash.initExtra = ''eval "$(devenv hook bash)"'';

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
