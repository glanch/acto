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

      # Add virt-amanger, Looking Glass client and Moonlight
      users.users.christopher = {
        packages = with pkgs; [
          virt-manager
          looking-glass-client
          moonlight-qt
        ];
      };

      virtualisation.libvirtd = {
        enable = true;
        deviceACL = [
          "/dev/kvm"
          "/dev/kvmfr0"
          "/dev/kvmfr1"
          "/dev/kvmfr2"
          "/dev/shm/scream"
          "/dev/shm/looking-glass"
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

      # Add three kvmfr devices 
      virtualisation.kvmfr = {
        enable = true;

        devices =
          let
            permissions = {
              permissions = {
                user = "christopher";
                group = "christopher";
                mode = "0777";
              };
            };

          in
          [
            (permissions // {
              size = 128; # in MiB
            })
            (permissions // {
              resolution = {
                width = 2560;
                height = 1440;
                pixelFormat = "rgba32";
              };
            })
            (permissions // {
              resolution = {
                width = 3840;
                height = 2160;
                pixelFormat = "rgba32";
              };
            })
          ];
      };

      # Reserve total of 16GiB, 1GiB each, hugepages
      virtualisation.hugepages = {
        enable = true;
        defaultPageSize = "1G";
        pageSize = "1G";
        numPages = 16;
      };

      # Add shmem areas for both scream and looking-glass as a kvmfr backup
      virtualisation.sharedMemoryFiles = {
        scream = {
          user = "christopher";
          group = "christopher"; # TODO: check permissions
          mode = "666";
        };
        looking-glass = {
          user = "christopher";
          group = "christopher";
          mode = "666";
        };
      };
      users.users.christopher.extraGroups = [ "libvirtd" "kvm" "input" ];
    };
}

