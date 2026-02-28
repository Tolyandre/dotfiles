{
  config,
  pkgs,
  secrets,
  ...
}:
{
  sops.secrets."elo-web-service/elo-project-466111-adeffde84816.json" = {
    sopsFile = "${secrets}/secrets/elo-web-service/elo-project-466111-adeffde84816.json.sops";
    owner = "root";
    mode = "0400";
    format = "binary";
  };

  sops.secrets."elo-web-service/secrets.env" = {
    sopsFile = "${secrets}/secrets/elo-web-service/secrets.env.sops";
    owner = "root";
    mode = "0400";
    format = "dotenv";
  };

  services.elo-web-service = {
    enable = true;
    secrets-env-file = config.sops.secrets."elo-web-service/secrets.env".path;
    google-service-account-key = config.sops.secrets."elo-web-service/elo-project-466111-adeffde84816.json".path;
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
