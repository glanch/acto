{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.custom.shell;
in
{
  options.custom.shell = {
    enable = mkEnableOption "Enable custom shell";
  };

  config = mkIf cfg.enable
    {
      # Enable fish
      /* programs.fish.enable = true;
      
      # Enable Oh-my-zsh
      programs.zsh.ohMyZsh = {
        enable = true;
        plugins = [ "git" "sudo" "docker" "kubectl" ];
      };

      # Set default shell of my user
      users.users.christopher.shell = pkgs.zsh;
      
      # Add zsh to /etc/shells
      environment.shells = with pkgs; [ zsh ];
 */

      # Enable nix-index
      programs.nix-index = {
        enable = true;
        enableBashIntegration = true;
      };
      programs.command-not-found.enable = false;
    };
}

