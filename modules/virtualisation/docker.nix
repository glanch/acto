{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.virtualisation.docker;
in
{
  imports = [];
  options.custom.virtualisation.docker = {
    enable = mkEnableOption "Enable Docker";
  };

  config = mkIf cfg.enable
    {
      virtualisation.docker.enable = true;

    };
}

