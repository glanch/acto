{ lib, config, pkgs, nix-vscode-extensions, ... }:
with lib;
let
  cfg = config.custom.gaming.steam;
in
{
  options.custom.gaming.steam = {
    enable = mkEnableOption "Enable Steam setup";
  };

  config = mkIf cfg.enable
    {
      programs.steam = {
        package = pkgs.steam;
        enable = true;
        gamescopeSession.enable = true;
      };
      
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "steam"
        "steam-original"
        "steam-run"
      ];
    };


}

