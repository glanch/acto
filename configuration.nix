# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, home-manager, agenix, disko, ... }:

let
  sshPubKey = builtins.readFile ./id_rsa.pub;
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      home-manager.nixosModules.default
      agenix.nixosModules.default
      disko.nixosModules.default
      ./disk-config.nix
      ./modules/nextcloud-backup-sink.nix
      ./modules/zaphod-backup-sink.nix
      ./hardware-configuration.nix
      ./modules/hyprland.nix
      ./modules/pipewire.nix
    ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable hyprland setup
  custom.hyprland.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "de";
    xkbVariant = "";
  };

  # Configure console keymap
  console.keyMap = "de";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable pipewire setup
  custom.pipewire.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable virtual box
  virtualisation.virtualbox.host.enable = false;

  # Enable kvm
  virtualisation.libvirtd.enable = false;

  programs.dconf.enable = true;
  users.extraGroups.vboxusers.members = [ "christopher" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = false;
  users.users.christopher = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$sQh6gLkaqd1X4G5BeQ4jp/$5NtPCBB9BFS/RhzN7QllypRTwzOcgwLX1j/PqnXiSm6";
    description = "Christopher";
    extraGroups = [ "dialout" "lock" "uucp" "dialout" "plugdev" "networkmanager" "wheel" "audio" "vboxusers" "libvirtd" "adbusers" ];
    packages = with pkgs; [
      firefox
      vim
      mixxx
      minecraft
      prismlauncher
      #vscodium
      #git
      #nixfmt
      rnix-lsp
      clang-tools_15
      virt-manager
      freecad
      chromium
      mattermost-desktop
      direnv
      nixpkgs-fmt
    ];
    #shell = pkgs.zsh;
  };

  programs.git.enable = true;
  programs.git.package = pkgs.gitFull;
  programs.ausweisapp.enable = true;
  programs.ausweisapp.openFirewall = true;

  home-manager.users.christopher = { ... }: {
    imports = [ ];
    home = {
      stateVersion = "22.05";
      packages = [ ];
    };

    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      extensions =
        with pkgs.vscode-extensions; [
          #     matklad.rust-analyzer
          #    ms-python.python
          #ms-vscode.cpptools
          #llvm-vs-code-extensions.vscode-clangd
          #ms-vscode-remote.remote-ssh # won't work with vscodium
        ];
    };
    programs.bash.enable = false;
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  programs.adb.enable = false;


  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "remote-data-store"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}


