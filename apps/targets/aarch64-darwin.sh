#!/usr/bin/env bash
# Target-specific configuration for aarch64-darwin

SYSTEM_TYPE="aarch64-darwin"
FLAKE_SYSTEM="darwinConfigurations.${SYSTEM_TYPE}.system"
ARCHITECTURE="aarch64"
PLATFORM="darwin"

# Load platform-specific configuration
source "$(dirname "$0")/../platforms/darwin.sh"

# Target-specific customizations (if any)
export TARGET_SPECIFIC_VAR="aarch64-darwin-specific"
