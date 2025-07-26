{
  services.caddy = {
    enable = true;

    extraConfig = ''
      http://,
      https://toly.is-cool.dev
      {
        root * /dotfiles-repo/nixos/caddy
        handle_path /index.html
        file_server
      }

      https://open-webui.toly.is-cool.dev
      {
        reverse_proxy localhost:44596
      }

      https://immich.localhost,
      https://661606e8c73b.sn.mynetname.net,
      https://immich.toly.is-cool.dev
      {
        reverse_proxy localhost:2283
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443];
}