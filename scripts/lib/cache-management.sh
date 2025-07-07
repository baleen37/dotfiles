#!/bin/sh
# Cache Management Module for Build Scripts
# Provides intelligent build cache optimization and management

# Cache configuration constants
CACHE_MAX_SIZE_GB=5
CACHE_CLEANUP_DAYS=7
CACHE_STAT_FILE="$HOME/.cache/nix-build-stats"

# Binary cache URLs
BINARY_CACHES="https://cache.nixos.org https://nix-community.cachix.org"

# Cache statistics tracking
init_cache_stats() {
    if [ ! -f "$CACHE_STAT_FILE" ]; then
        echo "cache_hits=0" > "$CACHE_STAT_FILE"
        echo "cache_misses=0" >> "$CACHE_STAT_FILE"
        echo "total_builds=0" >> "$CACHE_STAT_FILE"
        echo "last_cleanup=$(date +%s)" >> "$CACHE_STAT_FILE"
    fi
}

# Update cache statistics
update_cache_stats() {
    local cache_hit="${1:-false}"

    if [ ! -f "$CACHE_STAT_FILE" ]; then
        init_cache_stats
    fi

    # Read current stats
    local current_hits=$(grep "cache_hits=" "$CACHE_STAT_FILE" | cut -d'=' -f2)
    local current_misses=$(grep "cache_misses=" "$CACHE_STAT_FILE" | cut -d'=' -f2)
    local current_total=$(grep "total_builds=" "$CACHE_STAT_FILE" | cut -d'=' -f2)
    local last_cleanup=$(grep "last_cleanup=" "$CACHE_STAT_FILE" | cut -d'=' -f2)

    # Update counters
    current_total=$((current_total + 1))

    if [ "$cache_hit" = "true" ]; then
        current_hits=$((current_hits + 1))
    else
        current_misses=$((current_misses + 1))
    fi

    # Write updated stats
    echo "cache_hits=$current_hits" > "$CACHE_STAT_FILE"
    echo "cache_misses=$current_misses" >> "$CACHE_STAT_FILE"
    echo "total_builds=$current_total" >> "$CACHE_STAT_FILE"
    echo "last_cleanup=$last_cleanup" >> "$CACHE_STAT_FILE"
}

# Display cache statistics
show_cache_stats() {
    if [ ! -f "$CACHE_STAT_FILE" ]; then
        log_info "No cache statistics available"
        return
    fi

    local hits=$(grep "cache_hits=" "$CACHE_STAT_FILE" | cut -d'=' -f2)
    local misses=$(grep "cache_misses=" "$CACHE_STAT_FILE" | cut -d'=' -f2)
    local total=$(grep "total_builds=" "$CACHE_STAT_FILE" | cut -d'=' -f2)

    if [ "$total" -gt 0 ]; then
        local hit_rate=$((hits * 100 / total))
        log_info "Cache Statistics:"
        log_info "  Total builds: $total"
        log_info "  Cache hits: $hits ($hit_rate%)"
        log_info "  Cache misses: $misses"
    fi
}

# Get cache size in MB
get_cache_size() {
    if [ -d "$HOME/.cache/nix" ]; then
        du -sm "$HOME/.cache/nix" 2>/dev/null | cut -f1 || echo "0"
    else
        echo "0"
    fi
}

# Check if cache cleanup is needed
needs_cache_cleanup() {
    local current_size=$(get_cache_size)
    local max_size_mb=$((CACHE_MAX_SIZE_GB * 1024))

    if [ "$current_size" -gt "$max_size_mb" ]; then
        return 0  # true
    fi

    # Check if cleanup is overdue (more than 7 days)
    if [ -f "$CACHE_STAT_FILE" ]; then
        local last_cleanup=$(grep "last_cleanup=" "$CACHE_STAT_FILE" | cut -d'=' -f2)
        local current_time=$(date +%s)
        local days_since_cleanup=$(((current_time - last_cleanup) / 86400))

        if [ "$days_since_cleanup" -gt "$CACHE_CLEANUP_DAYS" ]; then
            return 0  # true
        fi
    fi

    return 1  # false
}

