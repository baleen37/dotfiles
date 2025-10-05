#!/bin/bash -e
# build-switch - Build and switch system configuration (Linux)
#
# Description:
#   For non-NixOS Linux (Ubuntu, etc.), this uses Home Manager for user configuration.
#   For NixOS, this uses nixos-rebuild for system configuration.

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
  echo "build-switch - Build and switch system configuration (Linux)"
  echo ""
  echo "Usage: nix run .#build-switch [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --help, -h    Show this help message"
  echo "  --verbose     Show detailed output"
  echo ""
  echo "For non-NixOS Linux (Ubuntu, etc.), this uses Home Manager for user configuration."
  echo "For NixOS, this uses nixos-rebuild for system configuration."
  echo ""
  exit 0
fi

# Environment setup
USER=${USER:-$(whoami)}

# Simple logging
log_info() {
  echo "ℹ️  $1"
}

# Check if we're on NixOS or regular Linux
if [ -f /etc/NIXOS ]; then
  # NixOS - use nixos-rebuild
  log_info "Detected NixOS system"
  log_info "Running: sudo nixos-rebuild switch --flake .#${SYSTEM_TYPE:-@SYSTEM@} --impure"
  exec sudo nixos-rebuild switch --flake ".#${SYSTEM_TYPE:-@SYSTEM@}" --impure "$@"
else
  # Regular Linux (Ubuntu, etc.) - use Home Manager
  log_info "Detected non-NixOS Linux system (Ubuntu, etc.)"
  log_info "Using Home Manager for user configuration"
  log_info "Running: nix run github:nix-community/home-manager/release-24.05 -- switch --flake .#${USER} --impure"
  exec nix run github:nix-community/home-manager/release-24.05 -- switch --flake ".#$USER" --impure "$@"
fi
