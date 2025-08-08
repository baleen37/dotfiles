#!/usr/bin/env bash
# Target-specific configuration for aarch64-darwin

export SYSTEM_TYPE="aarch64-darwin"
export FLAKE_SYSTEM="darwinConfigurations.${SYSTEM_TYPE}.system"
export ARCHITECTURE="aarch64"
export PLATFORM="darwin"

# Load platform-specific configuration
source "$(dirname "$0")/../platforms/darwin.sh"

# Target-specific customizations (if any)
export TARGET_SPECIFIC_VAR="aarch64-darwin-specific"
