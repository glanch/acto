{ config, lib, pkgs, ... }:
{
  # Add kernel module
  boot.kernelModules = ["i2c_dev"];
  
  users.groups.ddc = { };

  # Add udev rule for enabling group ddc to access ddcutil getvcp
  services.udev.extraRules = ''KERNEL=="i2c-[0-9]*", GROUP="ddc", MODE="0660", PROGRAM="${pkgs.ddcutil}/bin/ddcutil --bus=%n getvcp 0x10"'';

  # Add group and (helper) programs to use ddcutil
  users.users.christopher = {
      # Add user to group for enabling brightness setting to user 
      extraGroups = [ "ddc" ];
      packages = with pkgs; [
        ddcutil ddcui gnomeExtensions.brightness-control-using-ddcutil 
      ];
  };

}