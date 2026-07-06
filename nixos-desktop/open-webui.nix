{
  config,
  pkgs,
  unstable,
  ...
}:
{
  services.ollama = {
    package = unstable.ollama-rocm;
    enable = true;
    rocmOverrideGfx = "10.3.0";
    environmentVariables = {
      OLLAMA_HOST = "localhost:11434";
      ROCR_VISIBLE_DEVICES = "0"; # use discrete GPU instead of integrated
    };
    models = "/mnt/data/ollama_models";
  };

  systemd.services.ollama.serviceConfig = {
    ExecStartPre = "/usr/bin/env sleep 30"; # Fix "no compatible GPUs were discovered"
  };

  # my custom models
  environment.etc."ollama/gpt-oss-my-model.Modelfile".text = ''
    FROM gpt-oss:latest
    PARAMETER num_ctx 86000
  '';

  environment.etc."ollama/glm-4.7-flash-my-model.Modelfile".text = ''
    FROM glm-4.7-flash:latest
    PARAMETER num_ctx 86000
  '';

  systemd.services.ollama-create-models = {
    description = "Create custom Ollama models";
    after = [ "ollama.service" ];
    wants = [ "ollama.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      User = "ollama";
      Group = "ollama";
      Environment = [ "HOME=/var/lib/ollama" ];
      Restart = "no";
    };

    script = ''
      # Подождать, пока API Ollama станет доступен
      until ${config.services.ollama.package}/bin/ollama list ; do
        sleep 1
      done

      ${config.services.ollama.package}/bin/ollama create gpt-oss-my-model -f /etc/ollama/gpt-oss-my-model.Modelfile
      ${config.services.ollama.package}/bin/ollama create glm-4.7-flash-my-model -f /etc/ollama/glm-4.7-flash-my-model.Modelfile
    '';
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
    };
  };

  environment.systemPackages = with pkgs; [ oterm ];
}
