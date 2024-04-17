{ lib, config, pkgs, nix-vscode-extensions, ... }:
with lib;
let
  cfg = config.custom.gaming.retrogaming;
in
{
  options.custom.gaming.retrogaming = {
    enable = mkEnableOption "Enable Retro Gaming setup with Retroarch";
  };

  config = mkIf cfg.enable
    {
      users.users.christopher = {
        packages = with pkgs; [
          (retroarch.override {
            cores = with libretro; [
              dolphin
            ];
          })
          dolphin-emu
        ];
      };
    };
}




