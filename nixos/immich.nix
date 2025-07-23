{
  services.immich = {
    enable = true;
    mediaLocation = "/mnt/data/immich";
    # settings = {
    #   server.externalDomain = "https://immich.toly.is-cool.dev";
    # };

    machine-learning = {
      environment = {
        HSA_OVERRIDE_GFX_VERSION="10.3.0";
        HSA_USE_SVM="0";
      };
    };

    # `null` will give access to all devices
    accelerationDevices = null;
  };
}

