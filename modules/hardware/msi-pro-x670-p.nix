{ config, lib, pkgs, ... }:

{
  boot.extraModulePackages = with config.boot.kernelPackages; [ nct6687d ];

  boot.kernelModules = [ "nct6687" ];
}
