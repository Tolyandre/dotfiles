# Repository Guidelines

## Project Structure & Module Organization

This repository is a NixOS + home-manager flake for the single host `nixos-desktop`.

- `flake.nix` is the entry point and defines `nixosConfigurations.nixos-desktop`.
- `flake.lock` is tracked; update it only through Nix flake commands.
- `nixos-desktop/` contains active NixOS modules. Add services as focused module files and import them from `nixos-desktop/configuration.nix`.
- `nixos-desktop/home-toly/` contains the home-manager profile for user `toly`; `default.nix` aggregates the per-topic files.
- `nixos-desktop/caddy/`, `dotnet/`, and `happ/` group related service or tool configuration.
- `snippets/` contains standalone scripts.
- `obsolete/` is retained for reference only; do not extend it.

## Build, Test, and Development Commands

- `nix flake check` evaluates flake outputs.
- `sudo nixos-rebuild build --flake /dotfiles-repo#nixos-desktop` builds without activating.
- `sudo nixos-rebuild test --flake /dotfiles-repo#nixos-desktop` activates temporarily without changing the default boot entry.
- `sudo nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop` applies changes to the live machine.
- `nix flake update --flake /dotfiles-repo` updates all inputs.
- `nix flake update elo --flake /dotfiles-repo` updates one input.
- `nixfmt <file.nix>` formats Nix files.

`.envrc` uses `use flake`; the dev shell provides `python3`.

## Coding Style & Naming Conventions

Use `nixfmt` for `.nix` files. Keep modules small and topic-oriented, named after the service or concern, for example `navidrome.nix` or `postgresql.nix`. Prefer standard module arguments such as `{ config, pkgs, ... }`; add `unstable` or `secrets` only where needed. Comments should explain non-obvious reasons or operational procedures.

Never hand-edit `nixos-desktop/hardware-configuration.nix`; regenerate it with `nixos-generate-config` when hardware changes.

## Testing Guidelines

There is no separate test suite. Treat successful evaluation and rebuilds as validation. After editing Nix modules, run `nix flake check` or `sudo nixos-rebuild build --flake /dotfiles-repo#nixos-desktop`. Use `test` before `switch` for risky service or boot changes.

## Commit & Pull Request Guidelines

Recent history uses short, imperative subjects, often conventional prefixes such as `feat:` and scoped fixes such as `fix(git): ...`; simple `update` commits also appear. Prefer descriptive subjects like `feat: add navidrome backup` or `fix(caddy): correct proxy target`.

Pull requests should describe the affected module, the validation command run, and any activation or migration steps. Include screenshots only for visible UI or web content changes.

## Security & Configuration Tips

Do not commit plaintext secrets. Secret references should use the `secrets` flake and `sops-nix`. Be careful with commands that activate the live system; this repo is used directly from `/dotfiles-repo` on the target machine.
