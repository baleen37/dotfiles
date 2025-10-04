#!/usr/bin/env bash
# Common SSH key management logic
# Shared between all platforms

# Colors for output
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Common SSH key checking functions
lint_keys() {
  if [[ -f "${SSH_DIR}/id_ed25519" && -f "${SSH_DIR}/id_ed25519.pub" && -f "${SSH_DIR}/id_ed25519_agenix" && -f "${SSH_DIR}/id_ed25519_agenix.pub" ]]; then
    echo -e "${GREEN}All required SSH keys are present.${NC}"
  else
    echo -e "${RED}Missing SSH keys. Please run create-keys first.${NC}"
    exit 1
  fi
}

# Common key permission setup
setup_ssh_directory() {
  mkdir -p ${SSH_DIR}
  chmod 700 ${SSH_DIR}
}

# Common key generation prompts
prompt_for_key_generation() {
  local key_name=$1
  if [[ -f "${SSH_DIR}/${key_name}" ]]; then
    echo -e "${YELLOW}Key ${key_name} already exists.${NC}"
    echo -n "Do you want to overwrite it? (y/n): "
    read -r response
    case "$response" in
    [yY][eE][sS] | [yY])
      return 0
      ;;
    *)
      return 1
      ;;
    esac
  else
    return 0
  fi
}

# Common key generation
generate_ssh_key() {
  local key_name=$1
  if prompt_for_key_generation "$key_name"; then
    ssh-keygen -t ed25519 -f "${SSH_DIR}/${key_name}" -N ""
    # Platform-specific ownership will be set by platform script
  else
    echo -e "${GREEN}Kept existing ${key_name}.${NC}"
  fi
}
