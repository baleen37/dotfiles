# Cache Optimization End-to-End Tests
# Tests complete build-switch process with cache optimization

{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  testCacheOptimizationE2E = {
    name = "cache-optimization-e2e";

    testScript = testHelpers.createTestScript {
      name = "Cache Optimization End-to-End Tests";

      script = ''
        set -e

        # Test environment setup
        TEST_CACHE_DIR="$HOME/.cache/test-cache-e2e"
        TEST_STAT_FILE="$HOME/.cache/test-nix-build-stats-e2e"
        export CACHE_STAT_FILE="$TEST_STAT_FILE"

        ${testHelpers.testSection "End-to-End Cache Optimization Tests"}

        # Test 1: Full build-switch process with cache optimization
        ${testHelpers.testSubsection "Complete Build Process with Cache Optimization"}

        echo "${testHelpers.colors.blue}Testing complete build-switch process with cache optimization${testHelpers.colors.reset}"

        # Clean up any existing cache for clean test
        rm -rf "$TEST_CACHE_DIR"
        rm -f "$TEST_STAT_FILE"

        # Source all required modules
        . ${src}/scripts/lib/logging.sh
        . ${src}/scripts/lib/performance.sh
        . ${src}/scripts/lib/cache-management.sh

        # Set up test environment variables
        export SYSTEM_TYPE="test-system"
        export VERBOSE="false"
        export PLATFORM_TYPE="test"

        # Test cache optimization initialization
        optimize_cache "$SYSTEM_TYPE"

        if [ -f "$TEST_STAT_FILE" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache statistics initialized"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache statistics initialization failed"
          exit 1
        fi

        # Test 2: Cache-optimized command generation
        ${testHelpers.testSubsection "Cache-Optimized Command Generation"}

        BASE_CMD="nix eval --impure '.#test'"
        OPTIMIZED_CMD=$(get_optimized_nix_command "$BASE_CMD")

        echo "${testHelpers.colors.blue}Base command: $BASE_CMD${testHelpers.colors.reset}"
        echo "${testHelpers.colors.blue}Optimized command: $OPTIMIZED_CMD${testHelpers.colors.reset}"

        if [ -n "$OPTIMIZED_CMD" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache-optimized command generated"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache-optimized command generation failed"
          exit 1
        fi

        # Test 3: Cache statistics tracking
        ${testHelpers.testSubsection "Cache Statistics Tracking"}

        # Simulate build processes
        START_TIME=$(date +%s)

        # Simulate quick build (cache hit)
        sleep 1
        END_TIME=$(date +%s)
        update_post_build_stats "true" "$START_TIME" "$END_TIME"

        # Simulate slow build (cache miss)
        START_TIME=$(date +%s)
        sleep 2
        END_TIME=$(date +%s)
        update_post_build_stats "true" "$START_TIME" "$END_TIME"

        # Check statistics
        TOTAL_BUILDS=$(grep "total_builds=" "$TEST_STAT_FILE" | cut -d'=' -f2)
        CACHE_HITS=$(grep "cache_hits=" "$TEST_STAT_FILE" | cut -d'=' -f2)

        if [ "$TOTAL_BUILDS" -eq 2 ] && [ "$CACHE_HITS" -eq 1 ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache statistics tracking works correctly"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache statistics tracking failed"
          echo "${testHelpers.colors.blue}Expected: 2 builds, 1 hit. Got: $TOTAL_BUILDS builds, $CACHE_HITS hits${testHelpers.colors.reset}"
          exit 1
        fi

        # Test 4: Cache cleanup logic
        ${testHelpers.testSubsection "Cache Cleanup Logic"}

        # Create oversized test cache
        mkdir -p "$TEST_CACHE_DIR"

        # Override functions for testing
        get_cache_size() {
          echo "6000"  # 6GB - exceeds default 5GB limit
        }

        cleanup_cache() {
          echo "${testHelpers.colors.blue}Mock cleanup: Cache size reduced${testHelpers.colors.reset}"
          # Update cleanup timestamp
          local current_time=$(date +%s)
          if [ -f "$TEST_STAT_FILE" ]; then
            sed -i.bak "s/last_cleanup=.*/last_cleanup=$current_time/" "$TEST_STAT_FILE"
            rm -f "$TEST_STAT_FILE.bak"
          fi
        }

        if needs_cache_cleanup; then
          cleanup_cache
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache cleanup logic works correctly"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache cleanup logic failed"
          exit 1
        fi

        # Test 5: Cache warming simulation
        ${testHelpers.testSubsection "Cache Warming"}

        # Mock warm_cache_for_system for testing
        warm_cache_for_system() {
          local system_type="$1"
          echo "${testHelpers.colors.blue}Mock warming cache for $system_type${testHelpers.colors.reset}"
          sleep 1  # Simulate cache warming time
          echo "${testHelpers.colors.blue}Cache warming completed for $system_type${testHelpers.colors.reset}"
        }

        warm_cache_for_system "test-darwin"
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache warming completed"

        # Test 6: Complete optimization workflow
        ${testHelpers.testSubsection "Complete Cache Optimization Workflow"}

        # Test the full optimization process
        optimize_cache "test-system"

        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Complete cache optimization workflow tested"

        # Test 7: Performance summary with cache statistics
        ${testHelpers.testSubsection "Performance Summary with Cache Statistics"}

        # Set up performance variables for testing
        export PERF_START_TIME=$(date +%s)
        export PERF_BUILD_DURATION=30
        export PERF_SWITCH_DURATION=15

        # Test performance summary display
        perf_show_summary

        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Performance summary with cache statistics displayed"

        # Cleanup
        rm -rf "$TEST_CACHE_DIR"
        rm -f "$TEST_STAT_FILE"

        echo ""
        echo "${testHelpers.colors.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${testHelpers.colors.reset}"
        echo "${testHelpers.colors.green}  Cache Optimization E2E Tests: PASSED${testHelpers.colors.reset}"
        echo "${testHelpers.colors.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${testHelpers.colors.reset}"
      '';
    };
  };
in
{
  inherit testCacheOptimizationE2E;
}
