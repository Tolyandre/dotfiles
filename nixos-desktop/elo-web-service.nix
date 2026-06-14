{
  config,
  pkgs,
  secrets,
  elo,
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

  # Production backend instance. Keyed "elo-web-service" so the systemd unit,
  # system user/group, state dir and Postgres db/user keep their existing names.
  services.elo-web-service.instances."elo-web-service" = {
    secrets-env-file = config.sops.secrets."elo-web-service/secrets.env".path;
    settings = {
      address = "localhost:42981";
      oauth2_auth_uri = "https://accounts.google.com/o/oauth2/auth";
      oauth2_redirect_uri = "https://tolyandre.github.io/elo/oauth2-callback";
      oauth2_token_uri = "https://oauth2.googleapis.com/token";
      oauth2_userinfo_uri = "https://www.googleapis.com/oauth2/v1/userinfo";
      oauth2_scopes = "openid https://www.googleapis.com/auth/userinfo.profile";
      frontend_uri = "https://tolyandre.github.io/elo";
      cookie_ttl_seconds = 2592000; # 3600*24*30
      postgres = {
        enableLocalDatabase = true;
      };
      ollama = {
        baseUrl = "http://localhost:11434";
        model = "llama3.1:8b";
        visionModel = "llama3.2-vision:11b";
      };
    };
  };

  # Production frontend, served on the domain at /elo (in addition to GitHub
  # Pages). Same prod backend, so it shares the prod session cookie.
  services.elo-frontend.instances."elo" = {
    basePath = "/elo";
    apiBaseUrl = "https://toly.is-cool.dev/elo-web-service";
    revision = elo.shortRev or "dev";
  };
}
