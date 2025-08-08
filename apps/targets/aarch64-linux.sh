#!/usr/bin/env bash
# Target-specific configuration for aarch64-linux

export SYSTEM_TYPE="aarch64-linux"
export FLAKE_SYSTEM="nixosConfigurations.${SYSTEM_TYPE}.config.system.build.toplevel"
export ARCHITECTURE="aarch64"
export PLATFORM="linux"

# Load platform-specific configuration
source "$(dirname "$0")/../platforms/linux.sh"

# Target-specific customizations (if any)
export TARGET_SPECIFIC_VAR="aarch64-linux-specific"
