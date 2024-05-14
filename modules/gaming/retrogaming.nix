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
      security.pam.loginLimits = [
        {
          domain = "christopher";
          item = "memlock";
          type = "hard";
          value = "2147483648"; # 2147483648
        }
        {
          domain = "christopher";
          item = "memlock";
          type = "soft";
          value = "2147483648"; # 2147483648
        }
      ];

      users.users.christopher = {
        packages = with pkgs; [
          (retroarch.override {
            cores = with libretro; [
              dolphin
            ];
          })
          dolphin-emu
          cemu
          rpcs3
          pcsx2
        ];
      };
    };
}




