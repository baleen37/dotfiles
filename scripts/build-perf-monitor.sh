#!/usr/bin/env bash
# Build Performance Monitoring Script
# Tracks Nix build times, cache hits, and resource usage

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly PERF_LOG_DIR="$PROJECT_ROOT/.perf-logs"
readonly TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Create performance log directory
mkdir -p "$PERF_LOG_DIR"

# Performance metrics collection
collect_build_metrics() {
  local target="${1:-}"
  local log_file="$PERF_LOG_DIR/build_${TIMESTAMP}.json"

  if [[ -z $target ]]; then
    echo "Usage: collect_build_metrics <target>"
    return 1
  fi

  echo "Collecting build performance metrics for: $target"

  # System info
  local cpu_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo "unknown")
  local memory_gb=$(($(sysctl -n hw.memsize 2>/dev/null || echo "0") / 1024 / 1024 / 1024))

  # Start time and resource monitoring
  local start_time=$(date +%s)
  local start_memory=$(ps -o rss= -p $$ | awk '{print $1}')

  # Run build with verbose logging
  echo "Starting build at $(date)"
  nix build "$target" \
    --verbose \
    --print-build-logs \
    --show-trace \
    2>&1 | tee "$PERF_LOG_DIR/build_output_${TIMESTAMP}.log" &

  local build_pid=$!

  # Monitor resource usage
  local max_memory=0
  while kill -0 $build_pid 2>/dev/null; do
    local current_memory=$(ps -o rss= -p $build_pid 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    if [[ $current_memory -gt $max_memory ]]; then
      max_memory=$current_memory
    fi
    sleep 1
  done

  wait $build_pid
  local build_exit_code=$?
  local end_time=$(date +%s)
  local build_duration=$((end_time - start_time))

  # Parse build output for cache statistics
  local build_log="$PERF_LOG_DIR/build_output_${TIMESTAMP}.log"
  local total_derivations=$(grep -c "building '/nix/store/" "$build_log" 2>/dev/null || echo "0")
  local cached_hits=$(grep -c "copying path.*from" "$build_log" 2>/dev/null || echo "0")
  local local_builds=$(grep -c "building path(s)" "$build_log" 2>/dev/null || echo "0")

  # Generate performance report
  cat >"$log_file" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "target": "$target",
  "build_result": {
    "exit_code": $build_exit_code,
    "duration_seconds": $build_duration,
    "duration_human": "$(printf '%02d:%02d:%02d' $((build_duration / 3600)) $((build_duration % 3600 / 60)) $((build_duration % 60)))"
  },
  "system_info": {
    "cpu_cores": $cpu_cores,
    "memory_gb": $memory_gb,
    "hostname": "$(hostname)"
  },
  "resource_usage": {
    "max_memory_kb": $max_memory,
    "max_memory_mb": $((max_memory / 1024))
  },
  "cache_statistics": {
    "total_derivations": $total_derivations,
    "cache_hits": $cached_hits,
    "local_builds": $local_builds,
    "cache_hit_ratio": $(echo "scale=2; $cached_hits / ($total_derivations + 0.001)" | bc -l 2>/dev/null || echo "0")
  }
}
EOF

  echo "Performance metrics saved to: $log_file"

  # Generate summary
  cat <<EOF

=== BUILD PERFORMANCE SUMMARY ===
Target: $target
Duration: $(printf '%02d:%02d:%02d' $((build_duration / 3600)) $((build_duration % 3600 / 60)) $((build_duration % 60)))
Exit Code: $build_exit_code
Memory Usage: $((max_memory / 1024)) MB
Cache Hit Ratio: $(echo "scale=1; $cached_hits * 100 / ($total_derivations + 0.001)" | bc -l 2>/dev/null || echo "0")%
Total Derivations: $total_derivations
Cache Hits: $cached_hits
Local Builds: $local_builds

EOF

  return $build_exit_code
}

# Analyze historical performance data
analyze_performance_trends() {
  echo "=== PERFORMANCE TREND ANALYSIS ==="

  if [[ ! -d $PERF_LOG_DIR ]] || [[ -z "$(ls -A "$PERF_LOG_DIR"/*.json 2>/dev/null)" ]]; then
    echo "No performance data available. Run some builds first."
    return 0
  fi

  echo "Recent build performance:"
  for json_file in "$PERF_LOG_DIR"/*.json; do
    if [[ -f $json_file ]]; then
      local target=$(jq -r '.target' "$json_file" 2>/dev/null || echo "unknown")
      local duration=$(jq -r '.build_result.duration_human' "$json_file" 2>/dev/null || echo "unknown")
      local cache_ratio=$(jq -r '.cache_statistics.cache_hit_ratio' "$json_file" 2>/dev/null || echo "0")
      local timestamp=$(jq -r '.timestamp' "$json_file" 2>/dev/null || echo "unknown")

      printf "%-20s | %-10s | %-8s | %s\n" \
        "$(basename "$target")" \
        "$duration" \
        "${cache_ratio}%" \
        "$timestamp"
    fi
  done | sort -k4 -r | head -10
}

# Check for unnecessary rebuilds
check_rebuild_triggers() {
  echo "=== REBUILD TRIGGER ANALYSIS ==="

  # Check if any source files changed
  if git diff --quiet; then
    echo "✓ No uncommitted changes detected"
  else
    echo "⚠ Uncommitted changes detected:"
    git diff --name-only | head -5
  fi

  # Check for timestamp-based rebuilds
  echo "Checking for files that might trigger unnecessary rebuilds:"
  find "$PROJECT_ROOT" -name "*.nix" -newer "$PROJECT_ROOT/flake.lock" 2>/dev/null | head -5 || echo "No newer files found"

  # Check flake.lock age
  if [[ -f "$PROJECT_ROOT/flake.lock" ]]; then
    local lock_age=$(($(date +%s) - $(stat -f %m "$PROJECT_ROOT/flake.lock" 2>/dev/null || echo "0")))
    local lock_days=$((lock_age / 86400))

    if [[ $lock_days -gt 7 ]]; then
      echo "⚠ flake.lock is $lock_days days old - consider updating"
    else
      echo "✓ flake.lock is recent ($lock_days days old)"
    fi
  fi
}

# Main command dispatch
case "${1:-help}" in
"collect")
  collect_build_metrics "${2:-}"
  ;;
"analyze")
  analyze_performance_trends
  ;;
"check-rebuilds")
  check_rebuild_triggers
  ;;
"full-report")
  check_rebuild_triggers
  echo ""
  analyze_performance_trends
  ;;
"help" | *)
  cat <<EOF
Build Performance Monitor

Usage: $0 <command> [args]

Commands:
  collect <target>    Collect performance metrics for a build target
  analyze             Analyze historical performance trends
  check-rebuilds      Check for unnecessary rebuild triggers
  full-report         Run complete performance analysis
  help                Show this help message

Examples:
  $0 collect .#darwinConfigurations.hostname.system
  $0 analyze
  $0 check-rebuilds
EOF
  ;;
esac
