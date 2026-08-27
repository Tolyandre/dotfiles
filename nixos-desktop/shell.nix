{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "my-update-elo" ''
      set -e

      export https_proxy="http://127.0.0.1:2080"
      export http_proxy="http://127.0.0.1:2080"
      export no_proxy="localhost,127.0.0.1"

      nix flake update elo elo-stage --flake /dotfiles-repo

      nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop

      echo ""
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '')

    (writeShellScriptBin "my-update" ''
      set -e

      export https_proxy="http://127.0.0.1:2080"
      export http_proxy="http://127.0.0.1:2080"
      export no_proxy="localhost,127.0.0.1"

      nix-channel --update
      nix flake update --flake /dotfiles-repo

      nixos-rebuild switch --flake /dotfiles-repo#nixos-desktop

      echo ""
      nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -2)
    '')

    (writeShellScriptBin "my-update-nh" ''
      set -e

      export https_proxy="http://127.0.0.1:2080"
      export http_proxy="http://127.0.0.1:2080"
      export no_proxy="localhost,127.0.0.1"

      nix-channel --update
      nix flake update --flake /dotfiles-repo

      nh os switch /dotfiles-repo#nixos-desktop
    '')

    # Reset the AMD GPU after the system wakes from sleep (6700XT reset bug).
    # Must be run as root: it writes to /sys, arms an rtcwake alarm, and suspends.
    # Based on https://forum.level1techs.com/t/6700xt-reset-bug/181814/19
    (writeShellScriptBin "my-sleep-reset" ''
      set -ex

      slot_gpu="0000:03:00.0"
      slot_gpu_sound="0000:03:00.1"

      echo 1 > /sys/bus/pci/devices/$slot_gpu/remove
      echo 1 > /sys/bus/pci/devices/$slot_gpu_sound/remove

      echo "Suspending..."
      rtcwake -m no -s 4
      systemctl suspend
      sleep 5s

      echo 1 > /sys/bus/pci/rescan
      echo "Reset done"
    '')
  ];
}
