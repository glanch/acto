# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, home-manager, agenix, disko, nur, ... }:

let
  sshPubKey = builtins.readFile ./identities/acto/christopher.pub;
in
{
  imports =
    [
      home-manager.nixosModules.default
      agenix.nixosModules.default
      disko.nixosModules.default
      ./hardware-configuration.nix
      ./modules/hyprland.nix
      ./modules/media
      ./modules/gaming
      ./modules/communication
      ./modules/nix-path.nix
      ./modules/vscodium.nix
      ./modules/nur.nix
      ./modules/firefox.nix
      ./modules/virtualisation
      ./modules/color.nix
    ];

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  ## Networking

  # Set Hostname
  networking.hostName = "acto";

  # WiFi by NetworkManager
  networking.networkmanager.enable = true; 

  # Enable Tailscale as client, imperatively configured
  services.tailscale.enable = true;


  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;


  ## Time and Location

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

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
    layout = "de";
    xkbVariant = "";
  };

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  ## Media
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

  ## Virtualisation
  # Enable kvm
  # virtualisation.libvirtd.enable = false;
  # custom.vfio.enable = false;
  custom.virtualisation.docker.enable = true;

  users.mutableUsers = false;

  # Root user
  users.users.root.openssh.authorizedKeys.keys = [
    sshPubKey
  ];

  # My user account
  users.users.christopher = {
    isNormalUser = true;
    hashedPassword = "$6$fSedKlaWglw6hfXh$EU5D6BmYiEi7AD9qCJ.I.LpZ/Qjn.7KfezDWr007BPvvOTDYLtFLZVN2p7r8fQFnJ3c.9.AtMPfamFrRNIkUU/";

    openssh.authorizedKeys.keys = [
      sshPubKey
    ];
    extraGroups = [ "wheel" "lock" "dialout" "plugdev" "networkmanager" "audio" "vboxusers" "libvirtd" "adbusers" ];
    packages = with pkgs; [
      firefox
      vim
      mixxx
      rnix-lsp
      clang-tools_15
      virt-manager
      chromium
      direnv
      nixpkgs-fmt
      htop
    ];
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
  ];

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


