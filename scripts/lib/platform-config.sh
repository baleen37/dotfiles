#!/bin/sh
# Platform Configuration Module for Apply Scripts
# Contains platform detection and configuration loading

# Detect current platform
detect_platform() {
  local os=$(uname)
  local arch=$(uname -m)

  # Convert architecture names to Nix format
  case "$arch" in
  "arm64") arch="aarch64" ;;
  "x86_64") arch="x86_64" ;;
  *)
    _print "${RED}Unsupported architecture: $arch${NC}"
    exit 1
    ;;
  esac

  # Convert OS names to Nix format
  case "$os" in
  "Darwin")
    export PLATFORM_TYPE="darwin"
    export PLATFORM_SYSTEM="$arch-darwin"
    ;;
  "Linux")
    export PLATFORM_TYPE="linux"
    export PLATFORM_SYSTEM="$arch-linux"
    ;;
  *)
    _print "${RED}Unsupported operating system: $os${NC}"
    exit 1
    ;;
  esac

  export ARCH="$arch"
  export OS="$os"

  _print "${GREEN}Detected platform: $PLATFORM_SYSTEM${NC}"
}

# Load platform-specific configuration
load_platform_config() {
  detect_platform

  local config_file="$(dirname "$0")/config.sh"

  if [ -f "$config_file" ]; then
    . "$config_file"
    _print "${GREEN}Loaded platform config: $config_file${NC}"
  else
    _print "${YELLOW}Warning: No platform config found at $config_file${NC}"
  fi
}

# Setup platform-specific environment
setup_platform_environment() {
  load_platform_config

  # Linux-specific setup
  if [ "$PLATFORM_TYPE" = "linux" ]; then
    # Primary network interface detection
    if command -v ip >/dev/null 2>&1; then
      export PRIMARY_IFACE=$(ip -o -4 route show to default | awk '{print $5}')
      _print "${GREEN}Found primary network interface: $PRIMARY_IFACE${NC}"
    fi
  fi
}
