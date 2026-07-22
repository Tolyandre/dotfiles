{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Rootless podman needs a subuid/subgid range allocated to the user, so the
  # user namespace has UIDs/GIDs to map container ownership into. Without it,
  # podman fails on volume/image setup with:
  #   "potentially insufficient UIDs or GIDs available in user namespace"
  #   "lchown ...: invalid argument"
  # NOTE: subUidRanges/subGidRanges are system options (users.users.<name>),
  # NOT home-manager options — that's why they must live here, not in
  # home-toly/podman.nix. They write /etc/subuid and /etc/subgid.
  # After changing this, run `podman system migrate` as the user.
  users.users.toly = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  # FHS environments (vscode.fhs, appimage-run/agents — anything built with
  # buildFHSEnv) cannot run rootless podman locally: /run/wrappers is mounted
  # nosuid, so the setuid newuidmap is neutered ("write to uid_map failed:
  # Operation not permitted"). This is a hard bubblewrap boundary — no
  # /etc/subuid visibility trick fixes it.
  #
  # So every podman-based command inside an FHS env must talk to the host's
  # rootless podman socket instead of running podman locally. The socket lives
  # under $XDG_RUNTIME_DIR/podman/ (bind-mounted into FHS envs), and the host
  # podman does the userns/setuid work in its own namespace where newuidmap
  # works. Running podman locally in the FHS env is doubly bad: it not only
  # fails, it poisons the shared `podman pause` process with a degraded
  # "size:1" mapping that then breaks the terminal too.
  #
  # docker-compose honors DOCKER_HOST (set in home-toly/podman.nix). The
  # `docker`/`podman` CLIs honor CONTAINER_HOST instead — so we inject it here,
  # scoped to FHS envs only via a buildFHSEnv overlay (so the terminal keeps
  # using local podman unchanged). DOCKER_HOST is global because docker-compose
  # doesn't run from a stable-pkgs FHS context differently.
  #
  # The SAME overlay is also applied to the `unstable` nixpkgs import in
  # flake.nix, so that unstable.vscode.fhs is covered (vscode.fhs comes from the
  # unstable input, which is imported separately and does not see this system
  # overlay). Keep the two copies in sync.
  nixpkgs.overlays = [
    (_: prev: {
      buildFHSEnv =
        args:
        prev.buildFHSEnv (
          args
          // {
            extraBwrapArgs = (args.extraBwrapArgs or [ ]) ++ [
              "--setenv CONTAINER_HOST unix:///run/user/1000/podman/podman.sock"
            ];
          }
        );
    })
  ];

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };

    # see also nixos-desktop/home-toly/podman.nix
    containers = {
      enable = true;
      policy = {
        default = [ { type = "insecureAcceptAnything"; } ];
        transports = {
          docker-daemon = {
            "" = [ { type = "insecureAcceptAnything"; } ];
          };
        };
      };
      registries = {
        search = [
          "docker.io"
          "quay.io"
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # podman-compose
    docker-compose
  ];
}
