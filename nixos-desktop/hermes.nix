{ hermes-agent, pkgs, ... }: {
  # # https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup#minimal-configuration
  # services.hermes-agent = {
  #   enable = false;
  #   addToSystemPackages = true;
  # };

  # # hermes-desktop
  # # you can also run without install: 
  # # nix run github:NousResearch/hermes-agent#desktop
  # environment.systemPackages = [
  #   hermes-agent.packages.${pkgs.system}.desktop
  # ];
}
