{ config, lib, pkgs, nixpkgs-unstable, ... }: {
  # Currently, coolercontrol can only be found on unstable
  # TODO: fix this when merged in stable

  # Load module
  imports = [
    "${nixpkgs-unstable}/nixos/modules/programs/coolercontrol.nix"
  ];

  # Add coolercontrol packages from unstable
  nixpkgs.overlays = [
    (final: prev: {
      coolercontrol = nixpkgs-unstable.legacyPackages.${pkgs.system}.coolercontrol;
    })
  ];

  # Enable
  programs.coolercontrol = {
    enable = true;
  };
}

