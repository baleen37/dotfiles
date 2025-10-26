# MacBook Hardware Configuration
#
# Hardware-specific settings for baleen's MacBook.
# This file contains only hardware and platform-specific configurations
# that don't belong in user configuration.
#
# Architecture: Mitchell-style
#   - Hardware identification: MacBook
#   - Platform: macOS (Darwin)
#   - User configuration: users/baleen/darwin.nix
#
# Hardware Settings:
#   - Platform detection and identification
#   - System-level defaults (hostname, etc.)
#   - Hardware-specific optimizations
#
# User configuration is handled separately in users/baleen/darwin.nix

{
  pkgs,
  lib,
  user,
  ...
}:

{
  # System identification
  networking.hostName = "baleen-macbook";
  networking.computerName = "baleen's MacBook";

  # System state version for nix-darwin
  system.stateVersion = 5;

  # Platform detection for scripts and applications
  environment.variables = {
    PLATFORM = "darwin";
    ARCHITECTURE = if pkgs.stdenv.isAarch64 then "arm64" else "x86_64";
  };

  # Hardware-specific system settings
  system = {
    # Primary user for system configuration
    primaryUser = user;

    # Platform-specific checks
    checks.verifyNixPath = false;
  };

  # Note: System defaults moved to users/baleen/darwin.nix for Mitchell-style
  # Hardware-specific defaults only (if any) should be here

  # System fonts (hardware provisioned)
  fonts.packages = with pkgs; [
    # Add system-wide fonts if needed
    # (font-nerd-fonts-symbols) # Example: Nerd Fonts symbols
  ];

  # Platform-specific services
  services = {
    # Enable hardware-specific services if needed
    # Example: T2 chip support for Intel Macs
  };

  # Security settings (system level)
  security.pam.services.sudo_local.touchIdAuth = lib.mkIf pkgs.stdenv.isAarch64 true;
}
