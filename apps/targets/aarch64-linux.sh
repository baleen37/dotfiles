#!/usr/bin/env bash
# Target-specific configuration for aarch64-linux

SYSTEM_TYPE="aarch64-linux"
FLAKE_SYSTEM="nixosConfigurations.${SYSTEM_TYPE}.config.system.build.toplevel"
ARCHITECTURE="aarch64"
PLATFORM="linux"

# Load platform-specific configuration
source "$(dirname "$0")/../platforms/linux.sh"

# Target-specific customizations (if any)
export TARGET_SPECIFIC_VAR="aarch64-linux-specific"
