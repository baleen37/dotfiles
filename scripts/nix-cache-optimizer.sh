#!/usr/bin/env bash
# Nix Store Cache Optimization Script
# Optimizes Nix store cache usage and implements intelligent cache strategies

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly CACHE_REPORT_DIR="$PROJECT_ROOT/.cache-reports"
readonly TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Create cache report directory
mkdir -p "$CACHE_REPORT_DIR"

# Analyze current Nix store state
analyze_store_state() {
  echo "=== NIX STORE ANALYSIS ==="

  local report_file="$CACHE_REPORT_DIR/store_analysis_${TIMESTAMP}.json"

  # Get store statistics
  local store_size=$(du -sb /nix/store 2>/dev/null | cut -f1 || echo "0")
  local store_size_gb=$(echo "scale=2; $store_size / 1024 / 1024 / 1024" | bc -l)
  local store_paths=$(find /nix/store -maxdepth 1 -type d | wc -l)
  local gc_roots=$(nix-store --gc --print-roots 2>/dev/null | wc -l || echo "0")

  # Check for dead paths
  local dead_paths=$(nix-store --gc --print-dead 2>/dev/null | wc -l || echo "0")
  local live_paths=$(nix-store --gc --print-live 2>/dev/null | wc -l || echo "0")

  # Generate report
  cat >"$report_file" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "store_statistics": {
    "total_size_bytes": $store_size,
    "total_size_gb": $store_size_gb,
    "total_paths": $store_paths,
    "gc_roots": $gc_roots,
    "dead_paths": $dead_paths,
    "live_paths": $live_paths
  },
  "efficiency_metrics": {
    "dead_path_ratio": $(echo "scale=2; $dead_paths * 100 / ($live_paths + $dead_paths + 0.001)" | bc -l),
    "average_path_size_mb": $(echo "scale=2; $store_size / $store_paths / 1024 / 1024" | bc -l)
  }
}
EOF

  echo "Store Size: ${store_size_gb} GB"
  echo "Total Paths: $store_paths"
  echo "GC Roots: $gc_roots"
  echo "Dead Paths: $dead_paths"
  echo "Live Paths: $live_paths"
  echo ""
  echo "Report saved to: $report_file"
}

# Optimize store by removing unused paths
optimize_store() {
  echo "=== STORE OPTIMIZATION ==="

  local pre_gc_size=$(du -sb /nix/store 2>/dev/null | cut -f1 || echo "0")
  local pre_gc_paths=$(find /nix/store -maxdepth 1 -type d | wc -l)

  echo "Pre-optimization:"
  echo "  Store size: $(echo "scale=2; $pre_gc_size / 1024 / 1024 / 1024" | bc -l) GB"
  echo "  Store paths: $pre_gc_paths"

  # Run garbage collection
  echo "Running garbage collection..."
  nix-store --gc --print-dead | head -10

  if [[ ${1:-""} == "--delete" ]]; then
    echo "Deleting dead paths..."
    nix-store --gc

    # Optimize store (deduplicate identical files)
    echo "Optimizing store (deduplicating)..."
    nix-store --optimize
  else
    echo "Dry run mode. Use --delete to actually remove dead paths."
  fi

  local post_gc_size=$(du -sb /nix/store 2>/dev/null | cut -f1 || echo "0")
  local post_gc_paths=$(find /nix/store -maxdepth 1 -type d | wc -l)
  local saved_bytes=$((pre_gc_size - post_gc_size))
  local saved_gb=$(echo "scale=2; $saved_bytes / 1024 / 1024 / 1024" | bc -l)

  echo ""
  echo "Post-optimization:"
  echo "  Store size: $(echo "scale=2; $post_gc_size / 1024 / 1024 / 1024" | bc -l) GB"
  echo "  Store paths: $post_gc_paths"
  echo "  Space saved: ${saved_gb} GB"
  echo "  Paths removed: $((pre_gc_paths - post_gc_paths))"
}

