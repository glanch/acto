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

      environment.systemPackages = with pkgs; [ swtpm ];
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

          qemu.networks.declarative = true;
          qemu.networks.networks = {
            default.config = {
              bridge.name = "virbr_win10_1";
              forward = { mode = "nat"; };

              ips = [
                {
                  family = "ipv4";
                  address = "192.168.100.2";
                  prefix = 24;

                  dhcpRanges = [{
                    start = "192.168.100.128";
                    end = "192.168.100.254";
                  }];
                }
                {
                  family = "ipv6";
                  address = "2001:db8:ca2:2::1";
                  prefix = 64;

                  dhcpRanges = [{
                    start = "2001:db8:ca2:2::100";
                    end = "2001:db8:ca2:2::1ff";
                  }];
                }
              ];
            };
            default.autostart = true;
          };

          qemu.domains.declarative = true;
          qemu.domains.domains = {
            win10.config = {
              memory = {
                memory = {
                  value = 16;
                  unit = "G";
                };

                disableBallooning = true;
                useHugepages = true;
              };

              vcpu = {
                count = 16;
                placement = "static";
              };

              cputune = {
                vcpupins = [
                  { vcpu = 0; cpuset = [ 0 ]; }
                  { vcpu = 1; cpuset = [ 16 ]; }
                  { vcpu = 2; cpuset = [ 1 ]; }
                  { vcpu = 3; cpuset = [ 17 ]; }
                  { vcpu = 4; cpuset = [ 2 ]; }
                  { vcpu = 5; cpuset = [ 18 ]; }
                  { vcpu = 6; cpuset = [ 3 ]; }
                  { vcpu = 7; cpuset = [ 19 ]; }
                  { vcpu = 8; cpuset = [ 4 ]; }
                  { vcpu = 9; cpuset = [ 20 ]; }
                  { vcpu = 10; cpuset = [ 5 ]; }
                  { vcpu = 11; cpuset = [ 21 ]; }
                  { vcpu = 12; cpuset = [ 6 ]; }
                  { vcpu = 13; cpuset = [ 22 ]; }
                  { vcpu = 14; cpuset = [ 7 ]; }
                  { vcpu = 15; cpuset = [ 23 ]; }
                ];
              };

              cpu = {
                mode = "host-passthrough";
                topology = {
                  sockets = 1;
                  dies = 1;
                  cores = 8;
                  threads = 2;
                };
              };

              input = {
                virtioMouse = true;
                virtioKeyboard = true;
              };

              spice = {
                spiceAudio = true;
                spicemvcChannel = true;
                spiceGraphics = true;
              };

              pciHostDevices = [
                # Nvidia RTX2080 Super
                {
                  sourceAddress = {
                    bus = "0x18";
                    slot = "0x00";
                    function = 0;
                  };
                }
                # USB Controller: red port on mainboards port
                {
                  sourceAddress = {
                    bus = "0x19";
                    slot = "0x00";
                    function = 3;
                  };
                }
              ];

              networkInterfaces = [{ sourceNetwork = "default"; }];

              kvmfr = {
                device = "/dev/kvmfr0";
                size = "33554432"; # TODO: refactor this magic constant
              };
              devicesExtraXml = ''
                <disk type="file" device="disk"> 
                  <driver name="qemu" type="qcow2"/>
                  <source file="/home/christopher/subvolumefoo/test/Win10Gaming.qcow2"/>
                  <backingStore/>
                  <target dev="vdb" bus="sata"/>
                  <address type="drive" controller="0" bus="0" target="0" unit="1"/>
                </disk>
              '';
            };
          };

          scopedHooks.qemu = {
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

