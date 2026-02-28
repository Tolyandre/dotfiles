{
  description = "Flake for NixOS + home-manager from this repo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    secrets.url = "git+ssh://git@github.com/Tolyandre/dotfiles-secrets.git";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      sops-nix,
      secrets,
      ...
    }:
    let
      system = "x86_64-linux";
      elosrc = builtins.fetchTarball {
        url = "https://github.com/Tolyandre/elo/archive/refs/heads/main.tar.gz";
        sha256 = "1r92vbp11j2z8pry7v6dvg88g3drwmjd3asv9hi2ca6ka452wp55";
      };
    in
    {
      nixosConfigurations = {
        nixos-desktop = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # make sops available for configuration and modules
            sops-nix.nixosModules.default

            # main system configuration (will be called with module args)
            ./nixos-desktop/configuration.nix
            (import "${elosrc}/nix/elo-web-service-module.nix")

            # home-manager provided module
            home-manager.nixosModules.home-manager
          ];

          specialArgs = { secrets = secrets;};
        };
      };
    };
}