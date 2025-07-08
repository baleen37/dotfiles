#!/usr/bin/env bash
# Darwin-specific platform configuration

# Load configuration from external files
load_platform_configuration() {
  local config_loader="$(dirname "$0")/../../scripts/utils/config-loader.sh"

  if [[ -f "$config_loader" ]]; then
    source "$config_loader"
    load_path_config
    load_platform_config
  fi
}

# Load external configuration
load_platform_configuration

# Darwin-specific paths and settings (with external config support)
export SSH_DIR="${SSH_BASE_DIR:-/Users/${USER}/.ssh}"
export PLATFORM_TYPE="darwin"
export PLATFORM_NAME="$(get_config platform darwin_platform_name 2>/dev/null || echo 'Nix Darwin')"
export REBUILD_COMMAND="$(get_config platform darwin_rebuild_command 2>/dev/null || echo 'darwin-rebuild')"
export REBUILD_COMMAND_PATH="$(get_config platform darwin_rebuild_command_path 2>/dev/null || echo './result/sw/bin/darwin-rebuild')"
export NIXPKGS_ALLOW_UNFREE="${NIXPKGS_ALLOW_UNFREE:-1}"

# Darwin-specific USB mount detection
mount_usb() {
  MOUNT_PATH=""
  for dev in $(diskutil list | grep -o 'disk[0-9]'); do
    MOUNT_PATH="$(diskutil info /dev/${dev} | grep \"Mount Point\" | awk -F: '{print $2}' | xargs)"
    if [ -n "${MOUNT_PATH}" ]; then
      echo -e "${GREEN}USB drive found at ${MOUNT_PATH}.${NC}"
      break
    fi
  done

  if [ -z "${MOUNT_PATH}" ]; then
    handle_no_usb
  fi
}

# Darwin-specific ownership
change_ownership() {
  chown ${USER}:staff ${SSH_DIR}/id_ed25519{,.pub}
  chown ${USER}:staff ${SSH_DIR}/id_ed25519_{agenix,agenix.pub}
}

# Darwin-specific build configuration
get_build_config() {
  local arch=$1
  case "$arch" in
    aarch64)
      echo "aarch64-darwin"
      ;;
    x86_64)
      echo "x86_64-darwin"
      ;;
    *)
      echo -e "${RED}Unsupported architecture: $arch${NC}"
      return 1
      ;;
  esac
}

# Darwin-specific flake system
get_flake_system() {
  local system_type=$1
  echo "darwinConfigurations.${system_type}.system"
}
