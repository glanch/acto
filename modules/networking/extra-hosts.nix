{ config, lib, pkgs, ... }:

{
  # Extra hosts
  networking.extraHosts =
    let
      hostIpPairs = {
        "smarthub-ng.gnet" = "192.168.178.60";
      };
    in
    builtins.concatStringsSep "\n" (map (key: "${hostIpPairs.${key}} ${key}") (builtins.attrNames hostIpPairs));
}
