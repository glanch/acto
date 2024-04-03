{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.networking.netbird;
in
{
  options.custom.networking.netbird = {
    enable = mkEnableOption "Enable Netbird and tools";
  };

  config = mkIf cfg.enable
    {
      services.netbird.enable = true; # for netbird service & CLI
      environment.systemPackages = [ pkgs.netbird-ui ]; # for GUI
    };
}

