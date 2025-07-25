# Shared Test Helpers Library
# Day 16: Green Phase - Basic test helpers implementation

{ pkgs }:

{
  # Basic test environment setup
  setupTestEnv = ''
    # Set up test environment variables
    export TEST_ENV=true
    export TEST_TIMESTAMP=$(date +%s)
    export original_dir=$(pwd)

    # Create test temporary directory
    export TEST_TMP_DIR=$(mktemp -d -t "test-XXXXXX")

    # Function to clean up test environment
    cleanup_test_env() {
      if [[ -n "''${TEST_TMP_DIR:-}" && -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
      fi
    }

    # Set trap for cleanup
    trap cleanup_test_env EXIT

    echo "Test environment initialized (PID: $$, TMP: $TEST_TMP_DIR)"
  '';

  # Performance measurement utilities
  measurePerformance = ''
    measure_start() {
      local metric_name="$1"
      eval "''${metric_name}_START=\$(date +%s%N)"
      eval "''${metric_name}_MEMORY_START=\$(ps -o rss= -p \$\$ 2>/dev/null || echo '0')"
    }

    measure_end() {
      local metric_name="$1"
      local start_var="''${metric_name}_START"
      local memory_start_var="''${metric_name}_MEMORY_START"

      local end_time=$(date +%s%N)
      local end_memory=$(ps -o rss= -p $$ 2>/dev/null || echo "0")

      local start_time=$(eval echo \$"$start_var")
      local start_memory=$(eval echo \$"$memory_start_var")

      if [[ -n "$start_time" ]]; then
        local duration_ms=$(( (end_time - start_time) / 1000000 ))
        local memory_delta=$((end_memory - start_memory))

        echo "Performance [$metric_name]: ''${duration_ms}ms, Memory delta: ''${memory_delta}KB"

        # Store results in global variables
        eval "''${metric_name}_DURATION_MS=$duration_ms"
        eval "''${metric_name}_MEMORY_DELTA_KB=$memory_delta"
      fi
    }
  '';

  # Test isolation utilities
  isolatedTest = ''
    run_isolated() {
      local test_name="$1"
      local test_function="$2"

      echo "Running isolated test: $test_name"

      # Create isolated environment
      local isolated_dir=$(mktemp -d -t "isolated-$test_name-XXXXXX")
      local original_pwd=$(pwd)

      cd "$isolated_dir"

      # Run test in isolated environment
      if eval "$test_function"; then
        echo "✅ PASS: $test_name (isolated)"
        cd "$original_pwd"
        rm -rf "$isolated_dir" 2>/dev/null || true
        return 0
      else
        echo "❌ FAIL: $test_name (isolated)"
        cd "$original_pwd"
        rm -rf "$isolated_dir" 2>/dev/null || true
        return 1
      fi
    }
  '';
}
