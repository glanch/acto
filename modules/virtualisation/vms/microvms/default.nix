{ microvm, ... }:
{
  imports = [ microvm.nixosModules.host ./fancontrol-microvm.nix ./localllm-microvm.nix ];
}