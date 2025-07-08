#!/bin/sh
# Darwin-specific overrides for common library functions
# This file provides platform-specific implementations that override common library defaults

# Darwin always requires sudo for system activation
override_sudo_requirements() {
    # Override the default sudo requirement detection for Darwin
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        SUDO_REQUIRED=true
        export SUDO_REQUIRED

        if command -v log_info >/dev/null 2>&1; then
            log_info "Darwin platform detected - sudo required for system activation"
        fi
    fi
}

# Darwin-specific sudo session management
override_sudo_session_config() {
    # Darwin typically has longer sudo timeouts, optimize refresh interval
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        SUDO_REFRESH_INTERVAL=${SUDO_REFRESH_INTERVAL:-300}  # 5 minutes for Darwin
        export SUDO_REFRESH_INTERVAL

        if command -v log_debug >/dev/null 2>&1; then
            log_debug "Darwin sudo refresh interval set to ${SUDO_REFRESH_INTERVAL}s"
        fi
    fi
}

# Darwin-specific build environment setup
override_build_environment() {
    # Set Darwin-specific environment variables
    if [ "$PLATFORM_TYPE" = "darwin" ]; then
        export DARWIN_ACTIVATION_REQUIRED=true
        export NIX_BUILD_CORES=${NIX_BUILD_CORES:-$(sysctl -n hw.ncpu)}

        if command -v log_debug >/dev/null 2>&1; then
            log_debug "Darwin build environment configured (cores: ${NIX_BUILD_CORES})"
        fi
    fi
}

# Apply all Darwin overrides
apply_darwin_overrides() {
    override_sudo_requirements
    override_sudo_session_config
    override_build_environment

    if command -v log_info >/dev/null 2>&1; then
        log_info "Darwin platform overrides applied"
    fi
}
