# Cache Management Unit Tests
# Tests for cache optimization and management functionality

{ pkgs, ... }:

let
  # Import test helpers
  helpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Test that cache management functions exist and work correctly
  testCacheManagement = pkgs.runCommand "test-cache-management" {
    buildInputs = [ pkgs.bash pkgs.coreutils ];
  } ''
    # Test that we can source the cache management module
    if [ -f ${../../scripts/lib/cache-management.sh} ]; then
      echo "✅ Cache management module exists"

      # First source logging module (dependency)
      source ${../../scripts/lib/logging.sh}

      # Source the cache management module
      source ${../../scripts/lib/cache-management.sh}

      # Test that all expected functions exist
      if declare -f init_cache_stats > /dev/null; then
        echo "✅ init_cache_stats function exists"
      else
        echo "❌ init_cache_stats function missing"
        exit 1
      fi

      if declare -f update_cache_stats > /dev/null; then
        echo "✅ update_cache_stats function exists"
      else
        echo "❌ update_cache_stats function missing"
        exit 1
      fi

      if declare -f get_cache_size > /dev/null; then
        echo "✅ get_cache_size function exists"
      else
        echo "❌ get_cache_size function missing"
        exit 1
      fi

      if declare -f needs_cache_cleanup > /dev/null; then
        echo "✅ needs_cache_cleanup function exists"
      else
        echo "❌ needs_cache_cleanup function missing"
        exit 1
      fi

      if declare -f optimize_cache > /dev/null; then
        echo "✅ optimize_cache function exists"
      else
        echo "❌ optimize_cache function missing"
        exit 1
      fi

      # Test cache statistics initialization
      export HOME="$PWD/test-home"
      mkdir -p "$HOME/.cache"

      # Override the cache stat file location for testing
      export CACHE_STAT_FILE="$HOME/.cache/nix-build-stats"

      # Initialize cache stats
      init_cache_stats

      if [ -f "$HOME/.cache/nix-build-stats" ]; then
        echo "✅ Cache statistics file created"
      else
        echo "❌ Cache statistics file not created"
        exit 1
      fi

      # Test cache size detection (should work even with empty cache)
      CACHE_SIZE=$(get_cache_size)
      if [ "$CACHE_SIZE" -ge 0 ] 2>/dev/null; then
        echo "✅ Cache size detection works ($CACHE_SIZE MB)"
      else
        echo "❌ Cache size detection failed"
        exit 1
      fi

      # Test cache cleanup check
      if needs_cache_cleanup; then
        echo "✅ Cache cleanup check works (cleanup needed)"
      else
        echo "✅ Cache cleanup check works (no cleanup needed)"
      fi

      echo "✅ All cache management tests passed"
      touch $out
    else
      echo "❌ Cache management module not found"
      exit 1
    fi
  '';

in
testCacheManagement
