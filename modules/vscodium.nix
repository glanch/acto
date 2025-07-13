{ lib, config, pkgs, nix-vscode-extensions, ... }:
with lib;
let
  cfg = config.custom.vscodium;
  all-extensions = nix-vscode-extensions.extensions.${pkgs.system};

in
{
  options.custom.vscodium = {
    enable = mkEnableOption "Enable VS Codium setup";
  };

  config = mkIf cfg.enable
    {
      home-manager.users.christopher = { ... }: {
        programs.vscode = {
          enable = true;
          package = pkgs.vscodium;
          profiles.default.extensions = with pkgs.vscode-extensions;

            let
              ltex-vsxi = pkgs.vscode-utils.buildVscodeMarketplaceExtension rec {
                version = "13.1.1";
                mktplcRef = {
                  inherit version;
                  name = "ltex";
                  publisher = "neo-ltex";
                };
                vsix = builtins.fetchurl {
                  url = "https://github.com/neo-ltex/vscode-ltex/releases/download/${version}/ltex-${version}-offline-linux-x64.vsix";
                  sha256 = "sha256:0wlcndwax4d68b29k2kmagv3vm01ill4dix9d8cljdnwfvzaapr8";
                };

                unpackPhase = ''
                  unzip ${vsix}
                '';
              };
            in
            [
              ltex-vsxi
              #all-extensions.vscode-marketplace.ms-vscode.cpptools
              all-extensions.open-vsx.ms-python.python
              all-extensions.open-vsx.twxs.cmake
              all-extensions.open-vsx.llvm-vs-code-extensions.vscode-clangd
              all-extensions.open-vsx.webfreak.debug

              all-extensions.vscode-marketplace.james-yu.latex-workshop
              all-extensions.open-vsx.stkb.rewrap

              all-extensions.open-vsx.jnoortheen.nix-ide

              all-extensions.open-vsx.redhat.vscode-xml
            ];
        };
      };

      users.users.christopher = {
        packages = with pkgs; [
          nil
        ];
      };
    };
}

