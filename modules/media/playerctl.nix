{ lib, config, pkgs, firefox-addons, ... }:
with lib;
let
  cfg = config.custom.media.playerctl;
in
{
  imports = [
    ./nur.nix
  ];

  options.custom.media.playerctl = {
    enable = mkEnableOption "Enable playerctl setup";
  };

  config = mkIf cfg.enable
    {
      # Enable playerctld and install playerctl
      home-manager.users.christopher = { ... }: {
        services.playerctld.enable = true;
      };

      users.users.christopher = {
        packages = with pkgs; [
          playerctl
        ];
      };
    };

}
    
