{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.virtualisation.vms.win10-libvirtd;
in
{
  options.custom.virtualisation.vms.win10-libvirtd = {
    enable = mkEnableOption "Enable Windows 10 libvirtd VM with RTX2080 Super and red USB port passthrough";
  };

  config = lib.mkIf cfg.enable
    {
      assertions = [{
        assertion = config.custom.virtualisation.vfio.enable;
        message = "VFIO needs to be enabled for win10-libvirtd VM to function";
      }];
      virtualisation.libvirtd = {


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
                <source file="/home/christopher/.qcow-storage/win10/win10.qcow2"/>
                <backingStore/>
                <target dev="vdb" bus="sata"/>
                <address type="drive" controller="0" bus="0" target="0" unit="1"/>
              </disk>
            '';
          };

          /*         fancontrol.autostart = true;
        fancontrol.config = {
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

          cdroms = [
            {
              sourceFile = "/home/christopher/Downloads/nixos-minimal-23.11.5833.1487bdea619e-x86_64-linux.iso";
              bootIndex = 2;
            }
          ];

          devicesExtraXml = ''
            <disk type="file" device="disk"> 
              <driver name="qemu" type="qcow2"/>
              <source file="/home/christopher/.qcow-storage/fancontrol/fancontrol.qcow2"/>
              <backingStore/>
              <target dev="vdb" bus="sata"/>
              <address type="drive" controller="0" bus="0" target="0" unit="1"/>
              <boot order="1"/>
            </disk>
          '';
          }; */
        };
      };
    };
}
