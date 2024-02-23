{ config, lib, pkgs, nixpkgs-coolercontrol, ... }: {
  imports = [
    "${nixpkgs-coolercontrol}/nixos/modules/programs/coolercontrol.nix"
  ];
  
  nixpkgs.overlays = [
    (final: prev: {
      # Inherit the changes into the overlay
      inherit (nixpkgs-coolercontrol.legacyPackages.${prev.system})
        coolercontrold coolercontrol coolercontrol-liqctld;
    })
  ];

  programs.coolercontrol = {
    enable = true;
  };
}

