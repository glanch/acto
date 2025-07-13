# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, lib, pkgs, home-manager, agenix, disko, nur, nixpkgs-unstable, nixpkgs-moonlightlookingglassfix, musnix, ... }:

let
  sshPubKey = builtins.readFile ./identities/acto/christopher.pub;

  # VFIO Device Identifier
  RTX2080SuperPCIDevices = [ "10de:1e81" "10de:10f8" "10de:1ad8" "10de:1ad9" ];
  RX580PCIDevices = [ "1002:aaf0" "1002:67df" ];
  RaphaeliGPUPCIDevices = [ "1002:164e" ];
  RembrandtPCIDevices = [ "1002:1640" ];

  defaultVFIODevices = RTX2080SuperPCIDevices;

  # Overlay for adding .unstable to pkgs
  unstable-packages = final: _prev: {
    unstable = import nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  moonlightlookingglassfix-packages = final: _prev: {
    moonlightlookingglass = import nixpkgs-moonlightlookingglassfix {
      system = final.system;
      config.allowUnfree = true;
    };
  };

in
{
  imports =
    [
      home-manager.nixosModules.default
      agenix.nixosModules.default
      disko.nixosModules.default
      musnix.nixosModules.musnix
      ./hardware-configuration.nix
      ./modules/networking
      ./modules/shell.nix
      ./modules/hyprland.nix
      ./modules/media
      ./modules/gaming
      ./modules/communication
      ./modules/specializations.nix
      ./modules/nix-path.nix
      ./modules/vscodium.nix
      ./modules/nur.nix
      ./modules/firefox.nix
      ./modules/virtualisation
      ./modules/color.nix
      ./modules/hardware/nvidia.nix
    ];

  musnix.enable = true;
  musnix.rtcqs.enable = true;


  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings = {
    trusted-users = [ "christopher" ];
    extra-substituters = [
      "https://colmena.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Add overlay containing nixpkgs-unstable to add pkgs.unstable
  nixpkgs.overlays = [
    unstable-packages
    moonlightlookingglassfix-packages
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # binfmt for pi building
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  # Networking: see modules/networking/general.nix

  ## Time and Location

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  fonts.packages = with pkgs; [
    texlivePackages.cm
    cm_unicode
  ];
  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap = "de";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  # TODO: find out if these are necessary
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Enable hyprland setup
  custom.hyprland.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "de";
      variant = "";
    };
  };

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # See https://nixos.wiki/wiki/GNOME/Calendar
  programs.dconf.enable = true;
  services.gnome.evolution-data-server.enable = true;
  services.gnome.gnome-online-accounts.enable = true;
  services.gnome.gnome-keyring.enable = true;
  services.gvfs.enable = true;

  ## Media
  # Printing
  services.printing.enable = true;

  # Enable pipewire setup
  custom.media.pipewire.enable = true;

  # Enable spotify
  custom.media.spotify.enable = true;

  ## Communication
  custom.communication = {
    telegram.enable = true;
    signal.enable = true;
    teamspeak.enable = true;
    matrix.enable = true;
  };

  ## Development
  # Enable vscodium setup
  custom.vscodium.enable = true;


  # Enable custom firefox setup
  custom.firefox.enable = true;


  ## Gaming
  # Enable custom Minecraft setup
  custom.gaming.minecraft.enable = true;

  # Enable custom Minecraft setup
  custom.gaming.steam.enable = true;

  # Enable custom Retro Gaming
  custom.gaming.retrogaming.enable = true;

  ## Virtualisation
  # Enable vfio and virtualisation setup
  custom.virtualisation.vfio = lib.mkDefault {
    enable = true;
    blacklistNvidia = true;
    vfioDevices = defaultVFIODevices;
  };

  # Disable nvidia since for VFIO passthrough
  custom.nvidia.enable = lib.mkDefault false;

  # Enable both declarative VMs
  custom.virtualisation.vms.fancontrol-microvm.enable = lib.mkDefault true;
  custom.virtualisation.vms.localllm-microvm.enable = lib.mkDefault true;
  custom.virtualisation.vms.win10-libvirtd.enable = lib.mkDefault true;
  custom.virtualisation.vms.win11-libvirtd.enable = lib.mkDefault true;

  # Enable docker
  custom.virtualisation.docker.enable = true;

  users.mutableUsers = false;

  # XBox Controller
  hardware.xone.enable = true;
  hardware.xpadneo.enable = true;

  # Enable shell configuration
  custom.shell.enable = true;

  # My user account
  users.users.christopher = {
    isNormalUser = true;
    hashedPassword = "$6$fSedKlaWglw6hfXh$EU5D6BmYiEi7AD9qCJ.I.LpZ/Qjn.7KfezDWr007BPvvOTDYLtFLZVN2p7r8fQFnJ3c.9.AtMPfamFrRNIkUU/";

    openssh.authorizedKeys.keys = [
      sshPubKey
    ];
    extraGroups = [ "wheel" "lock" "dialout" "plugdev" "audio" "vboxusers" "libvirt" "adbusers" ];
    packages = with pkgs; [
      firefox
      vim
      mixxx
      clang-tools_15
      chromium
      direnv
      nixpkgs-fmt
      htop
      anki
      zotero
      languagetool
      evince
      joplin
      joplin-desktop
    ];
  };

  programs.java = {
    enable = true;
    #package = pkgs.jdk11;
  };

  programs.corectrl.enable = true;

  home-manager.users.christopher = { pkgs, ... }: {
    home = {
      stateVersion = "23.11";
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

    programs.bash.enable = false;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    nano
    docker-compose
    kdiskmark
    unigine-valley
    pciutils
    fend
    xdg-utils
  ];

  services.flatpak.enable = true;

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = false;
    config = {
      common.default = [ "gtk" ];
      Hyprland.default = [ "gtk" "hyprland" ];
    };
    wlr.enable = true;

    extraPortals = [
      #pkgs.xdg-desktop-portal-hyprland
    ];
  };

  systemd.user.extraConfig = ''
    DefaultEnvironment="PATH=/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
  '';

  #xdg.portal.config.common = {
  #  default = [ "gtk" ];
  #  "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
  #};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}


