#!/usr/bin/env bash
# Darwin-specific build logic

# Common build functions will be sourced externally
# SCRIPT_DIR="$(dirname "$0")"
# source "${SCRIPT_DIR}/common.sh"

# Darwin-specific build preparation
prepare_darwin_build() {
  printf "${YELLOW}Preparing Darwin build environment...${NC}\n"

  # Darwin-specific environment setup
  export NIXPKGS_ALLOW_UNFREE=1

  # Call common preparation
  prepare_build_environment
}

# Darwin-specific build execution
execute_darwin_build() {
  local system_type=$1
  local build_args="${@:2}"

  local flake_system="darwinConfigurations.${system_type}.system"

  printf "${YELLOW}Starting Darwin build for ${system_type}...${NC}\n"
  nix --extra-experimental-features 'nix-command flakes' build --impure ".#${flake_system}" ${build_args}

  printf "${GREEN}Darwin build completed successfully!${NC}\n"
  printf "${YELLOW}To apply changes, run: nix run --impure .#build-switch${NC}\n"
  printf "${YELLOW}Or use the result link: ./result/sw/bin/darwin-rebuild switch --impure --flake .#${system_type}${NC}\n"
}

# Main Darwin build function
build_darwin() {
  local arch=$(detect_architecture)
  local system_type=""

  # Improve architecture detection
  case "$arch" in
    arm64|aarch64)
      system_type="$DARWIN_AARCH64_TARGET"
      ;;
    x86_64)
      system_type="$DARWIN_X86_64_TARGET"
      ;;
    "")
      # Fallback: detect from current directory if running from app dir
      local current_dir=$(basename "$(pwd)")
      if [[ "$current_dir" =~ darwin ]]; then
        system_type="$current_dir"
        printf "${YELLOW}Detected system type from directory: $system_type${NC}\n"
      else
        printf "${RED}Unable to detect architecture${NC}\n"
        return 1
      fi
      ;;
    *)
      printf "${RED}Unsupported architecture for Darwin: $arch${NC}\n"
      return 1
      ;;
  esac

  prepare_darwin_build
  execute_darwin_build "$system_type" "$@"
  cleanup_build
}