# Analyze cache hit rates for recent builds
analyze_cache_performance() {
  echo "=== CACHE PERFORMANCE ANALYSIS ==="

  if [[ ! -d "$PROJECT_ROOT/.perf-logs" ]]; then
    echo "No performance logs found. Run some builds first."
    return 0
  fi

  echo "Cache hit analysis from recent builds:"
  echo "Date         | Target                    | Cache Hit % | Build Time"
  echo "-------------|---------------------------|-------------|------------"

  for json_file in "$PROJECT_ROOT/.perf-logs"/*.json; do
    if [[ -f $json_file ]]; then
      local target=$(jq -r '.target' "$json_file" 2>/dev/null || echo "unknown")
      local cache_ratio=$(jq -r '.cache_statistics.cache_hit_ratio' "$json_file" 2>/dev/null || echo "0")
      local duration=$(jq -r '.build_result.duration_human' "$json_file" 2>/dev/null || echo "unknown")
      local timestamp=$(jq -r '.timestamp' "$json_file" 2>/dev/null | sed 's/_/ /')

      # Convert cache ratio to percentage
      local cache_percent=$(echo "scale=1; $cache_ratio * 100" | bc -l 2>/dev/null || echo "0")

      printf "%-12s | %-25s | %8s%% | %s\n" \
        "$(echo $timestamp | cut -d' ' -f1)" \
        "$(basename "$target" | cut -c1-25)" \
        "$cache_percent" \
        "$duration"
    fi
  done | sort -r | head -10
}

# Setup intelligent caching configuration
setup_intelligent_caching() {
  echo "=== INTELLIGENT CACHING SETUP ==="

  local nix_conf_dir="$HOME/.config/nix"
  local nix_conf="$nix_conf_dir/nix.conf"

  # Create backup of existing config
  if [[ -f $nix_conf ]]; then
    cp "$nix_conf" "$nix_conf.backup.$(date +%s)"
    echo "Backed up existing nix.conf"
  fi

  # Create optimized configuration
  mkdir -p "$nix_conf_dir"

  cat >"$nix_conf" <<'EOF'
# Optimized Nix configuration for build performance
# Generated by nix-cache-optimizer.sh

# Build performance settings
cores = 8
max-jobs = 4
keep-outputs = true
keep-derivations = true

# Cache and substitution settings
auto-optimise-store = true
builders-use-substitutes = true
substitute = true

# Binary caches
substituters = https://cache.nixos.org/ https://nix-community.cachix.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=

# Performance optimizations
connect-timeout = 5
stalled-download-timeout = 300
download-attempts = 3

# Storage optimization
auto-optimise-store = true
min-free = 1073741824  # 1GB
max-free = 3221225472  # 3GB

# Build environment optimization
sandbox = true
pure-eval = false
warn-dirty = false
keep-going = true

# Experimental features
experimental-features = nix-command flakes ca-derivations

# Logging
log-lines = 25
verbosity = 0
EOF

  echo "Intelligent caching configuration applied to: $nix_conf"
  echo "Restart your shell or run 'nix-daemon' restart for changes to take effect"
}

# Monitor cache efficiency over time
monitor_cache_efficiency() {
  local monitoring_duration=${1:-300} # 5 minutes default

  echo "=== CACHE EFFICIENCY MONITORING ==="
  echo "Monitoring cache efficiency for $monitoring_duration seconds..."

  local monitor_log="$CACHE_REPORT_DIR/cache_monitor_${TIMESTAMP}.log"
  local start_time=$(date +%s)
  local end_time=$((start_time + monitoring_duration))

  echo "Start time: $(date)" >"$monitor_log"

  while [[ $(date +%s) -lt $end_time ]]; do
    # Check for active builds
    local active_builds=$(ps aux | grep -c '[n]ix.*build' || echo "0")
    local store_size=$(du -sb /nix/store 2>/dev/null | cut -f1 || echo "0")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$timestamp | Active builds: $active_builds | Store size: $store_size bytes" >>"$monitor_log"

    sleep 30
  done

  echo "End time: $(date)" >>"$monitor_log"
  echo "Monitoring complete. Log saved to: $monitor_log"
}

# Generate comprehensive cache report
generate_cache_report() {
  echo "=== COMPREHENSIVE CACHE REPORT ==="

  local report_file="$CACHE_REPORT_DIR/comprehensive_report_${TIMESTAMP}.md"

  cat >"$report_file" <<EOF
# Nix Cache Performance Report
Generated: $(date)

## Store Statistics
EOF

  # Add store analysis
  analyze_store_state >>"$report_file"

  cat >>"$report_file" <<'EOF'

## Cache Performance
EOF

  # Add cache performance analysis
  analyze_cache_performance >>"$report_file"

  cat >>"$report_file" <<'EOF'

## Recommendations

### Immediate Actions
1. Run garbage collection to remove dead paths
2. Enable store optimization for deduplication
3. Configure binary caches for faster downloads

### Long-term Optimizations
1. Implement layered caching strategy
2. Monitor build patterns for cache efficiency
3. Consider using remote builders for expensive builds

### Configuration Optimizations
- Increase max-jobs for better parallelization
- Enable keep-outputs for development workflow
- Configure appropriate cache retention policies
EOF

  echo "Comprehensive report generated: $report_file"
}

# Main command dispatch
case "${1:-help}" in
"analyze")
  analyze_store_state
  ;;
"optimize")
  optimize_store "${2:-}"
  ;;
"cache-perf")
  analyze_cache_performance
  ;;
"setup")
  setup_intelligent_caching
  ;;
"monitor")
  monitor_cache_efficiency "${2:-300}"
  ;;
"report")
  generate_cache_report
  ;;
"full-optimization")
  echo "Running full cache optimization..."
  analyze_store_state
  analyze_cache_performance
  optimize_store
  setup_intelligent_caching
  ;;
"help" | *)
  cat <<EOF
Nix Cache Optimizer

Usage: $0 <command> [args]

Commands:
  analyze              Analyze current Nix store state
  optimize [--delete]  Optimize store (use --delete to actually remove dead paths)
  cache-perf          Analyze cache performance from recent builds
  setup               Setup intelligent caching configuration
  monitor [seconds]   Monitor cache efficiency (default: 300s)
  report              Generate comprehensive cache report
  full-optimization   Run complete optimization workflow
  help                Show this help message

Examples:
  $0 analyze
  $0 optimize --delete
  $0 cache-perf
  $0 monitor 600
EOF
  ;;
esac
