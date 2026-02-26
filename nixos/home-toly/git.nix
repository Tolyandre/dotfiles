{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings.user = {
      Name = "Anatoley Buranov";
      Email = "2414704+Tolyandre@users.noreply.github.com";
      pull = {
        rebase = true;
      };
    };
  };
}
