{
  # nixpkgs
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;
  inputs.nixpkgs-unstable.url = github:NixOS/nixpkgs/nixos-unstable;

  # Hyprland
  inputs.hyprland = {
    url = "github:hyprwm/Hyprland";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Home Manager
  inputs.home-manager = {
    url = github:nix-community/home-manager/release-23.11;
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # VSCode extensions
  inputs.nix-vscode-extensions = {
    url = "github:nix-community/nix-vscode-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # NUR
  inputs.nur.url = github:nix-community/NUR;

  # Specialized NUR part as input for firefox addons
  inputs.firefox-addons = {
    url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # Virtualisation with VFIO
  inputs.nixos-vfio.url = "github:glanch/nixos-vfio";

  # Tools
  inputs.deploy-rs.url = "github:serokell/deploy-rs";
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.disko.url = "github:nix-community/disko";


  inputs.nix-colors.url = "github:misterio77/nix-colors";

  outputs = { self, nixpkgs, home-manager, deploy-rs, agenix, disko, hyprland, nix-vscode-extensions, nur, firefox-addons, nixos-vfio, nixpkgs-unstable, nix-colors, ... }@attrs: {
    nixosConfigurations."acto" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
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
    nixConfig = {
      extra-substituters = [
        "https://colmena.cachix.org"
        "https://hyprland.cachix.org"
      ];
      extra-trusted-public-keys = [
        "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}
