# NixOS User Configuration
#
# NixOS-specific system configurations for the user.
# This file contains Linux/NixOS-specific system settings that complement
# the base home-manager configuration.
#
# Note: This is a NixOS module, not a home-manager module.
# Home-manager configurations (packages, sessionVariables) should go in home-manager.nix
#
{
  pkgs,
  lib,
  config,
  currentSystemUser,
  ...
}:

{
  # NixOS-specific system configurations
  # Add system-level configurations that are specific to NixOS here

  # Example NixOS-specific system settings (if needed):
  # environment.systemPackages = with pkgs; [
  #   # System-wide packages that should be available to all users
  # ];

  # User-specific NixOS configurations
  # These are configurations that affect the user at the system level
}
