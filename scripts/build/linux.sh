#!/usr/bin/env bash
# Linux-specific build logic

# Common build functions will be sourced externally
# SCRIPT_DIR="$(dirname "$0")"
# source "${SCRIPT_DIR}/common.sh"

# Linux-specific build preparation
prepare_linux_build() {
  echo -e "${YELLOW}Preparing Linux build environment...${NC}"

  # Call common preparation
  prepare_build_environment
}

# Linux-specific build execution
execute_linux_build() {
  local system_type=$1
  local build_args="${@:2}"

  local flake_system="nixosConfigurations.${system_type}.config.system.build.toplevel"

  echo -e "${YELLOW}Starting Linux build for ${system_type}...${NC}"
  nix --extra-experimental-features 'nix-command flakes' build ".#${flake_system}" ${build_args}

  echo -e "${GREEN}Linux build completed successfully!${NC}"
}

# Main Linux build function
build_linux() {
  local arch=$(detect_architecture)
  local system_type=""

  case "$arch" in
    aarch64)
      system_type="aarch64-linux"
      ;;
    x86_64)
      system_type="x86_64-linux"
      ;;
    *)
      echo -e "${RED}Unsupported architecture for Linux: $arch${NC}"
      return 1
      ;;
  esac

  prepare_linux_build
  execute_linux_build "$system_type" "$@"
  cleanup_build
}
