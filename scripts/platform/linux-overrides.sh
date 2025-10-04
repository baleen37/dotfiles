#!/bin/sh
# Linux-specific overrides for common library functions
# This file provides platform-specific implementations that override common library defaults

# Linux may not require sudo for user-level builds
override_sudo_requirements() {
  # Override the default sudo requirement detection for Linux
  if [ "$PLATFORM_TYPE" = "linux" ]; then
    # Check if we're doing a system-level build
    if [ "${NIX_SYSTEM_BUILD:-false}" = "true" ]; then
      SUDO_REQUIRED=true
    else
      SUDO_REQUIRED=false
    fi
    export SUDO_REQUIRED

    if command -v log_info >/dev/null 2>&1; then
      log_info "Linux platform detected - sudo required: $SUDO_REQUIRED"
    fi
  fi
}

# Linux-specific sudo session management
override_sudo_session_config() {
  # Linux may have shorter default sudo timeouts
  if [ "$PLATFORM_TYPE" = "linux" ]; then
    SUDO_REFRESH_INTERVAL=${SUDO_REFRESH_INTERVAL:-240} # 4 minutes for Linux
    export SUDO_REFRESH_INTERVAL

    if command -v log_debug >/dev/null 2>&1; then
      log_debug "Linux sudo refresh interval set to ${SUDO_REFRESH_INTERVAL}s"
    fi
  fi
}

# Linux-specific build environment setup
override_build_environment() {
  # Set Linux-specific environment variables
  if [ "$PLATFORM_TYPE" = "linux" ]; then
    export LINUX_USER_BUILD=true
    export NIX_BUILD_CORES=${NIX_BUILD_CORES:-$(nproc)}

    # Linux-specific path configurations
    export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
    export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

    if command -v log_debug >/dev/null 2>&1; then
      log_debug "Linux build environment configured (cores: ${NIX_BUILD_CORES})"
    fi
  fi
}

# Apply all Linux overrides
apply_linux_overrides() {
  override_sudo_requirements
  override_sudo_session_config
  override_build_environment

  if command -v log_info >/dev/null 2>&1; then
    log_info "Linux platform overrides applied"
  fi
}
