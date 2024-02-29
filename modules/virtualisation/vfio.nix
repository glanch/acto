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
    vfioDevices = mkOption {
      type = types.listOf types.str;
      default = [ "10de:1e81" "10de:10f8" "10de:1ad8" "10de:1ad9" "1002:164e" ];
    };
    blacklistNvidia = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable
    {
      virtualisation.vfio = {
        enable = true;
        IOMMUType = "amd";
        blacklistNvidia = cfg.blacklistNvidia;
        ignoreMSRs = false;
        devices = cfg.vfioDevices;
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
        defaultPageSize = "1G";
        pageSize = "1G";
        numPages = 16;
      };

      users.users.christopher.extraGroups = [ "libvirtd" "kvm" "input" ];
    };
}

