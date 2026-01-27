#!/bin/bash
# Platform configuration management
# Centralizes platform-specific settings and paths

# Get platform-specific settings
get_platform_config() {
    local platform="$1"
    local setting="$2"

    case "$platform" in
        "darwin")
            case "$setting" in
                "shell") echo "zsh" ;;
                "config_dir") echo "$HOME/.config" ;;
                "nix_path") echo "/nix/var/nix/profiles/default/bin/nix" ;;
                "profile_path") echo "/nix/var/nix/profiles/default" ;;
                "temp_dir") echo "$TMPDIR" ;;
                "cache_dir") echo "$HOME/Library/Caches" ;;
                *) echo "" ;;
            esac
            ;;
        "linux")
            case "$setting" in
                "shell") echo "bash" ;;
                "config_dir") echo "$HOME/.config" ;;
                "nix_path") echo "/nix/var/nix/profiles/default/bin/nix" ;;
                "profile_path") echo "/nix/var/nix/profiles/default" ;;
                "temp_dir") echo "/tmp" ;;
                "cache_dir") echo "$HOME/.cache" ;;
                *) echo "" ;;
            esac
            ;;
        *)
            echo ""
            ;;
    esac
}

# Detect current platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*) echo "darwin" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

# Get current platform config
get_current_config() {
    local setting="$1"
    local platform=$(detect_platform)
    get_platform_config "$platform" "$setting"
}

# Validate platform support
validate_platform() {
    local platform="$1"
    case "$platform" in
        "darwin"|"linux") return 0 ;;
        *)
            echo "Unsupported platform: $platform" >&2
            return 1
            ;;
    esac
}

# Platform-specific environment setup
setup_platform_env() {
    local platform="$1"

    if ! validate_platform "$platform"; then
        return 1
    fi

    # Set platform-specific environment variables
    export PLATFORM_SHELL=$(get_platform_config "$platform" "shell")
    export PLATFORM_CONFIG_DIR=$(get_platform_config "$platform" "config_dir")
    export PLATFORM_TEMP_DIR=$(get_platform_config "$platform" "temp_dir")
    export PLATFORM_CACHE_DIR=$(get_platform_config "$platform" "cache_dir")

    # Add Nix to PATH if available
    local nix_path=$(get_platform_config "$platform" "nix_path")
    if [ -x "$nix_path" ]; then
        export PATH="$nix_path:$PATH"
    fi

    return 0
}
