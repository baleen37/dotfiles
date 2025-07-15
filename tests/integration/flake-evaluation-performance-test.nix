{ pkgs ? import <nixpkgs> {} }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
testHelpers.createTestScript {
  name = "flake-evaluation-performance-test";
  script = ''
    ${testHelpers.testSection "Flake Evaluation Performance Integration Tests"}

    # Test environment setup
    export PROJECT_ROOT="${toString ../../.}"
    export SCRIPTS_DIR="$PROJECT_ROOT/scripts"

    ${testHelpers.testSubsection "Environment Setup Tests"}

    # Test cache directory creation
    export XDG_CACHE_HOME="$PWD/test-cache"
    mkdir -p "$XDG_CACHE_HOME"

    # Source required modules
    export LIB_DIR="$SCRIPTS_DIR/lib"
    . "$LIB_DIR/logging.sh"
    . "$LIB_DIR/performance.sh"
    . "$LIB_DIR/progress.sh"
    . "$LIB_DIR/optimization.sh"
    . "$LIB_DIR/flake-evaluation.sh"

    ${testHelpers.testSubsection "Cache System Integration Tests"}

    # Mock functions for testing
    log_debug() { echo "DEBUG: $*"; }
    log_info() { echo "INFO: $*"; }
    log_warn() { echo "WARN: $*"; }
    log_error() { echo "ERROR: $*"; }
    log_success() { echo "SUCCESS: $*"; }

    # Test cache initialization
    if init_flake_evaluation_cache; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache initialization successful"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache initialization failed"
      exit 1
    fi

    # Test cache key generation
    CACHE_KEY=$(get_flake_cache_key)
    if [ -n "$CACHE_KEY" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache key generation: $CACHE_KEY"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Cache key generation failed"
      exit 1
    fi

    ${testHelpers.testSubsection "Batched Evaluation Logic Tests"}

    # Mock nix commands for testing (since we can't run real nix commands in test environment)
    nix() {
      case "$1" in
        "flake")
          case "$2" in
            "metadata")
              echo '{"lastModified": 1640995200}'
              ;;
          esac
          ;;
        "eval")
          if echo "$*" | grep -q "darwinConfigurations"; then
            echo '{"darwinConfigurations": {"test-system": {"system": "darwin"}}}'
          elif echo "$*" | grep -q "nixosConfigurations"; then
            echo '{"nixosConfigurations": {"test-system": {"system": "linux"}}}'
          else
            echo '{}'
          fi
          ;;
        "build")
          echo "Mock nix build completed"
          return 0
          ;;
      esac
      return 0
    }

    # Export mock function
    export -f nix

    # Test batched evaluation function
    export SYSTEM_TYPE="test-system"
    export PLATFORM_TYPE="darwin"

    if batch_evaluate_flake "$SYSTEM_TYPE" "darwinConfigurations" "apps"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Batched evaluation function works"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Batched evaluation function failed"
      exit 1
    fi

    ${testHelpers.testSubsection "Optimized Build Integration Tests"}

    # Test optimized flake build
    if optimized_flake_build "$SYSTEM_TYPE" "system"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Optimized flake build works"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Optimized flake build failed"
      exit 1
    fi

    ${testHelpers.testSubsection "Performance Measurement Tests"}

    # Test performance measurement wrapper
    test_operation() {
      sleep 0.1  # Simulate some work
      echo "Test operation completed"
      return 0
    }

    if measure_flake_evaluation_performance "test_operation" test_operation; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Performance measurement works"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Performance measurement failed"
      exit 1
    fi

    ${testHelpers.testSubsection "Fallback Mechanism Tests"}

    # Test fallback when batched evaluation fails
    # Override batch_evaluate_flake to fail
    batch_evaluate_flake() {
      echo "Simulated batch evaluation failure"
      return 1
    }

    if replace_individual_evaluations "$SYSTEM_TYPE" "build" 2>&1 | grep -q "individual evaluations"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Fallback mechanism message works"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Fallback mechanism should show appropriate message"
      exit 1
    fi

    ${testHelpers.testSubsection "Cache Cleanup Tests"}

    # Test cache cleanup
    cleanup_flake_evaluation_cache
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cache cleanup completed without errors"

    ${testHelpers.testSubsection "Module Loading Integration Tests"}

    # Test that the module loads correctly in build-switch-common.sh
    BUILD_SWITCH_SCRIPT="$SCRIPTS_DIR/build-switch-common.sh"
    if grep -q "flake-evaluation.sh" "$BUILD_SWITCH_SCRIPT"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Flake evaluation module properly loaded in build-switch-common.sh"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Flake evaluation module not loaded in build-switch-common.sh"
      exit 1
    fi

    echo ""
    echo "${testHelpers.colors.green}✓ All flake evaluation performance integration tests passed!${testHelpers.colors.reset}"
  '';
}
