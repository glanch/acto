{ lib, config, pkgs, nixos-vfio, ... }:
with lib;
let
  cfg = config.custom.virtualisation.vfio;
in
{
  imports = [
    nixos-vfio.nixosModules.default
    ./vms/win10-libvirtd.nix
    ./vms/win11-libvirtd.nix
    ./vms/microvms
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

      environment.systemPackages = with pkgs; [
        swtpm
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        win-virtio
        win-spice
        virtiofsd
      ];
      systemd.services.libvirtd.path = [ pkgs.swtpm ];
      virtualisation.libvirtd =
        let
          hostCores = "0-7,16-23";
          totalCores = "0-31";
        in
        {
          enable = true;
          onBoot = "ignore";
          onShutdown = "shutdown";

          deviceACL = [
            "/dev/vfio/vfio"
            "/dev/kvm"
            "/dev/kvmfr0"
            "/dev/kvmfr1"
            "/dev/kvmfr2"
            "/dev/null"
            "/dev/shm/scream"
            "/dev/shm/looking-glass"
          ];

          qemu = {
            swtpm.enable = true;
            ovmf.enable = true;
            ovmf.packages = [ pkgs.OVMFFull.fd ];
          }; 
          
          /*           scopedHooks.qemu = {
            "10-activate-core-isolation" = {
              enable = true;
              scope = {
                objects = [ "win10" ];
                operations = [ "prepare" ];
              };
              script = ''
                systemctl set-property --runtime -- user.slice AllowedCPUs=${hostCores}
                systemctl set-property --runtime -- system.slice AllowedCPUs=${hostCores}
                systemctl set-property --runtime -- init.scope AllowedCPUs=${hostCores}
              '';
            };

            "10-deactivate-core-isolation" = {
              enable = true;
              scope = {
                objects = [ "win10" ];
                operations = [ "release" ];
              };
              script = ''
                systemctl set-property --runtime -- user.slice AllowedCPUs=${totalCores}
                systemctl set-property --runtime -- system.slice AllowedCPUs=${totalCores}
                systemctl set-property --runtime -- init.scope AllowedCPUs=${totalCores}
              '';
            };
          }; */


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
            # Resolution seems broken: https://github.com/j-brn/nixos-vfio/issues/85
            # (permissions // {
            #   resolution = {
            #     width = 2560;
            #     height = 1440;
            #     pixelFormat = "rgba32";
            #   };
            # })
            # (permissions // {
            #   resolution = {
            #     width = 3840;
            #     height = 2160;
            #     pixelFormat = "rgba32";
            #   };
            # })
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

