{
  description = "Flake for NixOS + home-manager from this repo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    secrets.url = "git+ssh://git@github.com/Tolyandre/dotfiles-secrets.git";
    elo.url = "github:tolyandre/elo";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-master,
      home-manager,
      flake-utils,
      sops-nix,
      secrets,
      elo,
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

            #elo-web-service configuration module
            elo.nixosModules.default

            # home-manager provided module
            home-manager.nixosModules.home-manager
          ];

          specialArgs = {
            secrets = secrets;
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
            };
            master = import nixpkgs-master {
              inherit system;
              config.allowUnfree = true;
            };
          };
        };
      };
    };
}
