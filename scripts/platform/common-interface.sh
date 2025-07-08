#!/bin/sh
# Common interface for platform-specific overrides
# This script loads the appropriate platform overrides and provides a unified interface

# Detect platform type
detect_platform_type() {
    case "$(uname -s)" in
        Darwin*) echo "darwin" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Load platform-specific overrides
load_platform_overrides() {
    local platform_type="${1:-$(detect_platform_type)}"
    local script_dir="$(dirname "$0")"

    export PLATFORM_TYPE="$platform_type"

    case "$platform_type" in
        darwin)
            if [ -f "$script_dir/darwin-overrides.sh" ]; then
                . "$script_dir/darwin-overrides.sh"
                apply_darwin_overrides
            else
                if command -v log_warning >/dev/null 2>&1; then
                    log_warning "Darwin overrides not found, using defaults"
                fi
            fi
            ;;
        linux)
            if [ -f "$script_dir/linux-overrides.sh" ]; then
                . "$script_dir/linux-overrides.sh"
                apply_linux_overrides
            else
                if command -v log_warning >/dev/null 2>&1; then
                    log_warning "Linux overrides not found, using defaults"
                fi
            fi
            ;;
        *)
            if command -v log_warning >/dev/null 2>&1; then
                log_warning "Unknown platform: $platform_type, using defaults"
            fi
            ;;
    esac

    if command -v log_info >/dev/null 2>&1; then
        log_info "Platform interface loaded for: $platform_type"
    fi
}

# Initialize platform-specific configurations
initialize_platform_interface() {
    # Determine script directory relative to caller
    local script_dir="$(dirname "$0")"
    local lib_dir

    # Try to find lib directory relative to platform directory
    if [ -d "$script_dir/../lib" ]; then
        lib_dir="$script_dir/../lib"
    elif [ -d "scripts/lib" ]; then
        lib_dir="scripts/lib"
    else
        if command -v log_error >/dev/null 2>&1; then
            log_error "Cannot locate lib directory"
        else
            echo "ERROR: Cannot locate lib directory" >&2
        fi
        return 1
    fi

    # Source core libraries in dependency order
    for lib_file in logging.sh platform-config.sh; do
        if [ -f "$lib_dir/$lib_file" ]; then
            . "$lib_dir/$lib_file"
        else
            echo "WARNING: $lib_file not found in $lib_dir" >&2
        fi
    done

    # Then load platform-specific overrides
    load_platform_overrides

    if command -v log_success >/dev/null 2>&1; then
        log_success "Platform interface initialized successfully"
    fi
}

# Main initialization function to be called by build scripts
init_platform() {
    initialize_platform_interface "$@"
}
