#!/bin/bash
# Cache optimization helper script
# Provides advanced caching strategies for GitHub Actions

set -euo pipefail

# Function to optimize Nix store before caching
optimize_nix_store() {
    echo "🔧 Optimizing Nix store for caching..."
    
    if command -v nix >/dev/null 2>&1; then
        # Optimize store to reduce cache size
        nix store optimise 2>/dev/null || true
        
        # Clean up unnecessary paths
        nix store gc --max 1d 2>/dev/null || true
        
        # Show store statistics
        if [ -d "/nix/store" ]; then
            local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
            local store_items=$(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l || echo "unknown")
            echo "📊 Nix store size: $store_size ($store_items items)"
        fi
    fi
}

# Function to prepare cache key with optimal strategy
generate_cache_key() {
    local key_prefix="$1"
    local system="$2"
    local files="$3"
    
    # Generate hash of relevant files
    local file_hash=$(find . -name "$files" -type f -exec sha256sum {} \; 2>/dev/null | sort | sha256sum | cut -d' ' -f1 || echo "none")
    
    # Include system info for better cache separation
    local arch=$(uname -m 2>/dev/null || echo "unknown")
    local os_version=$(uname -r 2>/dev/null | cut -d. -f1-2 || echo "unknown")
    
    echo "${key_prefix}-${system}-${os_version}-${arch}-${file_hash:0:16}"
}

# Function to check cache efficiency
check_cache_efficiency() {
    local cache_action="$1"
    
    # Look for cache hit indicators in the action output
    if [[ "$cache_action" == *"Cache restored from key"* ]]; then
        echo "✅ Cache HIT - excellent performance"
        echo "cache_status=hit" >> $GITHUB_OUTPUT
    elif [[ "$cache_action" == *"Cache not found"* ]]; then
        echo "❌ Cache MISS - will populate for next run"
        echo "cache_status=miss" >> $GITHUB_OUTPUT
    else
        echo "ℹ️ Cache status unknown"
        echo "cache_status=unknown" >> $GITHUB_OUTPUT
    fi
}

# Function to estimate cache savings
estimate_cache_savings() {
    local build_start="${PERF_START_TIME:-$(date +%s)}"
    local current_time=$(date +%s)
    local elapsed=$((current_time - build_start))
    
    # Estimate savings based on typical Nix build times
    if [ "$elapsed" -lt 120 ]; then
        echo "🚀 Excellent: Likely 70%+ cache hit rate (${elapsed}s elapsed)"
        echo "estimated_savings=70" >> $GITHUB_OUTPUT
    elif [ "$elapsed" -lt 300 ]; then
        echo "⚡ Good: Likely 40-70% cache hit rate (${elapsed}s elapsed)"
        echo "estimated_savings=55" >> $GITHUB_OUTPUT
    elif [ "$elapsed" -lt 600 ]; then
        echo "📈 Fair: Likely 20-40% cache hit rate (${elapsed}s elapsed)"
        echo "estimated_savings=30" >> $GITHUB_OUTPUT
    else
        echo "🐌 Poor: Likely <20% cache hit rate (${elapsed}s elapsed)"
        echo "estimated_savings=10" >> $GITHUB_OUTPUT
    fi
}

# Function to set up advanced Nix configuration
setup_advanced_nix_config() {
    echo "⚙️ Setting up advanced Nix configuration for CI..."
    
    # Create optimized nix.conf if it doesn't exist
    local nix_conf="/etc/nix/nix.conf"
    if [ -w "$(dirname "$nix_conf")" ] 2>/dev/null; then
        cat >> "$nix_conf" << 'EOF'
# CI-optimized settings
build-cores = 0
max-jobs = auto
keep-going = true
substitute = true
builders-use-substitutes = true
EOF
    fi
    
    # Set environment variables for this session
    export NIX_BUILD_CORES=0
    export NIX_MAX_JOBS=auto
    export NIX_REMOTE=daemon
}

# Main function
main() {
    case "${1:-optimize}" in
        "optimize")
            optimize_nix_store
            ;;
        "cache-key")
            generate_cache_key "$2" "$3" "$4"
            ;;
        "check-efficiency")
            check_cache_efficiency "$2"
            ;;
        "estimate-savings")
            estimate_cache_savings
            ;;
        "setup-nix")
            setup_advanced_nix_config
            ;;
        "all")
            setup_advanced_nix_config
            optimize_nix_store
            estimate_cache_savings
            ;;
        *)
            echo "Usage: $0 [optimize|cache-key|check-efficiency|estimate-savings|setup-nix|all]"
            exit 1
            ;;
    esac
}

main "$@"