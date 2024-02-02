{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.communication.teamspeak;
in
{
  options.custom.communication.teamspeak = {
    enable = mkEnableOption "Enable teamspeak";
  };

  config = mkIf cfg.enable
    {
      users.users.christopher = {
        packages = with pkgs; [
          teamspeak_client
        ];
      };

      # TS3 is unfree, allow it
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "teamspeak_client"
      ];
    };
}

