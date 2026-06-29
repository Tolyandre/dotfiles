{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Anatolii Buranov";
        email = "2414704+Tolyandre@users.noreply.github.com";
      };
      pull.rebase = true;
    };
  };
}
