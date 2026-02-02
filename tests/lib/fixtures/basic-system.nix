# Basic System Fixture
#
# Reusable basic NixOS VM configuration for E2E testing
#
# Provides:
# - Standard VM boot configuration
# - Basic networking setup
# - Nix with flakes enabled
# - Test user with sudo access
# - Common development packages
#
# Usage:
#   imports = [ ../lib/fixtures/basic-system.nix ]

{ pkgs, lib, ... }:
{
  # Standard VM config
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "test-vm";
  networking.useDHCP = false;
  networking.firewall.enable = false;

  virtualisation.cores = 2;
  virtualisation.memorySize = 2048;
  virtualisation.diskSize = 4096;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
      accept-flake-config = true
    '';
    settings = {
      substituters = [ "https://cache.nixos.org/" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };
  };

  users.users.testuser = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.bash;
  };

  # Common packages from fixtures
  environment.systemPackages = import ./common-packages.nix { inherit pkgs; }.e2eBasicPackages;

  security.sudo.wheelNeedsPassword = false;
}
