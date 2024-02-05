{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.communication.matrix;
in
{
  options.custom.communication.matrix = {
    enable = mkEnableOption "Enable Matrix client";
  };

  config = mkIf cfg.enable
    {
      users.users.christopher = {
        packages = with pkgs; [
          element-desktop
        ];
      };
    };
}

