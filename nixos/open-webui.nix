{ config, pkgs, ... }:
{
  # To edit use your text editor application, for example Nano
  services.ollama = {
    # package = pkgs.unstable.ollama; # If you want to use the unstable channel package for example
    enable = true;
    acceleration = "rocm"; # Or "rocm"
    rocmOverrideGfx = "10.3.0";
    environmentVariables = {
      OLLAMA_HOST = "localhost:11434";
      ROCR_VISIBLE_DEVICES = "0"; # use discrete GPU instead of integrated
    };
    models = "/mnt/data/ollama_models";

    # environmentVariables = { # I haven't been able to get this to work, but please see the serviceConfig workaround below
    # HOME = "/home/ollama";
    # OLLAMA_MODELS = "/home/ollama/models";
    # OLLAMA_HOST = "0.0.0.0:11434"; # Make Ollama accesible outside of localhost
    # OLLAMA_ORIGINS = "http://localhost:8080,http://192.168.0.10:*"; # Allow access, otherwise Ollama returns 403 forbidden due to CORS
    #};
  };

  # The Ollama environment variables, as mentioned in the comments section
  systemd.services.ollama.serviceConfig = {
    #Environment = [ "OLLAMA_HOST=localhost:11434" ];
    ExecStartPre = "/usr/bin/env sleep 30"; # Fix "no compatible GPUs were discovered"
  };

  services.open-webui = {
    enable = true;
    host = "localhost";
    port = 44596;

    environment = {
      ANONYMIZED_TELEMETRY = "False";
      DO_NOT_TRACK = "True";
      SCARF_NO_ANALYTICS = "True";
      OLLAMA_API_BASE_URL = "http://localhost:11434/api";
      OLLAMA_BASE_URL = "http://localhost:11434";
      
      HOME = "${config.services.open-webui.stateDir}";

      # does not work
      # WEBUI_URL = "https://toly.is-cool.dev/open-webui/";
    };
  };

  # Add oterm to the systemPackages
  environment.systemPackages = with pkgs; [
    oterm
  ];
}
