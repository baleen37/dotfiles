#!/bin/sh
# Performance Optimization Module for Build Scripts
# Contains performance and caching optimization configurations

# Optimization settings based on environment
get_optimization_flags() {
  local optimization_flags=""

  # Always enable evaluation cache for better performance
  optimization_flags="$optimization_flags --eval-cache"

  # Environment-specific optimizations
  if [ "${CI:-}" = "true" ]; then
    # CI environment: conservative settings
    optimization_flags="$optimization_flags --quiet"
    log_info "CI optimization flags applied" >&2
  elif [ "${DEVELOPMENT:-}" = "true" ]; then
    # Development environment: more verbose for debugging
    log_info "Development optimization flags applied" >&2
  else
    # Production environment: balanced settings
    optimization_flags="$optimization_flags --quiet"
    log_info "Production optimization flags applied" >&2
  fi

  echo "$optimization_flags"
}

# Get build-specific optimization flags
get_build_optimization_flags() {
  local base_flags
  base_flags=$(get_optimization_flags)

  # Add build-specific flags
  echo "$base_flags --impure --no-warn-dirty"
}

# Get switch-specific optimization flags (for rebuild commands)
get_switch_optimization_flags() {
  local base_flags
  base_flags=$(get_optimization_flags)

  # Switch commands might need different flags
  # For now, just return base flags (future: add switch-specific optimizations)
  echo "$base_flags --impure"
}

# Check if optimization is available in current nix version
check_optimization_support() {
  if nix --help 2>/dev/null | grep -q "eval-cache"; then
    log_info "Eval cache optimization supported"
    return 0
  else
    log_warning "Eval cache optimization not supported in this nix version"
    return 1
  fi
}

# Performance mode configuration
set_performance_mode() {
  local mode="${1:-default}"

  case "$mode" in
  "conservative")
    export PERFORMANCE_MODE="conservative"
    log_info "Performance mode set to conservative (75% core utilization)"
    ;;
  "aggressive")
    export PERFORMANCE_MODE="aggressive"
    log_info "Performance mode set to aggressive (maximum core utilization)"
    ;;
  "default" | "")
    unset PERFORMANCE_MODE
    log_info "Performance mode set to default (intelligent scaling)"
    ;;
  *)
    log_warning "Unknown performance mode: $mode. Using default."
    unset PERFORMANCE_MODE
    ;;
  esac
}

# Get optimal parallel job count (integrated from performance.sh)
get_optimal_parallel_jobs() {
  if command -v detect_optimal_jobs >/dev/null 2>&1; then
    detect_optimal_jobs
  else
    # Fallback if performance.sh not loaded
    echo "4"
  fi
}

# Performance tuning recommendations
suggest_performance_improvements() {
  echo "🚀 Performance optimization suggestions:"
  echo "  • Enable eval-cache: $(check_optimization_support && echo "✅ Active" || echo "❌ Not available")"
  echo "  • CPU cores detected: $(get_optimal_parallel_jobs)"
  echo "  • Performance mode: ${PERFORMANCE_MODE:-default}"
  echo "  • Cache size: $(du -h ~/.cache/nix 2>/dev/null | cut -f1 || echo "Unknown")"
  echo ""
  echo "Available performance modes:"
  echo "  • default: Intelligent scaling based on system"
  echo "  • conservative: 75% core utilization (safer)"
  echo "  • aggressive: Maximum core utilization (faster)"
}
