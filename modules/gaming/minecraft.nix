{ lib, config, pkgs, nix-vscode-extensions, ... }:
with lib;
let
  cfg = config.custom.gaming.minecraft;
in
{
  options.custom.gaming.minecraft = {
    enable = mkEnableOption "Enable Minecraft setup";
  };

  config = mkIf cfg.enable
    {
      users.users.christopher = {
        packages = with pkgs; [
          prismlauncher
        ];
      };
    };
}

