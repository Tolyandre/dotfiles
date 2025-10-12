{ config, pkgs, ... }:
{
  imports = [
    /home/toly/Repo/Tolyandre/elo/nix/elo-web-service-module.nix
  ];

  services.elo-web-service = {
    enable = true;
    google-service-account-key = "/my-secrets/elo-web-service/elo-project-466111-adeffde84816.json";
    doc-id = "1bf6bmd63dvO9xjtnoTGmkcWJJE0NetQRjKkgcQvovQQ";
    address = "localhost:42981";
   };
}