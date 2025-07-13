{ config, lib, pkgs, nixpkgs-unstable, ... }: {
  # Enable
  programs.coolercontrol = {
    enable = true;
  };
}

