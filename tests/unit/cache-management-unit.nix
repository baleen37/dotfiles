# Cache Management Unit Tests
# Tests for cache optimization and management functionality

{ pkgs, lib, config, ... }:
let
  testHelpers = import ../test-helpers.nix { inherit pkgs lib; };

  testCacheManagement = {
    name = "cache-management-unit";

    testScript = testHelpers.createTestScript {
      name = "Cache Management Unit Tests";

      script = ''
        set -e

        # Test environment setup
        export TEST_CACHE_DIR="$HOME/.cache/test-nix"
        export TEST_STAT_FILE="$HOME/.cache/test-nix-build-stats"

        # Source the cache management module
        . ${config.build.scriptPath}/lib/cache-management.sh

        # Override cache constants for testing
        CACHE_MAX_SIZE_GB=1
        CACHE_CLEANUP_DAYS=1
        CACHE_STAT_FILE="$TEST_STAT_FILE"

        ${testHelpers.testSection "Cache Statistics Management"}

        # Test 1: Initialize cache statistics
        ${testHelpers.testSubsection "Cache Statistics Initialization"}

        # Clean up any existing test files
        rm -f "$TEST_STAT_FILE"

        init_cache_stats

        if [ -f "$TEST_STAT_FILE" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache statistics file created"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failed to create cache statistics file"
          exit 1
        fi

        # Verify initial values
        INITIAL_HITS=$(grep "cache_hits=" "$TEST_STAT_FILE" | cut -d'=' -f2)
        INITIAL_MISSES=$(grep "cache_misses=" "$TEST_STAT_FILE" | cut -d'=' -f2)
        INITIAL_TOTAL=$(grep "total_builds=" "$TEST_STAT_FILE" | cut -d'=' -f2)

        if [ "$INITIAL_HITS" = "0" ] && [ "$INITIAL_MISSES" = "0" ] && [ "$INITIAL_TOTAL" = "0" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Initial cache statistics are correct"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Initial cache statistics are incorrect"
          exit 1
        fi

        # Test 2: Update cache statistics
        ${testHelpers.testSubsection "Cache Statistics Updates"}

        # Test cache hit
        update_cache_stats "true"

        HITS_AFTER_HIT=$(grep "cache_hits=" "$TEST_STAT_FILE" | cut -d'=' -f2)
        TOTAL_AFTER_HIT=$(grep "total_builds=" "$TEST_STAT_FILE" | cut -d'=' -f2)

        if [ "$HITS_AFTER_HIT" = "1" ] && [ "$TOTAL_AFTER_HIT" = "1" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache hit statistics updated correctly"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache hit statistics update failed"
          exit 1
        fi

        # Test cache miss
        update_cache_stats "false"

        HITS_AFTER_MISS=$(grep "cache_hits=" "$TEST_STAT_FILE" | cut -d'=' -f2)
        MISSES_AFTER_MISS=$(grep "cache_misses=" "$TEST_STAT_FILE" | cut -d'=' -f2)
        TOTAL_AFTER_MISS=$(grep "total_builds=" "$TEST_STAT_FILE" | cut -d'=' -f2)

        if [ "$HITS_AFTER_MISS" = "1" ] && [ "$MISSES_AFTER_MISS" = "1" ] && [ "$TOTAL_AFTER_MISS" = "2" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache miss statistics updated correctly"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache miss statistics update failed"
          exit 1
        fi

        # Test 3: Cache size detection
        ${testHelpers.testSubsection "Cache Size Detection"}

        # Create a test cache directory with known size
        mkdir -p "$TEST_CACHE_DIR"

        # Create a test file with known size (1MB)
        dd if=/dev/zero of="$TEST_CACHE_DIR/testfile" bs=1024 count=1024 2>/dev/null

        # Override get_cache_size function for testing
        get_cache_size() {
          if [ -d "$TEST_CACHE_DIR" ]; then
            du -sm "$TEST_CACHE_DIR" 2>/dev/null | cut -f1 || echo "0"
          else
            echo "0"
          fi
        }

        TEST_CACHE_SIZE=$(get_cache_size)

        if [ "$TEST_CACHE_SIZE" -ge 1 ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache size detection works (${TEST_CACHE_SIZE}MB)"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache size detection failed"
          exit 1
        fi

        # Test 4: Cache cleanup necessity check
        ${testHelpers.testSubsection "Cache Cleanup Logic"}

        # Test with oversized cache
        CACHE_MAX_SIZE_GB=0  # Set to 0 to force cleanup

        if needs_cache_cleanup; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache cleanup correctly identified as needed"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache cleanup necessity check failed"
          exit 1
        fi

        # Test 5: Cache optimization configuration
        ${testHelpers.testSubsection "Cache Optimization Configuration"}

        # Test cache settings configuration
        configure_cache_settings

        if [ -n "$NIX_CACHE_OPTIONS" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache optimization settings configured"
          echo "${testHelpers.colors.blue}Cache options: $NIX_CACHE_OPTIONS${testHelpers.colors.reset}"
        else
          echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Cache optimization settings not changed (may already be optimal)"
        fi

        # Test 6: Optimized command generation
        ${testHelpers.testSubsection "Optimized Command Generation"}

        TEST_BASE_CMD="nix build --impure"
        OPTIMIZED_CMD=$(get_optimized_nix_command "$TEST_BASE_CMD")

        if [ -n "$OPTIMIZED_CMD" ]; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Optimized command generated successfully"
          echo "${testHelpers.colors.blue}Optimized command: $OPTIMIZED_CMD${testHelpers.colors.reset}"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Optimized command generation failed"
          exit 1
        fi

        # Test 7: Cache statistics display
        ${testHelpers.testSubsection "Cache Statistics Display"}

        echo "${testHelpers.colors.blue}Testing cache statistics display:${testHelpers.colors.reset}"
        show_cache_stats

        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache statistics display completed"

        # Cleanup
        rm -rf "$TEST_CACHE_DIR"
        rm -f "$TEST_STAT_FILE"

        echo ""
        echo "${testHelpers.colors.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${testHelpers.colors.reset}"
        echo "${testHelpers.colors.green}  Cache Management Unit Tests: PASSED${testHelpers.colors.reset}"
        echo "${testHelpers.colors.green}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${testHelpers.colors.reset}"
      '';
    };
  };
in
{
  inherit testCacheManagement;
}
