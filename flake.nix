{
  description = "Flake for NixOS + home-manager from this repo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    hermes-agent.url = "github:NousResearch/hermes-agent";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    secrets.url = "git+ssh://git@github.com/Tolyandre/dotfiles-secrets.git";
    elo.url = "github:tolyandre/elo";
    # Stage is pinned to the git tag `stage`; move the tag and
    # `nix flake update elo-stage` to deploy a different commit to stage.
    elo-stage.url = "github:tolyandre/elo/stage";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      flake-utils,
      sops-nix,
      secrets,
      elo,
      elo-stage,
      hermes-agent,
      ...
    }:
    let
      system = "x86_64-linux";

      # Inject CONTAINER_HOST into FHS environments (vscode.fhs,
      # appimage-run/agents) so the `docker`/`podman` CLIs route to the host
      # rootless podman socket instead of running podman locally (which can't
      # work — /run/wrappers is nosuid inside FHS envs). See
      # nixos-desktop/podman.nix for the full rationale. Applied to BOTH the
      # stable system nixpkgs (via the nixpkgs.overlays in that module) and to
      # the `unstable` import here, so unstable.vscode.fhs is covered too.
      fhsContainerHostOverlay = _: prev: {
        buildFHSEnv =
          args:
          prev.buildFHSEnv (
            args
            // {
              extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [
                "--setenv CONTAINER_HOST unix:///run/user/1000/podman/podman.sock"
              ];
            }
          );
      };
    in
    {
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = [ nixpkgs.legacyPackages.${system}.python3 ];
      };

      nixosConfigurations = {
        nixos-desktop = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }

            # make sops available for configuration and modules
            sops-nix.nixosModules.default

            # main system configuration (will be called with module args)
            ./nixos-desktop/configuration.nix

            #elo-web-service backend module (multi-instance) + static frontend builder
            elo.nixosModules.default
            elo.nixosModules.frontend

            hermes-agent.nixosModules.default

            # home-manager provided module
            home-manager.nixosModules.home-manager
          ];

          specialArgs = {
            secrets = secrets;
            inherit elo elo-stage hermes-agent;
            unstable = import nixpkgs-unstable {
              localSystem = system;
              config.allowUnfree = true;
              overlays = [ fhsContainerHostOverlay ];
            };
          };
        };
      };
    };
}
