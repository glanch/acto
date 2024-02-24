{ lib, config, pkgs, nixos-vfio, ... }:
with lib;
let
  cfg = config.custom.virtualisation.vfio;
in
{
  imports = [
    nixos-vfio.nixosModules.default
  ];
  options.custom.virtualisation.vfio = {
    enable = mkEnableOption "Enable VFIO";
  };

  config = mkIf cfg.enable
    {
      virtualisation.vfio = {
        enable = true;
        IOMMUType = "amd";
        blacklistNvidia = true;
        ignoreMSRs = false;
        devices = [ "10de:1e81" "10de:10f8" "10de:1ad8" "10de:1ad9" "1002:164e"];
      };

      users.users.qemu-libvirtd.group = "qemu-libvirtd";
      users.groups.qemu-libvirtd = { };

      virtualisation.libvirtd = {
        enable = true;
        deviceACL = [
          "/dev/kvm"
          "/dev/kvmfr0"
        ];
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = true;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            edf2 = true;
            packages = [
              (pkgs.OVMFFull.override {
                secureBoot = true;
                tpmSupport = true;
              }).fd
            ];
          };
        };
      };

      virtualisation.kvmfr = {
        enable = true;

        devices = [
          {
            size = 128; # in MiB
            permissions = {
              user = "christopher";
              group = "christopher";
              mode = "0777";
            };
          }
        ];
      };

      virtualisation.hugepages = {
        enable = true;
      };

      users.users.christopher.extraGroups = [ "libvirtd" "kvm" "input" ];
    };
}

