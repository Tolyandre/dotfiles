{ config, pkgs, ... }:
{
  imports = [ inputs.sops-nix.nixosModule ];

  sops.secrets."elo-web-service/elo-project-466111.json" = {
    sopsFile =
      builtins.toString inputs.secrets + "/secrets/elo-web-service/elo-project-466111.json.sops";
    path = "/run/secrets/elo-web-service/elo-project-466111.json";
    owner = "root";
    mode = "0400";
  };

  sops.secrets."elo-web-service/secrets.env" = {
    sopsFile =
      builtins.toString inputs.secrets + "/secrets/elo-web-service/secrets.env.sops";
    path = "/run/secrets/elo-web-service/secrets.env";
    owner = "root";
    mode = "0400";
  };

  services.elo-web-service = {
    enable = true;
    secrets-env-file = "/run/secrets/elo-web-service/secrets.env";
    google-service-account-key = "/run/secrets/elo-web-service/elo-project-466111.json";
    config = {
      doc_id = "1bf6bmd63dvO9xjtnoTGmkcWJJE0NetQRjKkgcQvovQQ";
      address = "localhost:42981";
      oauth2_auth_uri = "https://accounts.google.com/o/oauth2/auth";
      oauth2_redirect_uri = "https://tolyandre.github.io/elo/oauth2-callback";
      oauth2_token_uri = "https://oauth2.googleapis.com/token";
      oauth2_userinfo_uri = "https://www.googleapis.com/oauth2/v1/userinfo";
      frontend_uri = "https://tolyandre.github.io/elo";
      cookie_ttl_seconds = 2592000; # 3600*24*30
      postgres = {
        enableLocalDatabase = true;
      };
    };
  };
}
