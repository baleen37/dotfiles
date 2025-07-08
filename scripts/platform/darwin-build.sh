#!/bin/sh
# Darwin-specific build optimizations and overrides

# Darwin-specific build environment setup
setup_darwin_build_environment() {
    # Set Darwin-specific build flags
    export NIXPKGS_ALLOW_UNFREE=1
    export NIX_BUILD_CORES=${NIX_BUILD_CORES:-$(sysctl -n hw.ncpu)}

    # Darwin-specific cache settings
    export NIX_REMOTE_SYSTEMS_FILE="${NIX_REMOTE_SYSTEMS_FILE:-/etc/nix/machines}"

    if command -v log_debug >/dev/null 2>&1; then
        log_debug "Darwin build environment configured"
        log_debug "Build cores: ${NIX_BUILD_CORES}"
    fi
}

# Darwin-specific build optimization flags
get_darwin_build_flags() {
    local base_flags="$1"

    # Add Darwin-specific optimizations
    local darwin_flags="--option sandbox false"

    # Enable eval cache on Darwin for faster rebuilds
    darwin_flags="$darwin_flags --option eval-cache true"

    # Darwin-specific substituters
    darwin_flags="$darwin_flags --option extra-substituters 'https://cache.nixos.org/ https://nix-community.cachix.org'"

    echo "$base_flags $darwin_flags"
}

# Darwin-specific post-build actions
darwin_post_build() {
    # Darwin-specific cleanup or notifications
    if command -v log_info >/dev/null 2>&1; then
        log_info "Darwin post-build actions completed"
    fi

    # Check for macOS system integration
    if command -v launchctl >/dev/null 2>&1; then
        # Reload any changed launchd services
        if [ -d "/etc/nix-darwin" ]; then
            if command -v log_debug >/dev/null 2>&1; then
                log_debug "nix-darwin integration detected"
            fi
        fi
    fi
}

# Apply all Darwin build overrides
apply_darwin_build_overrides() {
    setup_darwin_build_environment

    # Override build optimization flags function if it exists
    if declare -f get_build_optimization_flags >/dev/null 2>&1; then
        eval "original_get_build_optimization_flags() { $(declare -f get_build_optimization_flags | sed '1d'); }"
        get_build_optimization_flags() {
            local base_flags=$(original_get_build_optimization_flags "$@")
            get_darwin_build_flags "$base_flags"
        }
    fi

    if command -v log_info >/dev/null 2>&1; then
        log_info "Darwin build overrides applied"
    fi
}
