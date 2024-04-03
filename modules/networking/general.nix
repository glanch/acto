{ config, lib, pkgs, ... }:

{
  imports = [
    ./tailscale.nix
    ./netbird.nix
  ];

  ## Networking

  # Set Hostname
  networking.hostName = "acto";

  # WiFi by NetworkManager
  networking.networkmanager.enable = false;

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  users.users.christopher = {
    extraGroups = [ "networkmanager" ];
  };

  custom.networking.tailscale.enable = true;
  custom.networking.netbird.enable = true;
}
