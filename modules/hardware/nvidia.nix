{ config, lib, pkgs, ... }: with lib; {
  # Enable Intel iGPU early in the boot process
  options.custom.nvidia = {
    enable = mkEnableOption "Enable NVidia";
    offloading = mkEnableOption "Enable Offloading";

  };

  config = mkIf config.custom.nvidia.enable {
    # Enable OpenGL
    hardware.graphics = {
      enable = true;
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [ "nvidia" ]; # or "nvidiaLegacy470 etc.

    hardware.nvidia = {

      # Modesetting is required.
      modesetting.enable = true;

      # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
      # Enable this if you have graphical corruption issues or application crashes after waking
      # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
      # of just the bare essentials.
      powerManagement.enable = false;

      # Fine-grained power management. Turns off GPU when not in use.
      # Experimental and only works on modern Nvidia GPUs (Turing or newer).
      powerManagement.finegrained = false;

      # Use the NVidia open source kernel module (not to be confused with the
      # independent third-party "nouveau" open source driver).
      # Support is limited to the Turing and later architectures. Full list of 
      # supported GPUs is at: 
      # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
      # Only available from driver 515.43.04+
      # Currently alpha-quality/buggy, so false is currently the recommended setting.
      open = false;

      # Enable the Nvidia settings menu,
      # accessible via `nvidia-settings`.
      nvidiaSettings = true;

      # Optionally, you may need to select the appropriate driver version for your specific GPU.
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
  # {
  #   environment.systemPackages =
  #     let
  #       nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''

  #   export __NV_PRIME_RENDER_OFFLOAD=1

  #   export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0

  #   export __GLX_VENDOR_LIBRARY_NAME=nvidia

  #   export __VK_LAYER_NV_optimus=NVIDIA_only


  #   exec "$@"

  # '';

  #     in
  #     mkIf config.custom.nvidia.offloading [ nvidia-offload ];


  #   hardware.nvidia = {

  #     # Drivers must be at verion 525 or newer

  #     package = config.boot.kernelPackages.nvidiaPackages.beta;

  #     prime = {

  #       offload.enable = config.custom.nvidia.offloading; # Enable PRIME offloading

  #       # TODO: find out how to fix these ids since they seem to change
  #       # amdgpuBusId = "PCI:16:0:0"; # lspci | grep VGA | grep Intel

  #       # nvidiaBusId = "PCI:16:0:0"; # lspci | grep VGA | grep NVIDIA

  #     };

  #   };

  #   home-manager.users.christopher = { lib, pkgs, ... }: {
  #     # TODO: check how to enable unfree packages here individually
  #     # Overwrite steam.desktop shortcut so that is uses PRIME

  #     # offloading for Steam and all its games
  #     # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #     #   "steam"
  #     #   "steam-original"
  #     #   "steam-run"
  #     # ];
  #     # home.activation.steam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''

  #     #   $DRY_RUN_CMD sed 's/^Exec=/&nvidia-offload /' \

  #     #     ${pkgs.steam}/share/applications/steam.desktop \

  #     #     > ~/.local/share/applications/steam.desktop

  #     #   $DRY_RUN_CMD chmod +x ~/.local/share/applications/steam.desktop

  #     # '';

  #   };
  #   services.xserver.videoDrivers = [ "nvidia" ];
  # };
}

