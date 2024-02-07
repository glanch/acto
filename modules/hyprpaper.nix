{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.hyprpaper;
  hyprpaperConfiguration = pkgs.writeText "hyprpaper.conf" ''
  preload = ${cfg.wallpaperFile}
  ${lib.strings.concatLines (builtins.map (t: "wallpaper=${t},${cfg.wallpaperFile}") cfg.target)}
  '';
in
{
  options.custom.hyprpaper = {
    enable = mkEnableOption "Enable hyprpaper and apply usual config";
    target = mkOption {
      type = types.listOf types.str;
      default = ["eDP-1"];
    };

    wallpaperFile = mkOption {
      type = types.str;
    };
  };

  config = mkIf cfg.enable
    {
      # Install hyprpaper as system package.
      environment.systemPackages = [
        pkgs.hyprpaper
        (pkgs.writeShellScriptBin "hyprpaper-withconfig" "exec -a $0 hyprpaper --config ${hyprpaperConfiguration} $@")
      ];
    };
}

