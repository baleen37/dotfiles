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
# Convert to absolute path
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"

# Handle cases where this script is called from platform-specific scripts
if [ -d "$SCRIPT_DIR/lib" ]; then
    LIB_DIR="$SCRIPT_DIR/lib"
elif [ -d "$SCRIPT_DIR/../scripts/lib" ]; then
    LIB_DIR="$(cd "$SCRIPT_DIR/../scripts/lib" && pwd)"
elif [ -n "$PROJECT_ROOT" ] && [ -d "$PROJECT_ROOT/scripts/lib" ]; then
    LIB_DIR="$PROJECT_ROOT/scripts/lib"
else
    echo "ERROR: Cannot find lib directory"
    echo "SCRIPT_DIR: $SCRIPT_DIR"
    echo "PROJECT_ROOT: $PROJECT_ROOT"
    echo "Checked paths:"
    echo "  $SCRIPT_DIR/lib"
    echo "  $SCRIPT_DIR/../scripts/lib"
    echo "  $PROJECT_ROOT/scripts/lib"
    exit 1
fi

# Load all modules
. "$LIB_DIR/logging.sh"
. "$LIB_DIR/performance.sh"
. "$LIB_DIR/progress.sh"
. "$LIB_DIR/sudo-management.sh"
. "$LIB_DIR/build-logic.sh"

# Execute main build-switch logic
# This is the entry point that platform-specific scripts will call
execute_build_switch "$@"
