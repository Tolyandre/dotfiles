# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal NixOS + home-manager configuration, managed as a flake, for a single machine: host `nixos-desktop` (primary user `toly`, x86_64-linux, KDE Plasma desktop). The repo is checked out at `/dotfiles-repo` directly on that machine, and the live system is built from that exact path (see `programs.git.config.safe.directory` in `configuration.nix` and the rebuild commands below — there's no separate deploy step).

## Commands

Apply changes to the running system (root required; only meaningful on the target machine itself):
```
sudo nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop
sudo nixos-rebuild test   --flake /dotfiles-repo#nixos-desktop   # activate without making it the default boot entry
sudo nixos-rebuild build  --flake /dotfiles-repo#nixos-desktop   # just build + symlink ./result, good for validating edits
```

Two wrapper scripts (`writeShellScriptBin`, installed system-wide) bundle the routine update flow. Both export a SOCKS5 proxy (`127.0.0.1:20170`, via the `throne`/v2raya setup in `networking.nix`) before touching the network, then update inputs, rebuild+switch, and print a generation diff:
- `my-update` (`nixos-desktop/shell.nix`) — `nix-channel --update` + `nix flake update` (all inputs) + switch + `nvd diff`
- `my-update-elo` (`nixos-desktop/elo-web-service.nix`) — updates only the `elo` flake input + switch + `nvd diff`

Other useful commands:
```
nix flake update --flake /dotfiles-repo            # bump every input, rewrites flake.lock
nix flake update elo --flake /dotfiles-repo        # bump a single input (e.g. elo, nixpkgs-unstable)
nix flake check                                    # evaluate the flake outputs
nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)   # diff the last two system generations
nixfmt <file.nix>                                  # formatter (nixfmt-rfc-style is in systemPackages)
```

There's no test suite — "correctness" means the flake evaluates and `nixos-rebuild switch` succeeds. After editing a `.nix` file, prefer `sudo nixos-rebuild build --flake /dotfiles-repo#nixos-desktop` (or `nix flake check`) to catch evaluation errors before recommending a `switch`/`test`.

`.envrc` is `use flake`, so direnv loads a devShell that provides only `python3`.

## Architecture

- `flake.nix` is the entry point and defines a single output: `nixosConfigurations.nixos-desktop`. Inputs worth knowing: `nixpkgs` pinned to `nixos-26.05`, plus `nixpkgs-unstable` exposed to every module as `unstable` via `specialArgs` (used to pull newer package versions where needed, e.g. `unstable.claude-code`); `home-manager`; `sops-nix`; a private `secrets` flake (`git+ssh://...dotfiles-secrets.git`, exposed as `secrets`; locally checked out at `~/Repo/Tolyandre/dotfiles-secrets`); and `elo` (the author's own `tolyandre/elo` flake, which supplies the `elo-web-service` NixOS module).
- `nixos-desktop/configuration.nix` is the top-level system module: it `imports` every other module file/dir, and directly defines users (`toly`, `game`), locale/timezone, bootloader, filesystems (a separate `/mnt/data` btrfs volume bind-mounted onto `/home` and `/tmp`), sudo NOPASSWD rules for read-only diagnostic tools (`df`, `smartctl`, `nvme`, …), the auto-upgrade window, and `home-manager.users.toly`.
- Every other concern gets its own module file (or subdirectory) next to `configuration.nix` and is added to its `imports` list — follow that pattern for new services/features rather than growing `configuration.nix` itself. Modules use the standard `{ config, pkgs, ... }` signature, adding `unstable`/`secrets` only where actually needed.
- `nixos-desktop/home-toly/` is the home-manager profile for `toly`; `default.nix` aggregates `git.nix`, `packages.nix`, `podman.nix`, `dosbox.nix`.
- Secrets are never committed in plaintext: `sops.secrets.*` entries point at `.sops`-encrypted files living in the `secrets` flake input, decrypted at activation by `sops-nix` using the age key at `/my-secrets/sops-nix/key.txt`.
- A number of self-hosted services each have their own `<name>.nix` module (`elo-web-service`, `guacamole`, `navidrome`, `ocis`, `open-webui` + Ollama, `immich`, plus support modules like `postgresql.nix` and `backup.nix`/rsnapshot) and are reverse-proxied through Caddy (`nixos-desktop/caddy/caddy.nix`) under the `toly.is-cool.dev` domain and a couple of dedicated subdomains.
- `obsolete/` is the previous provisioning approach (chezmoi dotfiles + Ansible playbooks), kept only for reference — the live system is fully flake-driven now; don't extend it.
- `snippets/` holds standalone `nix-shell` shebang scripts run directly, not part of the system build.
- `result` (the build-output symlink) and `.direnv` are gitignored; `flake.lock` is tracked and updated by the commands above.

## Notes

- Comments in modules frequently record *why*, not just *what* (proxy quirks, hardware-specific fixes, maintenance steps such as the password-reset procedure in `ocis.nix`) — read them before touching nearby options, and add similar notes for any non-obvious choice you introduce.
- Never hand-edit `nixos-desktop/hardware-configuration.nix` — it's regenerated by `nixos-generate-config`.
