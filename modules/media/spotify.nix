{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.media.spotify;
in
{
  options.custom.media.spotify = {
    enable = mkEnableOption "Enable spotify";
  };

  config = mkIf cfg.enable
    {
      users.users.christopher = {
        packages = with pkgs; [
          spotify
        ];
      };

      # Local discovery
      networking.firewall.allowedTCPPorts = [ 57621 ];

      # Google Cast
      networking.firewall.allowedUDPPorts = [ 5353 ];

      # Spotify is unfree, allow it
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
        "spotify"
      ];
    };
}

