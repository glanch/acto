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
      # Enable zsh
      programs.zsh.enable = true;

      # Enable Oh-my-zsh
      programs.zsh.ohMyZsh = {
        enable = true;
        plugins = [ "git" "sudo" "docker" "kubectl" ];
      };

      # Set default shell of my user
      users.users.christopher.shell = pkgs.zsh;
      
      # Add zsh to /etc/shells
      environment.shells = with pkgs; [ zsh ];

    };
}

