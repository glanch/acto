{ lib, config, pkgs, nix-colors, ... }:
with lib;
let
  cfg = config.custom.color;
in
{
  options.custom.color = {
    enable = mkEnableOption "Enable custom shell";
  };

  config = mkIf cfg.enable
    {
      home-manager.users.christopher = { config,  ... }: {
        imports = [ nix-colors.homeManagerModules.default ];

        colorScheme = nix-colors.colorSchemes.dracula;
      };
    };
}

