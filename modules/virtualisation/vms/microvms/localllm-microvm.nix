# microvm refers to microvm.nixosModules
{ nixpkgs, lib, config, pkgs, microvm, ... }:
with lib;
let
  cfg = config.custom.virtualisation.vms.localllm-microvm;
  sshPubKey = builtins.readFile ../../../../identities/acto/christopher.pub;


in
{
  options.custom.virtualisation.vms.localllm-microvm = {
    enable = mkEnableOption "Enable localllm microvm VM with RTX2080 Super passthrough";
    hostname = mkOption {
      type = types.str;
      default = "localllm";
    };
  };

  config =
    let
      maxVMs = 2;
      index = 2;
      mac = "00:00:00:00:00:10";
    in
    lib.mkIf cfg.enable
      {
        assertions = [{
          assertion = config.custom.virtualisation.vfio.enable;
          message = "VFIO needs to be enabled for localllm-microvm VM to function";
        }];

        systemd.network = {
          networks = builtins.listToAttrs (
            map
              (index: {
                name = "30-vm${toString index}";
                value = {
                  matchConfig.Name = "vm${toString index}";
                  # Host's addresses
                  address = [
                    "10.0.0.0/32"
                    "fec0::/128"
                  ];
                  # Setup routes to the VM
                  routes = [{
                    Destination = "10.0.0.${toString index}/32";
                  }
                    {
                      Destination = "fec0::${lib.toHexString index}/128";
                    }];
                  # Enable routing
                  networkConfig = {
                    IPv4Forwarding = true;
                    IPv6Forwarding = true;
                  };
                };
              })
              (lib.genList (i: i + 1) maxVMs)
          );
        };

        systemd.services."microvm@localllm".serviceConfig.ExecCondition =
          pkgs.writeScript "check_vfio_status.sh" ''
            #! ${pkgs.runtimeShell} -e
            content=$(< /sys/bus/pci/drivers/vfio-pci/0000\:18\:00.0/enable)

            # Check if the content is equal to 0
            if [ "$content" == "0" ]; then
              exit 0
            else
              exit 1
            fi
          '';

        microvm.vms =
          let
            openWebUiStateWrapperContainer = "/var/lib/open-webui-state";
            openWebUiStateContainer = "${openWebUiStateWrapperContainer}/state";

            ollamaStateWrapperContainer = "/var/lib/ollama-state";
            ollamaStateContainer = "${ollamaStateWrapperContainer}/home";

          in
          {
            localllm = {
              unbindPciDevices = false;
              autostart = false;
              pkgs = import nixpkgs {
                config = {
                  allowUnfree = true;
                  allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
                    "nvidia-x11"
                  ];
                };
                system = pkgs.system;
              };

              config = { config, ... }: {
                microvm.interfaces = [{
                  id = "vm${toString index}";
                  type = "tap";
                  inherit mac;
                }];

                networking.useNetworkd = true;

                systemd.network.networks."10-eth" = {
                  matchConfig.MACAddress = mac;
                  # Static IP configuration
                  address = [
                    "10.0.0.${toString index}/32"
                    "fec0::${lib.toHexString index}/128"
                  ];
                  routes = [{
                    # A route to the host
                    Destination = "10.0.0.0/32";
                    GatewayOnLink = true;
                  }
                    {
                      # Default route
                      Destination = "0.0.0.0/0";
                      Gateway = "10.0.0.0";
                      GatewayOnLink = true;
                    }
                    {
                      # Default route
                      Destination = "::/0";
                      Gateway = "fec0::";
                      GatewayOnLink = true;
                    }];
                  networkConfig = {
                    # DNS servers no longer come from DHCP nor Router
                    # Advertisements. Perhaps you want to change the defaults:
                    DNS = [
                      # Quad9.net
                      "9.9.9.9"
                      "149.112.112.112"
                      "2620:fe::fe"
                      "2620:fe::9"
                    ];
                  };
                };


                system.stateVersion = "25.05";
                microvm.shares = [
                  {
                    source = "/nix/store";
                    mountPoint = "/nix/.ro-store";
                    tag = "ro-store";
                    proto = "virtiofs";
                  }
                  {
                    proto = "virtiofs";
                    tag = "ollama";
                    source = "state/ollama";
                    mountPoint = ollamaStateWrapperContainer;
                  }
                  {
                    proto = "virtiofs";
                    tag = "open-webui";
                    source = "state/open-webui";
                    mountPoint = openWebUiStateWrapperContainer;
                  }
                ];
                systemd.tmpfiles.settings."10-open-webui-state" = {
                  ${ollamaStateContainer} = {
                    d = {
                      mode = "0750";
                      user = config.systemd.services.ollama.serviceConfig.User;
                      group = config.systemd.services.ollama.serviceConfig.Group;
                    };
                  };
                  ${openWebUiStateContainer} = {
                    d = {
                      mode = "0750";
                      user = config.systemd.services.open-webui.serviceConfig.User;
                      group = config.systemd.services.open-webui.serviceConfig.Group;
                    };
                  };
                };

                imports = [ ../../../local-llm.nix ];

                microvm.vcpu = 16;
                microvm.mem = 4*8192;
                services.open-webui = {
                  openFirewall = true;
                  stateDir = openWebUiStateContainer;
                  host = "::";
                };
                systemd.services.open-webui.serviceConfig = {
                  User = "open-webui";
                  Group = "open-webui";
                  DynamicUser = lib.mkForce false;
                };

                users.users.open-webui = {
                  isSystemUser = true;
                  group = "open-webui";
                };
                users.groups.open-webui = { };

                systemd.services.ollama.serviceConfig = {
                  DeviceAllow = lib.mkForce [ ];
                  DevicePolicy = lib.mkForce "auto";
                };

                services.ollama = {
                  acceleration = lib.mkForce "cuda";
                  user = "ollama";
                  group = "ollama";
                  home = ollamaStateContainer;
                };

                microvm.devices = [
                  {
                    bus = "pci";
                    path = "0000:18:00.0";
                  }
                ];

                systemd.network.enable = true;

                # Enable OpenGL
                hardware.graphics = {
                  enable = true;
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
                  open = false;

                  # Enable the Nvidia settings menu,
                  # accessible via `nvidia-settings`.
                  nvidiaSettings = true;

                  # Optionally, you may need to select the appropriate driver version for your specific GPU.
                  # package = config.boot.kernelPackages.nvidiaPackages.stable;
                };

                networking.hostName = cfg.hostname;

                environment.systemPackages = with pkgs; [
                  pciutils
                  lm_sensors
                  nvtopPackages.nvidia
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
            fec0::2 ${cfg.hostname}
          '';
        networking.nat = {
          enable = true;
          internalIPs = [ "10.0.0.0/24" ];
          # Change this to the interface with upstream Internet access
          externalInterface = "wlp14s0";
        };
      };
}

