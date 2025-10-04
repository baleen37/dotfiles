#!/bin/sh
# Linux-specific build optimizations and overrides

# Linux-specific build environment setup
setup_linux_build_environment() {
  # Set Linux-specific build flags
  export NIX_BUILD_CORES=${NIX_BUILD_CORES:-$(nproc)}

  # Linux-specific paths
  export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
  export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

  # Linux-specific cache settings
  export NIX_REMOTE_SYSTEMS_FILE="${NIX_REMOTE_SYSTEMS_FILE:-/etc/nix/machines}"

  if command -v log_debug >/dev/null 2>&1; then
    log_debug "Linux build environment configured"
    log_debug "Build cores: ${NIX_BUILD_CORES}"
  fi
}

# Linux-specific build optimization flags
get_linux_build_flags() {
  local base_flags="$1"

  # Add Linux-specific optimizations
  local linux_flags="--option sandbox true"

  # Enable more aggressive caching on Linux
  linux_flags="$linux_flags --option eval-cache true"
  linux_flags="$linux_flags --option keep-outputs true"

  # Linux-specific substituters
  linux_flags="$linux_flags --option extra-substituters 'https://cache.nixos.org/ https://nix-community.cachix.org'"

  echo "$base_flags $linux_flags"
}

# Linux-specific post-build actions
linux_post_build() {
  # Linux-specific cleanup or notifications
  if command -v log_info >/dev/null 2>&1; then
    log_info "Linux post-build actions completed"
  fi

  # Check for systemd integration
  if command -v systemctl >/dev/null 2>&1; then
    # Reload any changed systemd services
    if [ -d "/etc/systemd/system" ]; then
      if command -v log_debug >/dev/null 2>&1; then
        log_debug "SystemD integration detected"
      fi
    fi
  fi
}

# Apply all Linux build overrides
apply_linux_build_overrides() {
  setup_linux_build_environment

  # Override build optimization flags function if it exists
  if declare -f get_build_optimization_flags >/dev/null 2>&1; then
    eval "original_get_build_optimization_flags() { $(declare -f get_build_optimization_flags | sed '1d'); }"
    get_build_optimization_flags() {
      local base_flags=$(original_get_build_optimization_flags "$@")
      get_linux_build_flags "$base_flags"
    }
  fi

  if command -v log_info >/dev/null 2>&1; then
    log_info "Linux build overrides applied"
  fi
}
