#!/usr/bin/env bash
# Linux-specific platform configuration

# Linux-specific paths and settings
export SSH_DIR="/home/${USER}/.ssh"
export PLATFORM_TYPE="linux"
export PLATFORM_NAME="NixOS"
export REBUILD_COMMAND="nixos-rebuild"
export REBUILD_COMMAND_PATH="/run/current-system/sw/bin/nixos-rebuild"

# Linux-specific USB mount detection
mount_usb() {
  MOUNT_PATH=""
  # Look for mounted USB drives in common mount points
  for mount_point in /media /mnt /run/media/${USER}; do
    if [ -d "$mount_point" ]; then
      for usb_path in "$mount_point"/*; do
        if [ -d "$usb_path" ] && [ -r "$usb_path" ]; then
          echo -e "${GREEN}USB drive found at ${usb_path}.${NC}"
          MOUNT_PATH="$usb_path"
          break 2
        fi
      done
    fi
  done

  if [ -z "${MOUNT_PATH}" ]; then
    handle_no_usb
  fi
}

# Linux-specific ownership
change_ownership() {
  chown ${USER}:${USER} ${SSH_DIR}/id_ed25519{,.pub}
  chown ${USER}:${USER} ${SSH_DIR}/id_ed25519_{agenix,agenix.pub}
}

# Linux-specific build configuration
get_build_config() {
  local arch=$1
  case "$arch" in
  aarch64)
    echo "aarch64-linux"
    ;;
  x86_64)
    echo "x86_64-linux"
    ;;
  *)
    echo -e "${RED}Unsupported architecture: $arch${NC}"
    return 1
    ;;
  esac
}

# Linux-specific flake system
get_flake_system() {
  local system_type=$1
  echo "nixosConfigurations.${system_type}.config.system.build.toplevel"
}
