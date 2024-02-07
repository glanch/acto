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
        devices = ["10de:1401" "10de:0fba"];
      };

      users.users.qemu-libvirtd.group = "qemu-libvirtd";
      users.groups.qemu-libvirtd = { };

      virtualisation.libvirtd = {
        enable = true;
        deviceACL = [ 
          "/dev/kvm"
          "/dev/kvmfr0"
        ];
        qemu.networks.declarative = true;
        qemu.networks.networks = {
          default = {
            config = {
              bridge = { name = "virbr0"; };
              forward = { mode = "nat"; };

              ips = [
                {
                  family = "ipv4";
                  address = "192.168.100.1";
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

            autostart = true;
          };

          rawXml = {
            xml = ''
              <network>
                <name>rawWithOverrides</name>
                <bridge name="virbr0"/>
                <forward mode="nat"/>
                <ip address="192.168.122.1" netmask="255.255.255.0">
                  <dhcp>
                    <range start="192.168.122.2" end="192.168.122.254"/>
                  </dhcp>
                </ip>
                <ip family="ipv6" address="2001:db8:ca2:2::1" prefix="64"/>
              </network>
            '';
          };
        };

        qemu.domains = {
          declarative = true;

          domains = {
            nixos = {
              config = {
                memory = {
                  memory = {
                    value = 16;
                    unit = "G";
                  };

                  disableBallooning = true;
                  useHugepages = false;
                };

                os.enableBootmenu = true;

                vcpu = {
                  count = 4;
                  placement = "static";
                };

                # cputune = {
                #   vcpupins = [
                #     {
                #       vcpu = 1;
                #       cpuset = [ 1 ];
                #     }
                #     {
                #       vcpu = 2;
                #       cpuset = [ 2 ];
                #     }
                #   ];
                # };

                cpu = {
                  topology = {
                    sockets = 1;
                    dies = 1;
                    cores = 4;
                    threads = 1;
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

                pciHostDevices = [{
                  sourceAddress = {
                    bus = "0x16";
                    slot = "0x00";
                    function = 0;
                  };
                }];

                networkInterfaces = [{ sourceNetwork = "default"; }];

                cdroms = [{
                  sourceFile = "/opt/someIso.iso";
                  bootIndex = 1;
                }];

                kvmfr = {
                  device = "/dev/kvmfr0";
                  size = "33554432";
                };
              };
            };

            # rawXml.xml = ''
            #   <domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="kvm">
            #     <name>rawXml</name>
            #     <memory>131072</memory>
            #     <vcpu>1</vcpu>
            #     <os>
            #       <type arch="i686">hvm</type>
            #     </os>
            #     <devices>
            #       <emulator>/usr/bin/qemu-kvm</emulator>
            #       <disk type="file" device="disk">
            #         <source file="/var/lib/libvirt/images/demo2.img"/>
            #         <target dev="hda"/>
            #       </disk>
            #       <interface type="network">
            #         <source network="default"/>
            #         <mac address="24:42:53:21:52:45"/>
            #       </interface>
            #       <graphics type="vnc" port="-1" keymap="de"/>
            #     </devices>
            #   </domain>
            # '';
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
    };
}

