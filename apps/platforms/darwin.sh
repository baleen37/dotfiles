#!/usr/bin/env bash
# Darwin-specific platform configuration

# Load configuration from external files
load_platform_configuration() {
  local config_loader
  config_loader="$(dirname "$0")/../../scripts/utils/config-loader.sh"

  if [[ -f $config_loader ]]; then
    # shellcheck source=/dev/null
    source "$config_loader"
    # Use unified config loader for better performance
    load_all_configs
  fi
}

# Load external configuration
load_platform_configuration

# Darwin-specific paths and settings (optimized with unified config)
SSH_DIR="$(get_unified_config ssh_dir_darwin "/Users/${USER}/.ssh")"
export SSH_DIR
export PLATFORM_TYPE="darwin"
PLATFORM_NAME="$(get_unified_config platform_name "Nix Darwin")"
export PLATFORM_NAME
REBUILD_COMMAND="$(get_unified_config rebuild_command "darwin-rebuild")"
export REBUILD_COMMAND
REBUILD_COMMAND_PATH="$(get_unified_config rebuild_command_path "./result/sw/bin/darwin-rebuild")"
export REBUILD_COMMAND_PATH
NIXPKGS_ALLOW_UNFREE="$(get_unified_config allow_unfree "${NIXPKGS_ALLOW_UNFREE:-1}")"
export NIXPKGS_ALLOW_UNFREE

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
