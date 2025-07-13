{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.virtualisation.vms.win11-libvirtd;
in
{
  options.custom.virtualisation.vms.win11-libvirtd = {
    enable = mkEnableOption "Enable Windows 10 WIP libvirtd VM with RTX2080 Super and red USB port passthrough";
    kvmfr.device = mkOption {
      type = types.str;
      default = "/dev/kvmfr0";
    };
    kvmfr.size = mkOption {
      type = types.str;
      default = "134217728"; # 128 MiB
    };
    useUnstableLookingGlass = mkOption {
      type = types.bool;
      default = false;
    };
  };


  config =
    let
      vm-name = "win11";

      looking-glass-client-vm-cmd = "${if cfg.useUnstableLookingGlass then pkgs.moonlightlookingglass.looking-glass-client else pkgs.looking-glass-client}/bin/looking-glass-client app:shmFile=${cfg.kvmfr.device} -k egl:scale=2";

      virsh-basic-cmd = "${pkgs.libvirt}/bin/virsh --connect qemu:///system";

      start-vm-cmd = "${virsh-basic-cmd} start ${vm-name}";
      shutdown-vm-cmd = "${virsh-basic-cmd} shutdown ${vm-name}";
      reboot-vm-cmd = "${virsh-basic-cmd} reboot ${vm-name}";
      poweroff-vm-cmd = "${virsh-basic-cmd} destroy ${vm-name}";
      reset-vm-cmd = "${virsh-basic-cmd} reset ${vm-name}";

      commands = {
        "Looking Glass" = looking-glass-client-vm-cmd;
        "Start" = start-vm-cmd;
        "Shutdown" = shutdown-vm-cmd;
        "Poweroff" = poweroff-vm-cmd;
        "Reboot" = reboot-vm-cmd;
        "Reset" = reset-vm-cmd;
      };


      # Generate desktop entries for each command
      desktop-entries = mapAttrs'
        (command_name: command: nameValuePair ("${vm-name}-vm-${command_name}") (
          {
            name = "${vm-name}: ${command_name} VM";
            exec = command;
            terminal = false;
          }
        ))
        commands;
    in
    lib.mkIf cfg.enable
      {
        assertions = [{
          assertion = config.custom.virtualisation.vfio.enable;
          message = "VFIO needs to be enabled for win11-libvirtd VM to function";
        }];


        systemd.network = {
          netdevs = {
            # Create the bridge interface
            "20-virbr-win11-bridged" = {
              netdevConfig = {
                Kind = "bridge";
                Name = "virbr-win11";
              };
            };
          };
          networks = {
            # Connect the bridge ports to the bridge
            /* "30-enp1s0" = {
              matchConfig.Name = "enp7s0";
              networkConfig.Bridge = "virbr-win10-bridged";
               linkConfig.RequiredForOnline = "enslaved"; 
            }; */
            # Configure the bridge for its desired function
            "40-virbr-win11-bridged" = {
              matchConfig.Name = "virbr-win11";
              bridgeConfig = { };
              # Disable address autoconfig when no IP configuration is required
              #networkConfig.LinkLocalAddressing = "no";
              linkConfig = {
                # or "routable" with IP addresses configured
                RequiredForOnline = "carrier";
              };
            };
          };
        };

        home-manager.users.christopher = { ... }: {
          xdg.desktopEntries = {
            "win11-VMstartAndLookingGlass" = {
              name = "${vm-name}: Start VM and Looking Glass";
              exec =
                let
                  script = pkgs.writeShellScript "start_vm_and_desktop.sh" ''
                    ${commands.Start}
                    ${looking-glass-client-vm-cmd}
                  '';
                in
                "${script}";
              terminal = false;
            };
          } // desktop-entries;
        };
        networking.firewall = {
          enable = false;
        };
        networking.nat = {
          enable = true;
          internalInterfaces = [ "br-win11nat" ];
          externalInterface = "wlp14s0";
          forwardPorts =
            let
              destinationIp = "192.168.102.128";
              mkForwardPortsEntry = proto: port: {
                destination = "${destinationIp}:${toString port}";
                proto = proto;
                sourcePort = port;
              };
              tcpPorts = [ 47984 47989 48010 ];
              udpPorts = [ 47998 47999 48000 48002 48010 ];
            in
            map (mkForwardPortsEntry "tcp") tcpPorts
            ++
            map (mkForwardPortsEntry "udp") udpPorts;
        };
        virtualisation.libvirtd = {
          qemu.networks.declarative = true;
          qemu.networks.networks = {
            win11-net.config = {
              bridge.name = "br-win11wipnat";
              forward = { mode = "nat"; };

              ips = [
                {
                  family = "ipv4";
                  address = "192.168.102.2";
                  prefix = 24;

                  dhcpRanges = [{
                    start = "192.168.102.128";
                    end = "192.168.102.128";
                  }];
                }
                {
                  family = "ipv6";
                  address = "fd12:3456:789a:2::1";
                  prefix = 64;

                  dhcpRanges = [{
                    start = "fd12:3456:789a:2::100";
                    end = "fd12:3456:789a:2::1ff";
                  }];
                }
              ];
            };
            win11-net.autostart = true;

            win11-bridged.config = {
              bridge.name = "virbr-win11-bridged";
              forward = { mode = "bridge"; };
              ips = [ ];
            };
            win11-bridged.autostart = true;
          };



          qemu.domains.declarative = true;


          qemu.domains.domains = {
            "${vm-name}".config = {
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

              networkInterfaces = [{ sourceNetwork = "win11-net"; }];

              kvmfr = {
                device = cfg.kvmfr.device;
                size = cfg.kvmfr.size; # TODO: refactor this magic constant
              };
              devicesExtraXml = ''
                <disk type="file" device="disk"> 
                  <driver name="qemu" type="qcow2"/>
                  <source file="/home/christopher/.qcow-storage/win11/win11.qcow2"/>
                  <backingStore/>
                  <target dev="vdb" bus="sata"/>
                  <address type="drive" controller="0" bus="0" target="0" unit="1"/>
                </disk>
                <disk type="file" device="disk"> 
                  <driver name="qemu" type="qcow2"/>
                  <source file="/home/christopher/.qcow-storage/win10/win10.qcow2"/>
                  <backingStore/>
                  <target dev="vdc" bus="sata"/>
                  <address type="drive" controller="0" bus="0" target="0" unit="0"/>
                </disk>
                
                <hostdev mode="subsystem" type="usb" managed="yes">
                  <source>
                    <vendor id="0x1532"/>
                    <product id="0x0085"/>
                  </source>
                  <address type="usb" bus="0" port="1"/>
                </hostdev>

                <tpm model="tpm-crb">
                  <backend type="emulator" version="2.0"/>
                </tpm>
              '';
            };
          };

          scopedHooks.qemu = mkIf config.custom.virtualisation.vms.fancontrol-microvm.enable {
            "10-${vm-name}-prepare-stop-fancontrol-microvm" = {
              enable = true;
              scope = {
                objects = [ vm-name ];
                operations = [ "prepare" ];
              };
              script = ''
                systemctl stop microvm@fancontrol.service
              '';
            };
            "10-${vm-name}-release-start-fancontrol-microvm" = {
              enable = true;
              scope = {
                objects = [ vm-name ];
                operations = [ "release" ];
              };
              script = ''
                systemctl start microvm@fancontrol.service
              '';
            };
          };
        };
      };
}
