#!/usr/bin/env bash
# Configuration Loader Utility
# Loads external configuration files and provides default values

# Colors for output
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Configuration directories
CONFIG_DIR="${CONFIG_DIR:-$(dirname "$0")/../../config}"
DEFAULT_CONFIG_DIR="${CONFIG_DIR}/defaults"

# Global configuration variables
declare -A BUILD_CONFIG
declare -A PLATFORM_CONFIG
declare -A PATH_CONFIG

# Configuration cache variables
CONFIG_CACHE_LOADED=false
CONFIG_CACHE_DIR="/tmp/dotfiles-config-cache"

# Load YAML configuration (simple key-value parsing)
load_yaml_config() {
  local config_file="$1"
  local config_array="$2"

  if [[ ! -f "$config_file" ]]; then
    printf "${YELLOW}Warning: Config file not found: $config_file${NC}\n"
    return 1
  fi

  # Simple YAML parsing for key: value pairs
  while IFS=': ' read -r key value; do
    # Skip comments and empty lines
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue

    # Remove leading/trailing whitespace and quotes
    key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//')

    if [[ -n "$key" && -n "$value" ]]; then
      eval "${config_array}[\"$key\"]=\"$value\""
    fi
  done < "$config_file"
}

# Load default configuration
load_default_config() {
  printf "${YELLOW}Loading default configuration...${NC}\n"

  # Default build settings
  BUILD_CONFIG["timeout"]="3600"
  BUILD_CONFIG["parallel_jobs"]="4"
  BUILD_CONFIG["experimental_features"]="nix-command flakes"
  BUILD_CONFIG["allow_unfree"]="true"

  # Default platform settings
  PLATFORM_CONFIG["darwin_system_prefix"]="darwinConfigurations"
  PLATFORM_CONFIG["linux_system_prefix"]="nixosConfigurations"
  PLATFORM_CONFIG["supported_architectures"]="aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux"

  # Default path settings
  PATH_CONFIG["ssh_dir_darwin"]="/Users/\${USER}/.ssh"
  PATH_CONFIG["ssh_dir_linux"]="/home/\${USER}/.ssh"
  PATH_CONFIG["config_dir"]="config"
  PATH_CONFIG["scripts_dir"]="scripts"

  printf "${GREEN}Default configuration loaded${NC}\n"
}

# Load build configuration
load_build_config() {
  local config_file="${CONFIG_DIR}/build-settings.yaml"

  printf "${YELLOW}Loading build configuration from $config_file...${NC}\n"

  if load_yaml_config "$config_file" "BUILD_CONFIG"; then
    printf "${GREEN}Build configuration loaded successfully${NC}\n"
  else
    printf "${YELLOW}Using default build configuration${NC}\n"
  fi

  # Export build environment variables
  export BUILD_TIMEOUT="${BUILD_CONFIG[timeout]}"
  export PARALLEL_JOBS="${BUILD_CONFIG[parallel_jobs]}"
  export NIX_EXPERIMENTAL_FEATURES="${BUILD_CONFIG[experimental_features]}"
  export NIXPKGS_ALLOW_UNFREE="${BUILD_CONFIG[allow_unfree]}"

  # Export architecture target variables to remove hardcoding
  export DARWIN_AARCH64_TARGET="aarch64-darwin"
  export DARWIN_X86_64_TARGET="x86_64-darwin"
  export LINUX_AARCH64_TARGET="aarch64-linux"
  export LINUX_X86_64_TARGET="x86_64-linux"
}

# Load platform configuration
load_platform_config() {
  local config_file="${CONFIG_DIR}/platforms.yaml"

  printf "${YELLOW}Loading platform configuration from $config_file...${NC}\n"

  if load_yaml_config "$config_file" "PLATFORM_CONFIG"; then
    printf "${GREEN}Platform configuration loaded successfully${NC}\n"
  else
    printf "${YELLOW}Using default platform configuration${NC}\n"
  fi
}

# Load path configuration
load_path_config() {
  local config_file="${CONFIG_DIR}/paths.yaml"

  printf "${YELLOW}Loading path configuration from $config_file...${NC}\n"

  if load_yaml_config "$config_file" "PATH_CONFIG"; then
    printf "${GREEN}Path configuration loaded successfully${NC}\n"
  else
    printf "${YELLOW}Using default path configuration${NC}\n"
  fi

  # Export common path variables
  export SSH_BASE_DIR="${PATH_CONFIG[ssh_dir_$(uname -s | tr '[:upper:]' '[:lower:]')]}"
}

# Get configuration value with fallback
get_config() {
  local config_type="$1"
  local key="$2"
  local default_value="$3"

  local config_array="${config_type}_CONFIG"
  local value

  case "$config_type" in
    "build")
      eval "value=\${BUILD_CONFIG[\"$key\"]}"
      ;;
    "platform")
      eval "value=\${PLATFORM_CONFIG[\"$key\"]}"
      ;;
    "path")
      eval "value=\${PATH_CONFIG[\"$key\"]}"
      ;;
    *)
      printf "${RED}Unknown config type: $config_type${NC}\n"
      return 1
      ;;
  esac

  echo "${value:-$default_value}"
}

# Load all configurations
load_all_configs() {
  printf "${YELLOW}Loading all configurations...${NC}\n"

  load_default_config
  load_build_config
  load_platform_config
  load_path_config

  # Mark as loaded
  CONFIG_CACHE_LOADED=true

  printf "${GREEN}All configurations loaded successfully${NC}\n"
}

# Check if configuration is already loaded (performance optimization)
is_config_loaded() {
  [[ "$CONFIG_CACHE_LOADED" == true ]]
}

# Unified configuration getter with intelligent defaults
get_unified_config() {
  local key="$1"
  local default_value="$2"

  # Ensure config is loaded
  if ! is_config_loaded; then
    load_all_configs >/dev/null 2>&1
  fi

  # Search across all config types
  local value=""

  # Try build config first
  value=$(get_config build "$key" "" 2>/dev/null)
  if [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  # Try platform config
  value=$(get_config platform "$key" "" 2>/dev/null)
  if [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  # Try path config
  value=$(get_config path "$key" "" 2>/dev/null)
  if [[ -n "$value" ]]; then
    echo "$value"
    return 0
  fi

  # Return default if not found
  echo "${default_value}"
}

# Main function for standalone execution
main() {
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_all_configs

    echo ""
    echo "Configuration Summary:"
    echo "- Build timeout: $(get_config build timeout)"
    echo "- Parallel jobs: $(get_config build parallel_jobs)"
    echo "- SSH base dir: $SSH_BASE_DIR"
    echo "- Supported architectures: $(get_config platform supported_architectures)"
  fi
}

# Run main function if script is executed directly
main "$@"
