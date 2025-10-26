# VM Test Configuration
#
# Simplified NixOS configuration for VM testing.
# This configuration is optimized for QEMU VMs and avoids
# complex services like NetworkManager that may not work
# in virtualized environments.

{ config, pkgs, ... }:

{
  imports = [
    ../../machines/nixos-vm.nix
  ];

  # Override networking for VM compatibility
  networking.useDHCP = false;
  networking.useNetworkd = true;

  # Simple systemd-networkd configuration for VM
  systemd.networks."10-eth0" = {
    matchConfig.Name = "eth0";
    networkConfig.DHCP = "yes";
  };

  # Override NetworkManager (disable for VM)
  networking.networkmanager.enable = false;

  # Basic packages for testing
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    bash
    coreutils
  ];

  # Enable SSH for testing
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";

  # Add test user
  users.users.testuser = {
    isNormalUser = true;
    password = "test123";
    extraGroups = [ "wheel" ];
  };

  # Ensure shells are available
  programs.bash.enable = true;
  users.users.root.shell = pkgs.bashInteractive;
  users.users.testuser.shell = pkgs.bashInteractive;

  # VM-specific virtualization settings
  virtualisation.graphics = false;
  virtualisation.memorySize = 1024; # Minimal memory for test
  virtualisation.diskSize = 2048;  # Minimal disk for test
}