{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.networking.tailscale;
in
{
  options.custom.networking.tailscale = {
    enable = mkEnableOption "Enable imperatively configred Tailscale";
  };

  config = mkIf cfg.enable
    {
      # Enable Tailscale as client, imperatively configured
      services.tailscale.enable = true;
    };
}

