{ config, pkgs, ... }:
{
    environment.systemPackages = with pkgs; [
      jetbrains.rider
      dotnetCorePackages.sdk_9_0-bin
  ];
}