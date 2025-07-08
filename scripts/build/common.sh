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
  local config_loader="${SCRIPT_DIR:-$(dirname "$0")}/../utils/config-loader.sh"

  if [[ -f "$config_loader" ]]; then
    source "$config_loader"
    load_build_config
    printf "${GREEN}External build configuration loaded${NC}\n"
  else
    printf "${YELLOW}Config loader not found, using defaults${NC}\n"
    # Default values
    export BUILD_TIMEOUT="3600"
    export PARALLEL_JOBS="4"
    export NIXPKGS_ALLOW_UNFREE="true"
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
