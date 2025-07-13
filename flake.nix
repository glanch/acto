{
  # nixpkgs
  nixConfig = {
    extra-substituters = [
      "https://colmena.cachix.org"
      "https://hyprland.cachix.org"
      "https://ai.cachix.org"
      "https://nix-community.cachix.org"
    ];
  };
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Fractional Scaling Fixes for Moonlight / Looking Glass Client
  inputs.nixpkgs-moonlightlookingglassfix.url = "github:glanch/nixpkgs/moonshine-looking-glass";

  # Hyprlandg
  inputs.hyprland = {
    url = "github:hyprwm/Hyprland";
    #inputs.nixpkgs.follows = "nixpkgs";
  };

  # Home Manager
  inputs.home-manager = {
    url = "github:nix-community/home-manager/release-25.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # VSCode extensions
  inputs.nix-vscode-extensions = {
    url = "github:nix-community/nix-vscode-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # NUR
  inputs.nur.url = "github:nix-community/NUR";

  # Specialized NUR part as input for firefox addons
  inputs.firefox-addons = {
    url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Virtualisation with VFIO
  inputs.nixos-vfio.url = "github:glanch/nixos-vfio/additional_device_xml";

  # microvm.nix
  # Fork containing option for disabling PCI device unbinding
  inputs.microvm.url = "github:glanch/microvm.nix/option_unbind_pci_devices";
  inputs.microvm.inputs.nixpkgs.follows = "nixpkgs";

  # Tools
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.disko.url = "github:nix-community/disko";


  inputs.nix-colors.url = "github:misterio77/nix-colors";

  # Music Production Enhancement
  inputs.musnix.url = "github:musnix/musnix";
  
  # Custom dmenu
  inputs.walker.url = "github:abenz1267/walker";

  outputs =
    { self, nixpkgs, home-manager, deploy-rs, agenix, disko, hyprland, nix-vscode-extensions, nur, firefox-addons, nixos-vfio, nixpkgs-unstable, microvm, nix-colors, musnix, walker, ... }@attrs:

    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations."acto" = nixpkgs.lib.nixosSystem {
        system = system;
        specialArgs = attrs;
        modules = [ ./configuration.nix ];
      };

      deploy.nodes.acto = {
        hostname = "acto.fritz.box";
        fastConnection = true;
        profiles = {
          system = {
            sshUser = "root";
            path =
              deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations."acto";
            user = "root";
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
