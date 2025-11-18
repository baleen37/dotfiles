# =============================================================================
# VM Shared Configuration Module
# =============================================================================
#
# This module provides the base configuration for NixOS virtual machines running
# in UTM on Apple Silicon. It contains common settings that apply across all
# VM instances regardless of specific hardware configuration.
#
# Purpose:
# - Establish base NixOS system configuration for development VMs
# - Provide common packages and services for development workflows
# - Configure virtualization-friendly defaults (no firewall, passwordless sudo)
# - Enable essential services (SSH, Docker) for development
#
# Design Philosophy:
# Simplified module signature with hardcoded values to reduce complexity for
# the current use case. The configuration assumes development VM usage with
# standard settings that work well across different UTM VM configurations.
#
# Usage:
# Imported by machine-specific configurations (e.g., vm-aarch64-utm.nix) which
# provide hardware-specific overrides and additional VM-specific settings.
#
# =============================================================================
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Be careful updating this.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  nix = {
    package = pkgs.nixVersions.latest;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # Use the systemd-boot EFI boot loader (can be overridden for WSL)
  boot.loader.systemd-boot.enable = lib.mkDefault true;
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;

  # VMware, Parallels both only support this being 0 otherwise you see
  # "error switching console mode" on boot.
  boot.loader.systemd-boot.consoleMode = "0";

  # Define your hostname.
  # Note: Can be overridden in machine-specific configuration
  networking.hostName = lib.mkDefault "dev";

  # Set your time zone.
  # Note: Hardcoded for West Coast development workflow. Could be parameterized
  # if needed for different geographical regions.
  time.timeZone = "Asia/Seoul";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Virtualization settings
  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.mutableUsers = true;

  # Set zsh as default shell
  programs.zsh.enable = true;

  # Fix root user home directory conflict
  users.users.root.home = lib.mkForce "/root";

  # Manage fonts.
  fonts = {
    fontDir.enable = true;

    packages = [
      pkgs.fira-code
      pkgs.cascadia-code
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    cachix
    gnumake
    killall
    xclip

    # For hypervisors that support auto-resizing, this script forces it.
    # I've noticed not everyone listens to the udev events so this is a hack.
    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')
  ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = true;
  services.openssh.settings.PermitRootLogin = "no";

  # Disable the firewall since we're in a VM and we want to make it
  # easy to visit stuff in here. We only use NAT networking anyways.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
