{ config, pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = false; # Use custom v4l2loopback module parameters instead
    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      droidcam-obs
    ];
  };
  programs.droidcam.enable = true;

  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  boot.kernelModules = [ "v4l2loopback" ];

  # two video devices can be created: 
  # options v4l2loopback devices=2 card_label="OBS Virtual Camera,DroidCam Virtual Camera" exclusive_caps=1,1
  # but there is no a good way to configure OBS and DroidCam. Also, firefox sometimes cannot show second camera
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 card_label="OBS Virtual Camera" exclusive_caps=1
  '';

  security.polkit.enable = true;

  services.udev.extraRules = ''
    # OBS Virtual Camera → /dev/video-obs
    KERNEL=="video[0-9]*", ATTR{name}=="OBS Virtual Camera", SYMLINK+="video-obs"

    # DroidCam Virtual Camera → /dev/video-droidcam
    KERNEL=="video[0-9]*", ATTR{name}=="DroidCam Virtual Camera", SYMLINK+="video-droidcam"
  '';

    environment.systemPackages = with pkgs; [
      v4l-utils
    ];
}
