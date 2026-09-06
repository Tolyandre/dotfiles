{
  config,
  unstable,
  ...
}:
{
  services.immich = {
    enable = true;
    # nixos-26.05 ships immich 2.7.x, which is marked insecure (2.x is EOL).
    # 3.x lives in unstable until the 26.11 branch; keep the 26.05 NixOS
    # module (options/db wiring are identical, VectorChord 1.1.1 in both).
    package = unstable.immich;
    mediaLocation = "/mnt/data/immich";
    # settings = {
    #   server.externalDomain = "https://immich.toly.is-cool.dev";
    # };

    machine-learning = {
      environment = {
        HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        HSA_USE_SVM = "0";
      };
    };

    # `null` will give access to all devices
    accelerationDevices = null;
  };
}
