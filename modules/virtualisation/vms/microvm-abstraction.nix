{ config, microvm, lib, ... }:
with lib;
let
  cfg = config.custom.virtualisation.microvm-abstraction;
in
{
  options.custom.virtualisation.microvm-abstraction = {
    enable = mkEnableOption "microvm.nix abstraction";

    isContainer = mkEnableOption "Container";
    containerName = mkOption {
      type = types.str;
      default = "";
      description = "The hostname of the container if isContainer is true.";
    };
    container = mkOption {
      type = containerOption;
      default = null;
    };

    hostName = mkOption {
      type = types.str;
      description = "The hostname of the host machine when inside a container.";
    };

    containers = mkOption {
      type = types.attrsOf containerOption;
      default = { };
      description = "Map of container names to their networking configurations.";
    };

    containerRuntime = mkOption {
      type = containerRuntimeOption;
    };
    containersRuntime = mkOption {
      type = types.attrsOf containerRuntimeOption;
      default = { };
    };
    secretsDir = mkOption {
      type = types.str;
    };
  };

}
