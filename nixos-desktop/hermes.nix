{ hermes-agent, pkgs, ... }: {
  # https://hermes-agent.nousresearch.com/docs/getting-started/nix-setup?utm_source=chatgpt.com#minimal-configuration
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
  };

  # run hermes-desktop
  environment.systemPackages = [
    hermes-agent.packages.${pkgs.system}.desktop
  ];
}
