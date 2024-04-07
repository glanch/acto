# microvm refers to microvm.nixosModules
{ lib, config, pkgs, microvm, ... }:
with lib;
let
  cfg = config.custom.virtualisation.vms.fancontrol-microvm;
  sshPubKey = builtins.readFile ../../../identities/acto/christopher.pub;


in
{
  imports = [ microvm.nixosModules.host ];

  options.custom.virtualisation.vms.fancontrol-microvm = {
    enable = mkEnableOption "Enable fancontrol microvm VM with RTX2080 Super passthrough";
    hostname = mkOption {
      type = types.str;
      default = "fancontrol";
    };
  };

  config =
    let
      hostIPv4Address = "10.5.10.1/24";
      vmIPv4Address = "10.5.10.4";
      vmMacAddress = "02:00:00:00:00:01";
      vmTapId = "vm-fancontrol";
      bridgeName = "br-fancontrol";


    in
    lib.mkIf cfg.enable
      {
        assertions = [{
          assertion = config.custom.virtualisation.vfio.enable;
          message = "VFIO needs to be enabled for fancontrol-microvm VM to function";
        }];

        systemd.network = {
          netdevs."10-microvm".netdevConfig = {
            Kind = "bridge";
            Name = bridgeName;
          };

          networks."10-microvm" =
            {
              matchConfig.Name = bridgeName;
              networkConfig = {
                DHCPServer = true;
                IPv6SendRA = true;
              };
              addresses = [
                {
                  addressConfig.Address = hostIPv4Address;
                }
                {
                  addressConfig.Address = "fd12:3456:789a::1/64";
                }
              ];
              dhcpServerStaticLeases = [
                {
                  dhcpServerStaticLeaseConfig = {
                    Address = vmIPv4Address;
                    MACAddress = vmMacAddress;
                  };
                }
              ];
              ipv6Prefixes = [{
                ipv6PrefixConfig.Prefix = "fd12:3456:789a::/64";
              }];
            };
        };

        nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "nvidia-x11"
        ];
        systemd.network.networks."11-microvm" = {
          matchConfig.Name = vmTapId;
          # Attach to the bridge that was configured above
          networkConfig.Bridge = bridgeName;
        };

        systemd.services."fancontrol-at-boot" = {
          wantedBy = [ "multi-user.target" ];
          requires = [ "microvm@fancontrol.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };


          script = ''
            echo "Starting fancontrol microvm at boot"
          '';
        };

        microvm.vms = {
          fancontrol = {
            autostart = false;
            # The package set to use for the microvm. This also determines the microvm's architecture.
            # Defaults to the host system's package set if not given.
            /* pkgs = import nixpkgs { system = pkgs.system; };*/

            # (Optional) A set of special arguments to be passed to the MicroVM's NixOS modules.
            #specialArgs = {};

            # The configuration for the MicroVM.
            # Multiple definitions will be merged as expected.
            config = {
              # It is highly recommended to share the host's nix-store
              # with the VMs to prevent building huge images.
              microvm.shares = [{
                source = "/nix/store";
                mountPoint = "/nix/.ro-store";
                tag = "ro-store";
                proto = "virtiofs";
              }];

              microvm.devices = [
                {
                  bus = "pci";
                  path = "0000:18:00.0";
                }
              ];
              microvm.interfaces = [
                {
                  type = "tap";
                  id = vmTapId;
                  mac = vmMacAddress;
                }
              ];

              # Just use 99-ethernet-default-dhcp.network
              systemd.network.enable = true;

              # Enable OpenGL
              hardware.opengl = {
                enable = true;
                driSupport = true;
                driSupport32Bit = true;
              };
              services.xserver = {
                enable = true;
                videoDrivers = [ "nvidia" ];

                displayManager.startx.enable = true;
              };
              # NVidia
              hardware.nvidia = {

                # Modesetting is required.
                modesetting.enable = true;

                # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
                powerManagement.enable = true;

                # Fine-grained power management. Turns off GPU when not in use.
                # Experimental and only works on modern Nvidia GPUs (Turing or newer).
                powerManagement.finegrained = false;

                # Use the NVidia open source kernel module (not to be confused with the
                # independent third-party "nouveau" open source driver).
                # Support is limited to the Turing and later architectures. Full list of 
                # supported GPUs is at: 
                # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
                # Only available from driver 515.43.04+
                # Currently alpha-quality/buggy, so false is currently the recommended setting.
                open = true;

                # Enable the Nvidia settings menu,
                # accessible via `nvidia-settings`.
                nvidiaSettings = true;

                # Optionally, you may need to select the appropriate driver version for your specific GPU.
                # package = config.boot.kernelPackages.nvidiaPackages.stable;
              };

              networking.hostName = cfg.hostname;

              environment.systemPackages = [
                pkgs.pciutils
                pkgs.lm_sensors
              ];

              users.mutableUsers = false;
              users.users.root.openssh.authorizedKeys.keys = [
                sshPubKey
              ];

              services.openssh = {
                enable = true;
                settings.PermitRootLogin = "yes";
              };
            };
          };
        };

        # Add entry to hosts as cheap DNS resolution of cfg.hostname
        networking.extraHosts =
          ''
            ${vmIPv4Address} ${cfg.hostname}
          '';
      };
}

