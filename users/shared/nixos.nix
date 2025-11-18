# NixOS System Configuration
#
# NixOS-specific system settings for all NixOS deployments (bare metal, VM, WSL).
# Mirrors the structure of darwin.nix for consistency.
#
# Features:
#   - User account configuration with zsh shell
#   - WSL-specific settings (conditional based on isWSL parameter)
#   - System-level zsh enablement
#   - Docker group membership
#
# Usage:
#   Import this file in NixOS configurations to apply shared user settings.
#   Set isWSL = true for WSL deployments, false for bare metal/VM.
#
# VERSION: 1.0.0
# LAST UPDATED: 2025-11-18

{
  pkgs,
  lib,
  config,
  currentSystemUser,
  isWSL ? false,
  ...
}:

{
  # WSL-specific configuration (only when isWSL = true)
  wsl = lib.mkIf isWSL {
    enable = true;
    defaultUser = currentSystemUser;
    startMenuLaunchers = true;
  };

  # User account configuration (all NixOS systems)
  users.users.${currentSystemUser} = {
    name = currentSystemUser;
    home = "/home/${currentSystemUser}";
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };
}
