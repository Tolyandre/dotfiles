{
  description = "Flake for NixOS + home-manager from this repo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
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
      ...
    }:
    let
      system = "x86_64-linux";
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

            # home-manager provided module
            home-manager.nixosModules.home-manager
          ];

          specialArgs = {
            secrets = secrets;
            inherit elo elo-stage;
            unstable = import nixpkgs-unstable {
              localSystem = system;
              config.allowUnfree = true;
            };
          };
        };
      };
    };
}
