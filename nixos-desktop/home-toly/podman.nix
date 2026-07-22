{
  # See also nixos-desktop/podman.nix
  #
  # NOTE: subUidRanges/subGidRanges are NOT home-manager options. They are
  # system options (users.users.toly.*) and are set in nixos-desktop/podman.nix.

  # FHS environments (vscode.fhs, appimage-run/agents — anything built with
  # buildFHSEnv) cannot run rootless podman locally: /run/wrappers is mounted
  # nosuid, so the setuid newuidmap is neutered ("write to uid_map failed:
  # Operation not permitted"). This is a hard bubblewrap boundary — there is no
  # config fix that makes local podman work inside an FHS env.
  #
  # The solution is to route ALL podman work to the host's rootless podman socket
  # ($XDG_RUNTIME_DIR/podman/podman.sock, bind-mounted into FHS envs), where the
  # host podman does the userns/setuid work in its own namespace. Two env vars:
  #   - DOCKER_HOST  → docker-compose (set here, global)
  #   - CONTAINER_HOST → docker/podman CLIs (set only inside FHS envs, see
  #     nixos-desktop/podman.nix overlay + flake.nix for unstable)
  # Keeping CONTAINER_HOST scoped to FHS envs means the terminal keeps using
  # local podman unchanged.
  #
  # One-time cleanup if you still hit "lchown ... 65534:65534 ... invalid
  # argument": a poisoned `podman pause` process (from an older config that ran
  # local podman inside an FHS env) may be holding a degraded "size:1" mapping.
  # From a REAL terminal, kill it so podman recreates it with the full range:
  #   pkill -u toly -f 'podman pause'
  #   podman system migrate
  home.sessionVariables.DOCKER_HOST = "unix:///run/user/${toString 1000}/podman/podman.sock";

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
