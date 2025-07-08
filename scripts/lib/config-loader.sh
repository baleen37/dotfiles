#!/bin/bash
# Configuration Loader Utility
# Loads and parses YAML configuration files

# Get the directory of the dotfiles project
get_dotfiles_root() {
    # Find the root by looking for flake.nix
    local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/flake.nix" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
    done

    # Fallback to relative path if not found
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
}

# Load configuration from YAML file
load_config() {
    local config_file="$1"
    local key_path="$2"
    local default_value="$3"

    local dotfiles_root="$(get_dotfiles_root)"
    local config_path="$dotfiles_root/config/$config_file"

    if [[ ! -f "$config_path" ]]; then
        echo "Warning: Configuration file $config_path not found" >&2
        echo "$default_value"
        return 1
    fi

    # Use yq if available, otherwise fall back to basic parsing
    if command -v yq >/dev/null 2>&1; then
        local value=$(yq eval "$key_path" "$config_path" 2>/dev/null)
        if [[ "$value" == "null" || -z "$value" ]]; then
            echo "$default_value"
        else
            echo "$value"
        fi
    else
        # Basic YAML parsing fallback
        echo "$default_value"
    fi
}

# Load cache configuration
load_cache_config() {
    local key="$1"
    local default="$2"

    case "$key" in
        "max_size_gb")
            load_config "cache.yaml" ".cache.local.max_size_gb" "$default"
            ;;
        "cleanup_days")
            load_config "cache.yaml" ".cache.local.cleanup_days" "$default"
            ;;
        "cache_dir")
            load_config "cache.yaml" ".cache.local.cache_dir" "$default"
            ;;
        "binary_caches")
            load_config "cache.yaml" ".cache.binary_caches[]" "$default"
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# Load network configuration
load_network_config() {
    local key="$1"
    local default="$2"

    case "$key" in
        "http_connections")
            load_config "network.yaml" ".network.http.connections" "$default"
            ;;
        "connect_timeout")
            load_config "network.yaml" ".network.http.connect_timeout" "$default"
            ;;
        "download_attempts")
            load_config "network.yaml" ".network.http.download_attempts" "$default"
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# Load platform configuration
load_platform_config() {
    local platform="$1"
    local key="$2"
    local default="$3"

    case "$key" in
        "rebuild_command")
            load_config "platforms.yaml" ".platforms.platform_configs.$platform.rebuild_command" "$default"
            ;;
        "platform_name")
            load_config "platforms.yaml" ".platforms.platform_configs.$platform.platform_name" "$default"
            ;;
        *)
            echo "$default"
            ;;
    esac
}

# Load security configuration
load_security_config() {
    local key="$1"
    local default="$2"

    case "$key" in
        "ssh_key_type")
            load_config "security.yaml" ".security.ssh.key_type" "$default"
            ;;
        "sudo_refresh_interval")
            load_config "security.yaml" ".security.sudo.refresh_interval" "$default"
            ;;
        *)
            echo "$default"
            ;;
    esac
}
