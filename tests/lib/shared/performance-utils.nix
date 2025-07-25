# Shared Performance Utilities
# Day 16: Green Phase - Performance measurement and optimization utilities

{ pkgs }:

{
  # Enhanced performance measurement with detailed metrics
  performanceProfiler = ''
    # Global performance tracking variables
    declare -A PERF_METRICS
    declare -A PERF_START_TIMES
    declare -A PERF_START_MEMORY

    # Start performance measurement
    perf_start() {
      local metric_name="$1"
      local timestamp=$(date +%s%3N 2>/dev/null || date +%s)
      local memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

      PERF_START_TIMES["$metric_name"]="$timestamp"
      PERF_START_MEMORY["$metric_name"]="$memory"

      echo "📊 Started profiling: $metric_name"
    }

    # End performance measurement
    perf_end() {
      local metric_name="$1"
      local end_timestamp=$(date +%s%3N 2>/dev/null || date +%s)
      local end_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")

      local start_timestamp="''${PERF_START_TIMES[$metric_name]:-0}"
      local start_memory="''${PERF_START_MEMORY[$metric_name]:-0}"

      if [[ "$start_timestamp" != "0" ]]; then
        local duration=$((end_timestamp - start_timestamp))
        local memory_delta=$((end_memory - start_memory))

        PERF_METRICS["''${metric_name}_duration"]="$duration"
        PERF_METRICS["''${metric_name}_memory_delta"]="$memory_delta"

        echo "📊 Completed profiling: $metric_name (''${duration}ms, ''${memory_delta}KB)"
      fi
    }

    # Get performance report
    perf_report() {
      echo ""
      echo "=== Performance Report ==="
      for key in "''${!PERF_METRICS[@]}"; do
        echo "  $key: ''${PERF_METRICS[$key]}"
      done
      echo ""

      # Calculate totals
      local total_duration=0
      local total_memory=0

      for key in "''${!PERF_METRICS[@]}"; do
        if [[ "$key" =~ _duration$ ]]; then
          total_duration=$((total_duration + PERF_METRICS[$key]))
        elif [[ "$key" =~ _memory_delta$ ]]; then
          total_memory=$((total_memory + PERF_METRICS[$key]))
        fi
      done

      echo "📊 Total Duration: ''${total_duration}ms"
      echo "💾 Total Memory Delta: ''${total_memory}KB"
    }
  '';

  # Memory optimization utilities
  memoryOptimizer = ''
    # Memory usage monitoring
    monitor_memory() {
      local label="''${1:-memory-check}"
      local current_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
      echo "💾 Memory usage [$label]: ''${current_memory}KB"
      return $current_memory
    }

    # Force garbage collection (where applicable)
    optimize_memory() {
      echo "🧹 Optimizing memory usage..."

      # Clear shell variable cache
      unset HISTFILE

      # Cleanup temporary files
      if [[ -n "''${TEST_TMP_DIR:-}" && -d "$TEST_TMP_DIR" ]]; then
        find "$TEST_TMP_DIR" -type f -mmin +5 -delete 2>/dev/null || true
      fi

      echo "✅ Memory optimization completed"
    }

    # Memory-efficient file operations
    efficient_file_check() {
      local file_path="$1"
      local check_type="''${2:-exists}"

      case "$check_type" in
        "exists")
          [[ -e "$file_path" ]]
          ;;
        "readable")
          [[ -r "$file_path" ]]
          ;;
        "directory")
          [[ -d "$file_path" ]]
          ;;
        "not_empty")
          [[ -s "$file_path" ]]
          ;;
        *)
          [[ -e "$file_path" ]]
          ;;
      esac
    }
  '';

  # Test execution optimizer
  executionOptimizer = ''
    # Optimized test runner with early exit
    run_optimized_test() {
      local test_name="$1"
      local test_function="$2"
      local timeout="''${3:-30}"

      echo "🚀 Running optimized test: $test_name"
      perf_start "$test_name"

      # Run test with timeout
      if timeout "$timeout" bash -c "$test_function" 2>/dev/null; then
        perf_end "$test_name"
        echo "✅ PASS: $test_name"
        return 0
      else
        perf_end "$test_name"
        echo "❌ FAIL: $test_name"
        return 1
      fi
    }

    # Batch test executor
    run_test_batch() {
      local -n test_array=$1
      local passed=0
      local failed=0

      echo "🔄 Running test batch (''${#test_array[@]} tests)"

      for test_spec in "''${test_array[@]}"; do
        IFS='|' read -r test_name test_function <<< "$test_spec"

        if run_optimized_test "$test_name" "$test_function"; then
          ((passed++))
        else
          ((failed++))
        fi
      done

      echo "📊 Batch results: $passed passed, $failed failed"
      return $failed
    }
  '';
}
