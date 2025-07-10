#!/usr/bin/env bash
# Common build logic shared across all platforms

# Colors for output
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Common build functions
detect_architecture() {
  uname -m
}

detect_platform() {
  case "$(uname -s)" in
    Darwin)
      echo "darwin"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      printf "${RED}Unsupported platform: $(uname -s)${NC}\n"
      return 1
      ;;
  esac
}

# Load build environment from external configuration
load_build_environment() {
  local script_dir="${SCRIPT_DIR:-$(dirname "$0")}"
  local config_loader="$script_dir/../utils/config-loader.sh"

  # Try multiple possible locations for config-loader.sh
  local possible_paths=(
    "$script_dir/../utils/config-loader.sh"
    "$script_dir/../../scripts/utils/config-loader.sh"
    "$(pwd)/scripts/utils/config-loader.sh"
  )

  local found_config_loader=""
  for path in "${possible_paths[@]}"; do
    if [[ -f "$path" ]]; then
      found_config_loader="$path"
      break
    fi
  done

  # Always set default values first
  export BUILD_TIMEOUT="3600"
  export PARALLEL_JOBS="4"
  export NIXPKGS_ALLOW_UNFREE="true"
  export DARWIN_AARCH64_TARGET="aarch64-darwin"
  export DARWIN_X86_64_TARGET="x86_64-darwin"
  export LINUX_AARCH64_TARGET="aarch64-linux"
  export LINUX_X86_64_TARGET="x86_64-linux"

  if [[ -n "$found_config_loader" ]]; then
    # Try to load external config (may override defaults)
    if source "$found_config_loader" 2>/dev/null && type load_build_config >/dev/null 2>&1; then
      load_build_config 2>/dev/null || true
      printf "${GREEN}External build configuration loaded from $found_config_loader${NC}\n"
    else
      printf "${YELLOW}Config loader found but failed to load, using defaults${NC}\n"
    fi
  else
    printf "${YELLOW}Config loader not found, using defaults${NC}\n"
  fi
}

# Common build preparation
prepare_build_environment() {
  printf "${YELLOW}Preparing build environment...${NC}\n"

  # Load external configuration
  load_build_environment

  # Set USER if not already set
  if [ -z "$USER" ]; then
    export USER=$(whoami)
  fi

  # Enable experimental features from config
  export NIX_CONFIG="experimental-features = ${NIX_EXPERIMENTAL_FEATURES:-nix-command flakes}"
}

# Common build execution
execute_build() {
  local flake_system=$1
  local build_args="${@:2}"

  printf "${YELLOW}Starting build for ${flake_system}...${NC}\n"
  nix --extra-experimental-features 'nix-command flakes' build ".#${flake_system}" ${build_args}
}

# Common build cleanup
cleanup_build() {
  printf "${YELLOW}Cleaning up...${NC}\n"
  if [ -L "./result" ]; then
    unlink ./result
  fi
}

# Main build orchestrator
run_build() {
  local target_config=$1
  shift
  local build_args="$@"

  # Source target configuration
  if [ -f "$target_config" ]; then
    source "$target_config"
  else
    printf "${RED}Target configuration not found: $target_config${NC}\n"
    return 1
  fi

  prepare_build_environment
  execute_build "$FLAKE_SYSTEM" $build_args
  cleanup_build

  printf "${GREEN}Build completed successfully!${NC}\n"
}
