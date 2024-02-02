{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.communication.telegram;
in
{
  options.custom.communication.telegram = {
    enable = mkEnableOption "Enable telegram";
  };

  config = mkIf cfg.enable
    {
      users.users.christopher = {
        packages = with pkgs; [
          telegram-desktop
        ];
      };
    };
}

