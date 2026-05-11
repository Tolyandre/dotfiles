{ pkgs, ... }:
{
  # BenQ 5150c определяется snapscan backend как USB 04a5:2137 (FlatbedScanner40).
  # Прошивка извлечена из mirascan_v6.1.5150c.2.zip — официальный драйвер для 5150c.
  nixpkgs.overlays = [
    (final: prev: {
      sane-backends = (prev.sane-backends.override {
        snapscanFirmware = ./u55v009.bin;
      }).overrideAttrs (old: {
        # Fix: BenQ 5150c uses 1200 DPI position units, not 600.
        # Without the patch the scanned image covers only half the actual area.
        patches = (old.patches or []) ++ [ ./benq-5150c-pos-factor.patch ];
      });
    })
  ];

  hardware.sane.enable = true;

  users.users.toly.extraGroups = [ "scanner" ];

  environment.systemPackages = with pkgs; [
    simple-scan
    sane-frontends
  ];
}
