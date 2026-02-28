{
  description = "Flake for NixOS + home-manager from this repo";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    secrets.url = "git+ssh://git@github.com:Tolyandre/dotfiles-secrets.git";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      flake-utils,
      ...
    }:
    let
      system = "x86_64-linux";
      # загружаем архив репо прямо (замените sha256 на реальное значение, полученное командой ниже)
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
            ./nixos-desktop/configuration.nix
            # импортируем конкретный файл из архива (не весь каталог)
            (import "${elosrc}/nix/elo-web-service-module.nix")
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
