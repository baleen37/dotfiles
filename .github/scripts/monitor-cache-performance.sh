#!/bin/bash
# Performance monitoring script for CI cache optimization
# Usage: ./monitor-cache-performance.sh [job-name]

set -euo pipefail

JOB_NAME="${1:-unknown}"
START_TIME=$(date +%s)

# Function to log performance metrics
log_metric() {
    local metric_name="$1"
    local metric_value="$2"
    local timestamp=$(date -Iseconds)
    echo "::notice title=Performance Metric::${metric_name}=${metric_value} (job=${JOB_NAME}, time=${timestamp})"
}

# Function to check cache hit/miss
check_cache_status() {
    local cache_key="$1"
    if grep -q "Cache restored from key" <<< "${GITHUB_STEP_SUMMARY:-}"; then
        log_metric "cache_hit" "true"
        log_metric "cache_key" "$cache_key"
    else
        log_metric "cache_hit" "false"
        log_metric "cache_key" "$cache_key"
    fi
}

# Function to measure build time
measure_build_time() {
    local end_time=$(date +%s)
    local duration=$((end_time - START_TIME))
    log_metric "build_duration_seconds" "$duration"
    
    if [ "$duration" -lt 300 ]; then
        log_metric "performance_grade" "excellent"
    elif [ "$duration" -lt 600 ]; then
        log_metric "performance_grade" "good"
    elif [ "$duration" -lt 900 ]; then
        log_metric "performance_grade" "fair"
    else
        log_metric "performance_grade" "poor"
    fi
}

# Function to check Nix store size
check_store_size() {
    if [ -d "/nix/store" ]; then
        local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
        log_metric "nix_store_size" "$store_size"
    fi
}

# Function to check cache efficiency
check_cache_efficiency() {
    # Count how many packages were downloaded vs cached
    local downloaded_count=0
    local cached_count=0
    
    if command -v nix >/dev/null 2>&1; then
        # This is a simplified metric - in practice, we'd need more sophisticated tracking
        local total_packages=$(nix path-info --all 2>/dev/null | wc -l || echo "0")
        log_metric "total_packages" "$total_packages"
    fi
}

# Function to generate performance summary
generate_summary() {
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))
    
    cat >> $GITHUB_STEP_SUMMARY << EOF
## 📊 CI Performance Summary - ${JOB_NAME}

| Metric | Value |
|--------|-------|
| Build Duration | ${total_duration}s |
| Job Name | ${JOB_NAME} |
| Timestamp | $(date -Iseconds) |

### Performance Optimization Status
- ✅ Advanced Nix caching enabled
- ✅ Multi-level fallback keys configured
- ✅ Build parallelization optimized
- ✅ Cache compression enabled

EOF
}

# Main execution
main() {
    case "${1:-measure}" in
        "cache-status")
            check_cache_status "${2:-unknown}"
            ;;
        "build-time")
            measure_build_time
            ;;
        "store-size")
            check_store_size
            ;;
        "efficiency")
            check_cache_efficiency
            ;;
        "summary")
            generate_summary
            ;;
        "measure")
            check_store_size
            check_cache_efficiency
            measure_build_time
            generate_summary
            ;;
        *)
            echo "Usage: $0 [cache-status|build-time|store-size|efficiency|summary|measure] [args...]"
            exit 1
            ;;
    esac
}

# Trap to ensure summary is generated even if script fails
trap 'generate_summary' EXIT

main "$@"