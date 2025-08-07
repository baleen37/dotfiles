# Shared modules default import
#
# This file provides a default import for the shared modules directory.
# It's referenced by hosts/darwin/default.nix and other system configurations.
#
# The shared modules are imported via platform-specific home-manager configurations,
# not directly through this file.

{ config, pkgs, lib, ... }:

{
  # This module serves as a placeholder for the shared directory import.
  # The actual shared configurations are applied through:
  # - modules/shared/home-manager.nix (via Darwin/NixOS home-manager modules)
  # - modules/shared/packages.nix (via platform-specific package imports)
  # - modules/shared/files.nix (via platform-specific file imports)

  # No direct configuration is needed here, as all shared functionality
  # is handled through the platform-specific home-manager integrations.
}
