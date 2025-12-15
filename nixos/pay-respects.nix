{ config, pkgs, ... }:
{
  programs.pay-respects = {
    enable = true;
    aiIntegration = {
      locale = "ru-RU";
      model = "llama3";
      url = "http://127.0.0.1:11434/v1/chat/completions";
    };
  };
}
