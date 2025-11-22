{ config, pkgs, ... }:
{
  imports = [
    /home/toly/Repo/Tolyandre/elo/nix/elo-web-service-module.nix
  ];

  services.elo-web-service = {
    enable = true;
    secrets-env-file = "/my-secrets/elo-web-service/secrets.env";
    google-service-account-key = "/my-secrets/elo-web-service/elo-project-466111-adeffde84816.json";
    config = {
      doc_id = "1bf6bmd63dvO9xjtnoTGmkcWJJE0NetQRjKkgcQvovQQ";
      address = "localhost:42981";
      oauth2_auth_uri= https://accounts.google.com/o/oauth2/auth;
      oauth2_redirect_uri= https://tolyandre.github.io/elo/oauth2-callback;
      oauth2_token_uri= https://oauth2.googleapis.com/token;
      frontend_uri= https://tolyandre.github.io/elo;
      cookie_ttl_seconds= 2592000; # 3600*24*30
    };
  };
}
