{
  config,
  pkgs,
  ...
}:
{
  # QEMU/KVM + libvirt + virt-manager for desktop VMs (Windows and Linux
  # guests), display over SPICE. GPU passthrough is intentionally not set up
  # yet; when needed, bind the RX 6700 XT (1002:73df) and its HDMI audio
  # (1002:ab28) to vfio-pci via boot.kernelParams and pass them to the guest.
  # IOMMU groups are already isolated: 03:00.0 -> group 14, 03:00.1 -> group 15,
  # host desktop can stay on the Raphael iGPU (0e:00.0, group 25).
  virtualisation.libvirtd = {
    enable = true;
    # Emulated TPM 2.0 device, required by Windows 11 guests.
    qemu.swtpm.enable = true;
  };

  programs.virt-manager.enable = true;

  # Setuid helper that lets the SPICE client redirect USB devices into the guest.
  virtualisation.spiceUSBRedirection.enable = true;

  users.users.toly.extraGroups = [ "libvirtd" ];

  # VM disk images live on the NVMe btrfs (/mnt/data), not in the default pool
  # /var/lib/libvirt/images (root ext4 has only ~60G free). `vms` is a subvolume
  # so vm-backup.nix can take crash-consistent snapshots of it; `.snapshots` is
  # its own subvolume so snapshots never nest if /mnt/data itself is ever
  # snapshotted as a whole.
  systemd.services.vms-storage = {
    description = "Create btrfs subvolumes for VM images and their snapshots";
    wantedBy = [ "multi-user.target" ];
    after = [ "mnt-data.mount" ];
    requires = [ "mnt-data.mount" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for sub in /mnt/data/vms /mnt/data/.snapshots; do
        if ! ${pkgs.btrfs-progs}/bin/btrfs subvolume show "$sub" > /dev/null 2>&1; then
          ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$sub"
        fi
      done
      # VM images and their snapshots are root-only; nobody else on the machine
      # may read them. Snapshots (taken by vm-backup.nix) inherit this mode.
      chmod 700 /mnt/data/vms /mnt/data/.snapshots
    '';
  };

  # Register /mnt/data/vms as a libvirt storage pool named "vms" so it shows up
  # in virt-manager's disk dialog. The built-in "default" pool is left in
  # place; pick `vms` as the storage pool when creating VM disks.
  systemd.services.libvirt-vms-pool = {
    description = "Define and start the libvirt storage pool for VM images";
    wantedBy = [ "multi-user.target" ];
    after = [
      "libvirtd.service"
      "vms-storage.service"
    ];
    requires = [ "vms-storage.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if ! ${pkgs.libvirt}/bin/virsh pool-info vms > /dev/null 2>&1; then
        ${pkgs.libvirt}/bin/virsh pool-define-as --name vms --type dir --target /mnt/data/vms
        ${pkgs.libvirt}/bin/virsh pool-autostart vms
      fi
      # already-active on reboots (autostart); not an error
      ${pkgs.libvirt}/bin/virsh pool-start vms 2>/dev/null || true
    '';
  };
}
