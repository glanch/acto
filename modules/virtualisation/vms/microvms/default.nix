{ microvm, ... }:
{
  imports = [ microvm.nixosModules.host ./fancontrol-microvm.nix ./localllm-microvm.nix ];
  networking.nat = {
    enable = true;
    internalIPs = [ "10.0.0.0/24" ];
    # Change this to the interface with upstream Internet access
    externalInterface = "enp7s0";
  };
}
