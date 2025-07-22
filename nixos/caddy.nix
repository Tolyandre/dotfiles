{
  services.caddy = {
    enable = true;

    extraConfig = ''
      http://,
      https://toly.is-cool.dev,
      {
        respond "Hello, world!"
      }

      https://immich.localhost,
      https://661606e8c73b.sn.mynetname.net,
      https://immich.toly.is-cool.dev
      {
        reverse_proxy 127.0.0.1:2283
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443];
}