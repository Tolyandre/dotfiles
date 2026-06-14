{
  config,
  pkgs,
  secrets,
  elo-stage,
  ...
}:
{
  # Stage runtime secrets (OAuth2 client id/secret reused from prod, but a fresh
  # COOKIE_JWT_SECRET). The Google credentials JSON is not consumed by the
  # backend, so stage does not declare it.
  sops.secrets."elo-web-service-stage/secrets.env" = {
    sopsFile = "${secrets}/secrets/elo-web-service-stage/secrets.env.sops";
    owner = "root";
    mode = "0400";
    format = "dotenv";
  };

  # Stage backend instance. Keyed "elo-web-service-stage" so it gets its own
  # systemd unit, user/group, state dir and Postgres db/user, isolated from prod.
  services.elo-web-service.instances."elo-web-service-stage" = {
    package = elo-stage.packages.${pkgs.system}.default;
    secrets-env-file = config.sops.secrets."elo-web-service-stage/secrets.env".path;
    settings = {
      address = "localhost:42982";
      # Distinct cookie name so stage and prod (same host) sessions don't clobber.
      cookie_name = "elo-web-service-stage-token";
      oauth2_auth_uri = "https://accounts.google.com/o/oauth2/auth";
      oauth2_redirect_uri = "https://toly.is-cool.dev/elo-stage/oauth2-callback";
      oauth2_token_uri = "https://oauth2.googleapis.com/token";
      oauth2_userinfo_uri = "https://www.googleapis.com/oauth2/v1/userinfo";
      oauth2_scopes = "openid https://www.googleapis.com/auth/userinfo.profile";
      frontend_uri = "https://toly.is-cool.dev/elo-stage";
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

  # Stage frontend, served on the domain at /elo-stage with the test banner.
  services.elo-frontend.instances."elo-stage" = {
    package = elo-stage.packages.${pkgs.system}.frontend;
    basePath = "/elo-stage";
    apiBaseUrl = "https://toly.is-cool.dev/elo-web-service-stage";
    banner = "Тестовый сервер";
    revision = elo-stage.shortRev or "stage";
  };
}
