{ config, lib, pkgs, ... }:
{
  services.hardware.openrgb.enable = true;

  users.users.christopher = {
    packages = with pkgs; [
      openrgb
    ];
  };
}
