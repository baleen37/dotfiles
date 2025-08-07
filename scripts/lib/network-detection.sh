#!/bin/sh
# Network Detection Module for Build Scripts
# Provides network connectivity detection and offline mode handling

# Network connectivity check
check_network_connectivity() {
    log_debug "Checking network connectivity"

    # Multiple methods to detect network connectivity
    local connectivity_methods=(
        "check_dns_resolution"
        "check_http_connectivity"
        "check_nix_cache_connectivity"
    )

    local online_methods=0
    local total_methods=${#connectivity_methods[@]}

    for method in "${connectivity_methods[@]}"; do
        if eval "$method"; then
            online_methods=$((online_methods + 1))
        fi
    done

    # Consider online if majority of methods succeed
    if [ $online_methods -gt $((total_methods / 2)) ]; then
        log_debug "Network connectivity detected ($online_methods/$total_methods methods succeeded)"
        return 0
    else
        log_debug "Network connectivity limited or unavailable ($online_methods/$total_methods methods succeeded)"
        return 1
    fi
}

# DNS resolution check
check_dns_resolution() {
    if command -v nslookup >/dev/null 2>&1; then
        nslookup cache.nixos.org >/dev/null 2>&1
    elif command -v dig >/dev/null 2>&1; then
        dig +short cache.nixos.org >/dev/null 2>&1
    else
        # Fallback to getent if available
        getent hosts cache.nixos.org >/dev/null 2>&1
    fi
}

# HTTP connectivity check
check_http_connectivity() {
    if command -v curl >/dev/null 2>&1; then
        curl -s --connect-timeout 5 --max-time 10 https://cache.nixos.org >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=10 --tries=1 https://cache.nixos.org -O /dev/null 2>&1
    else
        # No HTTP client available, assume offline
        return 1
    fi
}

# Nix cache connectivity check
check_nix_cache_connectivity() {
    # Check if we can reach primary Nix caches
    local caches=("https://cache.nixos.org" "https://nix-community.cachix.org")

    for cache in "${caches[@]}"; do
        if command -v curl >/dev/null 2>&1; then
            if curl -s --connect-timeout 3 --max-time 5 "${cache}/nix-cache-info" >/dev/null 2>&1; then
                return 0
            fi
        fi
    done

    return 1
}

# Enable offline mode
enable_offline_mode() {
    log_info "Enabling offline mode due to network connectivity issues"

    export NIX_OFFLINE_MODE=1
    export NIX_CONFIG="
        substituters =
        require-sigs = false
        auto-optimise-store = true
        max-jobs = auto
    "

    log_debug "Offline mode environment configured"

    # Create offline mode indicator
    touch "${HOME}/.nix-build-offline-mode" 2>/dev/null || true
}

# Disable offline mode
disable_offline_mode() {
    log_info "Disabling offline mode - network connectivity restored"

    unset NIX_OFFLINE_MODE
    unset NIX_CONFIG

    log_debug "Online mode environment restored"

    # Remove offline mode indicator
    rm -f "${HOME}/.nix-build-offline-mode" 2>/dev/null || true
}

# Check if currently in offline mode
is_offline_mode() {
    [ -n "${NIX_OFFLINE_MODE:-}" ] || [ -f "${HOME}/.nix-build-offline-mode" ]
}

# Smart network mode detection and configuration
configure_network_mode() {
    log_debug "Configuring network mode based on connectivity"

    if check_network_connectivity; then
        if is_offline_mode; then
            disable_offline_mode
        fi
        log_info "Network mode: Online"
        return 0
    else
        if ! is_offline_mode; then
            enable_offline_mode
        fi
        log_warning "Network mode: Offline (limited functionality)"
        return 1
    fi
}

# Network retry with exponential backoff
retry_with_backoff() {
    local command="$1"
    local max_attempts="${2:-3}"
    local base_delay="${3:-2}"

    local attempt=1
    local delay=$base_delay

    while [ $attempt -le $max_attempts ]; do
        log_debug "Network retry attempt $attempt/$max_attempts"

        if eval "$command"; then
            log_debug "Network operation succeeded on attempt $attempt"
            return 0
        fi

        if [ $attempt -lt $max_attempts ]; then
            log_debug "Network operation failed, retrying in ${delay}s"
            sleep $delay
            delay=$((delay * 2))
        fi

        attempt=$((attempt + 1))
    done

    log_warning "Network operation failed after $max_attempts attempts"
    return 1
}

# Get offline mode message for user
get_offline_mode_message() {
    cat << 'EOF'
⚠️  Offline Mode Active

Build-switch is running in offline mode due to network connectivity issues.

Limitations:
• Binary cache downloads disabled
• Package updates unavailable
• Remote flake inputs won't update
• Only locally cached packages available

The system will automatically resume online mode when network connectivity is restored.

For troubleshooting network issues, check:
• Internet connection
• DNS resolution
• Firewall/proxy settings
• Nix cache accessibility
EOF
}
