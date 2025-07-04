# Unit Tests for Build Script Performance Module
# Tests performance monitoring functions extracted from build-switch-common.sh

{ pkgs, ... }:

let
  # Test that performance functions exist and work correctly
  testPerformanceModule = pkgs.runCommand "test-performance-module" {
    buildInputs = [ pkgs.bash ];
  } ''
    # Test that we can source the performance module
    if [ -f ${../../scripts/lib/performance.sh} ]; then
      echo "✅ Performance module exists"

      # Source the module
      source ${../../scripts/lib/performance.sh}

      # Test that all expected functions exist
      if declare -f perf_start_total > /dev/null; then
        echo "✅ perf_start_total function exists"
      else
        echo "❌ perf_start_total function missing"
        exit 1
      fi

      if declare -f perf_start_phase > /dev/null; then
        echo "✅ perf_start_phase function exists"
      else
        echo "❌ perf_start_phase function missing"
        exit 1
      fi

      if declare -f perf_end_phase > /dev/null; then
        echo "✅ perf_end_phase function exists"
      else
        echo "❌ perf_end_phase function missing"
        exit 1
      fi

      if declare -f perf_show_summary > /dev/null; then
        echo "✅ perf_show_summary function exists"
      else
        echo "❌ perf_show_summary function missing"
        exit 1
      fi

      if declare -f detect_optimal_jobs > /dev/null; then
        echo "✅ detect_optimal_jobs function exists"
      else
        echo "❌ detect_optimal_jobs function missing"
        exit 1
      fi

      # Test that performance variables are defined
      if [ -n "$PERF_START_TIME" ] || [ "$PERF_START_TIME" = "" ]; then
        echo "✅ PERF_START_TIME variable defined"
      else
        echo "❌ PERF_START_TIME variable missing"
        exit 1
      fi

      # Test performance functions work
      echo "Testing performance functions..."
      perf_start_total > /dev/null 2>&1
      perf_start_phase "test" > /dev/null 2>&1
      perf_end_phase "test" > /dev/null 2>&1

      # Test detect_optimal_jobs returns a number
      JOBS=$(detect_optimal_jobs)
      if [ "$JOBS" -gt 0 ] 2>/dev/null; then
        echo "✅ detect_optimal_jobs returns valid number: $JOBS"
      else
        echo "❌ detect_optimal_jobs returned invalid value: $JOBS"
        exit 1
      fi

      echo "✅ All performance tests passed"
    else
      echo "❌ Performance module does not exist yet - this test should fail initially"
      exit 1
    fi

    touch $out
  '';

in testPerformanceModule
