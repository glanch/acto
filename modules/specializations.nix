{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.specializations;
in
{
  options.custom.specializations = {
    enable = mkEnableOption "Add specializations to boot menu";
  };

  config = mkIf cfg.enable
    {
      specialisation =
        {
          "NoPassthrough-NVidiaDriver".configuration = {
            custom = {
              virtualisation.vfio = {
                blacklistNvidia = false;
                vfioDevices = [ ];
              };

              virtualisation.vms.fancontrol-microvm.enable = false;

              nvidia.enable = true;

            };
          };
          "NoPassthrough-Offloading".configuration = {
            custom = {
              virtualisation.vfio = {
                blacklistNvidia = false;
                vfioDevices = [ ];
              };

              virtualisation.vms.fancontrol-microvm.enable = false;

              nvidia.enable = true;
              nvidia.offloading = true;

            };
          };
          "VFIO-Raphael".configuration = {
            system.nixos.tags = [ "Raphael-VFIO" ];
            custom = {
              virtualisation.vfio = {
                blacklistNvidia = false;
                vfioDevices = RaphaeliGPUPCIDevices;
              };

              virtualisation.vms.fancontrol-microvm.enable = false;

              nvidia.enable = false;
            };

          };
          "VFIO-RTX2080S".configuration = {
            system.nixos.tags = [ "RTX2080S-VFIO" ];
            custom.virtualisation.vfio = {
              blacklistNvidia = true;
              vfioDevices = RTX2080SuperPCIDevices;
            };
            custom.nvidia.enable = false;
          };
          "VFIO-RTX2080S_Raphael".configuration = {
            system.nixos.tags = [ "RTX2080S-VFIO" "Raphael-VFIO" ];
            custom.virtualisation.vfio = {
              blacklistNvidia = true;
              vfioDevices = RTX2080SuperPCIDevices ++ RaphaeliGPUPCIDevices;
            };
            custom.nvidia.enable = false;
          };
          "VFIO-RTX2080S_Navi".configuration = {
            system.nixos.tags = [ "RTX2080S-VFIO" "Navi-VFIO" ];
            custom.virtualisation.vfio = {
              blacklistNvidia = true;
              vfioDevices = RTX2080SuperPCIDevices ++ RaphaeliGPUPCIDevices;
            };
            custom.nvidia.enable = false;
          };
        };
    };
}

