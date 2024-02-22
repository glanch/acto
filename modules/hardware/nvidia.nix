{ config, lib, pkgs, ... }: {
  # Enable Intel iGPU early in the boot process


  environment.systemPackages =

    # Running `nvidia-offload vlc` would run VLC with dGPU

    let
      nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''

      export __NV_PRIME_RENDER_OFFLOAD=1

      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0

      export __GLX_VENDOR_LIBRARY_NAME=nvidia

      export __VK_LAYER_NV_optimus=NVIDIA_only


      exec "$@"

    '';

    in
    [ nvidia-offload ];


  hardware.nvidia = {

    # Drivers must be at verion 525 or newer

    package = config.boot.kernelPackages.nvidiaPackages.beta;

    prime = {

      offload.enable = true; # Enable PRIME offloading

      # TODO: find out how to fix these ids since they seem to change
      # amdgpuBusId = "PCI:16:0:0"; # lspci | grep VGA | grep Intel

      # nvidiaBusId = "PCI:16:0:0"; # lspci | grep VGA | grep NVIDIA

    };

  };

  home-manager.users.christopher = { lib, pkgs, ... }: {
    # TODO: check how to enable unfree packages here individually
    # Overwrite steam.desktop shortcut so that is uses PRIME

    # offloading for Steam and all its games
    # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    #   "steam"
    #   "steam-original"
    #   "steam-run"
    # ];
    # home.activation.steam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''

    #   $DRY_RUN_CMD sed 's/^Exec=/&nvidia-offload /' \

    #     ${pkgs.steam}/share/applications/steam.desktop \

    #     > ~/.local/share/applications/steam.desktop

    #   $DRY_RUN_CMD chmod +x ~/.local/share/applications/steam.desktop

    # '';

  };

  
  services.xserver.videoDrivers = [ "nvidia" ];

}

