{ inputs, nixpkgs, home-manager, ... }:
{
  nix.nixPath = [
    "nixpkgs=${nixpkgs}"
    "home-manager=${home-manager}"
  ];
}