# Perform intelligent cache cleanup
cleanup_cache() {
    local current_size=$(get_cache_size)
    local max_size_mb=$((CACHE_MAX_SIZE_GB * 1024))

    if [ "$current_size" -gt "$max_size_mb" ]; then
        log_info "Cache size ${current_size}MB exceeds ${max_size_mb}MB, cleaning..."

        # Use nix-collect-garbage with aggressive settings
        nix-collect-garbage --delete-older-than "${CACHE_CLEANUP_DAYS}d" >/dev/null 2>&1

        # Update last cleanup time
        local current_time=$(date +%s)
        if [ -f "$CACHE_STAT_FILE" ]; then
            sed -i.bak "s/last_cleanup=.*/last_cleanup=$current_time/" "$CACHE_STAT_FILE"
            rm -f "$CACHE_STAT_FILE.bak"
        fi

        local new_size=$(get_cache_size)
        local saved_mb=$((current_size - new_size))
        log_info "Cache cleanup completed. Freed ${saved_mb}MB"
    fi
}

# Warm cache for common dependencies
warm_cache_for_system() {
    local system_type="$1"
    log_info "Warming cache for common dependencies..."

    # Common dependencies that are frequently used
    local common_deps=""
    case "$system_type" in
        *darwin*)
            common_deps="nixpkgs#git nixpkgs#curl nixpkgs#openssh nixpkgs#gnupg"
            ;;
        *linux*)
            common_deps="nixpkgs#git nixpkgs#curl nixpkgs#openssh nixpkgs#gnupg nixpkgs#gcc"
            ;;
        *)
            common_deps="nixpkgs#git nixpkgs#curl"
            ;;
    esac

    # Warm cache in parallel for faster execution
    local pids=""
    for dep in $common_deps; do
        if [ "$VERBOSE" = "true" ]; then
            log_info "Warming cache for $dep"
        fi
        (nix build --no-link "$dep" >/dev/null 2>&1) &
        pids="$pids $!"
    done

    # Wait for all warming processes to complete
    for pid in $pids; do
        wait "$pid"
    done

    log_info "Cache warming completed"
}

# Configure optimal cache settings
configure_cache_settings() {
    log_info "Configuring optimal cache settings..."

    # Set binary caches if not already configured
    local current_caches
    current_caches=$(nix show-config | grep "binary-caches" | cut -d'=' -f2 | tr -d ' ')

    # Check if our optimized caches are already configured
    local needs_config=false
    for cache in $BINARY_CACHES; do
        if ! echo "$current_caches" | grep -q "$cache"; then
            needs_config=true
            break
        fi
    done

    if [ "$needs_config" = "true" ]; then
        if [ "$VERBOSE" = "true" ]; then
            log_info "Adding binary caches: $BINARY_CACHES"
        fi

        # Note: We'll add cache settings as command-line options instead of
        # modifying system configuration to avoid permission issues
        export NIX_CACHE_OPTIONS="--option binary-caches '$BINARY_CACHES'"
    fi
}

# Get optimized nix command with cache settings
get_optimized_nix_command() {
    local base_command="$1"
    local cache_options=""

    if [ -n "$NIX_CACHE_OPTIONS" ]; then
        cache_options="$NIX_CACHE_OPTIONS"
    fi

    echo "$base_command $cache_options"
}

# Check if build will likely be a cache hit
predict_cache_hit() {
    local flake_system="$1"

    # Simple heuristic: if we can evaluate without building, it's likely cached
    if nix eval --impure ".#$flake_system" >/dev/null 2>&1; then
        return 0  # likely cache hit
    else
        return 1  # likely cache miss
    fi
}

# Main cache optimization function
optimize_cache() {
    local system_type="$1"

    log_info "Optimizing build cache..."

    # Initialize cache statistics
    init_cache_stats

    # Configure cache settings
    configure_cache_settings

    # Warm cache for common dependencies (background process)
    if [ "$VERBOSE" = "true" ]; then
        warm_cache_for_system "$system_type"
    else
        (warm_cache_for_system "$system_type") &
    fi

    # Cleanup cache if needed
    if needs_cache_cleanup; then
        cleanup_cache
    fi

    # Show current cache statistics
    if [ "$VERBOSE" = "true" ]; then
        show_cache_stats
        local current_size=$(get_cache_size)
        log_info "Current cache size: ${current_size}MB"
    fi
}

# Post-build cache statistics update
update_post_build_stats() {
    local build_success="$1"
    local start_time="$2"
    local end_time="$3"

    if [ "$build_success" = "true" ]; then
        local duration=$((end_time - start_time))

        # Heuristic: if build was very fast (< 30 seconds), likely cache hit
        if [ "$duration" -lt 30 ]; then
            update_cache_stats "true"
        else
            update_cache_stats "false"
        fi
    fi
}
