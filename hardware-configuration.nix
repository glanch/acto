# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, modulesPath, nixpkgs-unstable, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      ./modules/hardware/msi-pro-x670-p.nix
      ./modules/hardware/disk-config.nix
      ./modules/hardware/brightness.nix
      ./modules/hardware/bluetooth.nix
      ./modules/hardware/coolercontrol.nix
      ./modules/hardware/amdgpu.nix
      ./modules/hardware/openrgb.nix
    ];

  boot.initrd.availableKernelModules = [ "ahci" "nvme" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];

  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [
    "amd_iommu=on"
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
