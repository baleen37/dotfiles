#!/bin/sh -e

# build-switch-common.sh - Modular Build & Switch Logic
# Simplified main script that orchestrates modular components

# Environment setup
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_MESSAGES=en_US.UTF-8

# Set USER if not already set (Darwin-specific)
if [ -z "$USER" ]; then
    export USER=$(whoami)
fi

# Parse arguments
VERBOSE=false
for arg in "$@"; do
    if [ "$arg" = "--verbose" ]; then
        VERBOSE=true
        break
    fi
done

# Get script directory for module loading
SCRIPT_DIR="$(dirname "$0")"
# Determine if we're being called from an app (contains PROJECT_ROOT) or directly
if [ -n "${PROJECT_ROOT:-}" ]; then
    LIB_DIR="$PROJECT_ROOT/scripts/lib"
else
    LIB_DIR="$SCRIPT_DIR/lib"
fi

# Load all modules
. "$LIB_DIR/logging.sh"
. "$LIB_DIR/performance.sh"
. "$LIB_DIR/progress.sh"
. "$LIB_DIR/optimization.sh"
. "$LIB_DIR/sudo-management.sh"
. "$LIB_DIR/cache-management.sh"
. "$LIB_DIR/build-logic.sh"

# Main build-switch logic loaded
# Platform-specific scripts will call execute_build_switch directly
