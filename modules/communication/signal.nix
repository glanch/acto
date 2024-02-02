{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.communication.signal;
in
{
  options.custom.communication.signal = {
    enable = mkEnableOption "Enable signal";
  };

  config = mkIf cfg.enable
    {
      users.users.christopher = {
        packages = with pkgs; [
          signal-desktop
        ];
      };
    };
}

