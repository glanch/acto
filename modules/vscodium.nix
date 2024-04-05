{ lib, config, pkgs, nix-vscode-extensions, ... }:
with lib;
let
  cfg = config.custom.vscodium;
in
{
  options.custom.vscodium = {
    enable = mkEnableOption "Enable VS Codium setup";
  };

  config = mkIf cfg.enable
    {
      home-manager.users.christopher = { ... }: {
        programs.vscode = {
          enable = true;
          package = pkgs.unstable.vscodium;
        };
      };
    
      users.users.christopher = {
        packages = with pkgs; [
          nil
        ];
      };

    };
}

