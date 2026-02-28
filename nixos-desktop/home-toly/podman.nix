{
  # See also nixos/podman.nix

  # Also you may need to set subuid and subgid for your user:
  # subUidRanges = [
  #   {
  #     startUid = 100000;
  #     count = 65536;
  #   }
  # ];
  # subGidRanges = [
  #   {
  #     startGid = 100000;
  #     count = 65536;
  #   }
  # ];
  # and then run `podman system migrate`

  xdg.configFile."containers/policy.json".text = ''
    {
      "default": [
        { "type": "insecureAcceptAnything" }
      ]
    }
  '';

  xdg.configFile."containers/registries.conf".text = ''
    unqualified-search-registries = ["docker.io", "quay.io"]
  '';

  # # чтобы container dex не менял права монтированных файлов так, что их нельзя удалить
  # xdg.configFile."containers/containers.conf".text = ''
  #   [containers]
  #   userns="keep-id"
  # '';
}
