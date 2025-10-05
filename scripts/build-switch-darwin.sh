#!/bin/bash -e
# build-switch - Build and switch Darwin system configuration
#
# Description:
#   Builds and applies user-level configuration using Home Manager.
#   No root privileges required - safe for Claude Code execution.

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
  echo "build-switch - Build and switch Darwin system configuration"
  echo ""
  echo "Usage: nix run .#build-switch [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --help, -h    Show this help message"
  echo "  --verbose     Enable verbose logging"
  echo ""
  echo "Description:"
  echo "  Builds and applies user-level configuration using Home Manager."
  echo "  No root privileges required - safe for Claude Code execution."
  echo ""
  echo "Examples:"
  echo "  nix run .#build-switch"
  echo "  nix run .#build-switch -- --verbose"
  echo ""
  exit 0
fi

# Environment setup - minimize export usage
USER=${USER:-$(whoami)}

# Simple logging
log_info() {
  echo "ℹ️  $1"
}

# TDD: Minimal implementation for Green phase
log_info "Running user-level configuration (no root privileges required)"
log_info "Using Home Manager for all configurations"
log_info "Running: nix run github:nix-community/home-manager/release-24.05 -- switch --flake .#${USER} --impure"

# Home Manager 직접 실행 - 무한 루프 해결
USER=${USER:-$(whoami)}
log_info "Running Home Manager directly for user: $USER"

# Home Manager 직접 실행 (스크립트 재호출 없이)
exec nix run github:nix-community/home-manager/release-24.05 -- switch --flake ".#$USER" --impure "$@"
