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
LIB_DIR="$SCRIPT_DIR/lib"

# Load all modules
. "$LIB_DIR/logging.sh"
. "$LIB_DIR/performance.sh"
. "$LIB_DIR/sudo-management.sh"
. "$LIB_DIR/build-logic.sh"

# Execute main build-switch logic
# This is the entry point that platform-specific scripts will call
execute_build_switch "$@"
