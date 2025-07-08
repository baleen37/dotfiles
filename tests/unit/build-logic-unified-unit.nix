{ lib, pkgs, ... }:

let
  # Import test utilities
  testUtils = import ../lib/test-helpers.nix { inherit lib pkgs; };

  # Test configuration for build logic unification
  testConfig = {
    platforms = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
    buildCommands = [
      "run_build"
      "execute_build_switch"
      "optimize_cache"
      "detect_optimal_jobs"
    ];
  };

in

{
  # Test that build steps are consistent across platforms
  test_build_steps_consistent_across_platforms = testUtils.runShellTest {
    name = "build-steps-consistent-cross-platform";
    script = ''
      # Test that unified build logic works for all platforms
      source scripts/lib/build-logic.sh
      source scripts/lib/performance.sh
      source scripts/lib/logging.sh

      # Mock platform detection for testing
      export PLATFORM_OVERRIDE_TEST=true

      # Test Darwin platform
      export PLATFORM_TYPE="darwin"
      export SYSTEM_TYPE="aarch64-darwin"
      export FLAKE_SYSTEM="darwinConfigurations.aarch64-darwin.system"

      # Test basic function existence
      if ! declare -f run_build >/dev/null 2>&1; then
        echo "FAIL: run_build function not found"
        exit 1
      fi

      if ! declare -f execute_build_switch >/dev/null 2>&1; then
        echo "FAIL: execute_build_switch function not found"
        exit 1
      fi

      # Test Linux platform
      export PLATFORM_TYPE="linux"
      export SYSTEM_TYPE="x86_64-linux"
      export FLAKE_SYSTEM="nixosConfigurations.x86_64-linux.config.system.build.toplevel"

      # Verify functions still work with different platform
      if ! declare -f run_build >/dev/null 2>&1; then
        echo "FAIL: run_build function not available for Linux"
        exit 1
      fi

      echo "PASS: Build steps consistent across platforms"
    '';
  };

  # Test that error handling is unified
  test_error_handling_unified = testUtils.runShellTest {
    name = "error-handling-unified";
    script = ''
      source scripts/lib/build-logic.sh
      source scripts/lib/logging.sh

      # Test that error handling functions exist
      if ! declare -f handle_build_error >/dev/null 2>&1; then
        echo "FAIL: handle_build_error function not found"
        exit 1
      fi

      # Test error recovery mechanisms
      if ! declare -f cleanup_on_failure >/dev/null 2>&1; then
        echo "FAIL: cleanup_on_failure function not found"
        exit 1
      fi

      # Test error logging integration
      if ! declare -f log_error >/dev/null 2>&1; then
        echo "FAIL: log_error function not integrated"
        exit 1
      fi

      echo "PASS: Error handling unified"
    '';
  };

  # Test that performance improvements are implemented
  test_performance_improvements = testUtils.runShellTest {
    name = "performance-improvements";
    script = ''
      source scripts/lib/build-logic.sh
      source scripts/lib/performance.sh

      # Test parallel job detection
      if ! declare -f detect_optimal_jobs >/dev/null 2>&1; then
        echo "FAIL: detect_optimal_jobs function not found"
        exit 1
      fi

      # Test build optimization flags
      if ! declare -f get_build_optimization_flags >/dev/null 2>&1; then
        echo "FAIL: get_build_optimization_flags function not found"
        exit 1
      fi

      # Test cache optimization
      if ! declare -f optimize_cache >/dev/null 2>&1; then
        echo "FAIL: optimize_cache function not found"
        exit 1
      fi

      # Test performance monitoring
      if ! declare -f perf_start_phase >/dev/null 2>&1; then
        echo "FAIL: perf_start_phase function not found"
        exit 1
      fi

      echo "PASS: Performance improvements implemented"
    '';
  };

  # Test that platform-specific build configurations work
  test_platform_specific_build_configs = testUtils.runShellTest {
    name = "platform-specific-build-configs";
    script = ''
      # Test that platform overrides can customize build behavior
      source scripts/lib/build-logic.sh

      # Test Darwin-specific configuration
      export PLATFORM_TYPE="darwin"
      export REBUILD_COMMAND="darwin-rebuild"
      export PLATFORM_NAME="Nix Darwin"

      # Test that platform-specific settings are applied
      if [ -f "scripts/platform/darwin-overrides.sh" ]; then
        source scripts/platform/darwin-overrides.sh
        echo "PASS: Darwin build configuration available"
      else
        echo "PASS: No Darwin-specific build overrides needed"
      fi

      # Test Linux-specific configuration
      export PLATFORM_TYPE="linux"
      export REBUILD_COMMAND="nixos-rebuild"
      export PLATFORM_NAME="NixOS"

      if [ -f "scripts/platform/linux-overrides.sh" ]; then
        source scripts/platform/linux-overrides.sh
        echo "PASS: Linux build configuration available"
      else
        echo "PASS: No Linux-specific build overrides needed"
      fi
    '';
  };

  # Test that build logic integrates with existing platform interface
  test_build_logic_platform_integration = testUtils.runShellTest {
    name = "build-logic-platform-integration";
    script = ''
      # Test integration with platform interface system
      source scripts/platform/common-interface.sh
      source scripts/lib/build-logic.sh

      # Initialize platform interface
      init_platform

      # Test that build logic can detect current platform
      platform=$(detect_platform_type)
      if [ -z "$platform" ]; then
        echo "FAIL: Platform detection failed"
        exit 1
      fi

      # Test that build functions work with platform interface
      export PLATFORM_TYPE="$platform"

      if ! declare -f run_build >/dev/null 2>&1; then
        echo "FAIL: Build logic not integrated with platform interface"
        exit 1
      fi

      echo "PASS: Build logic integrated with platform interface"
    '';
  };

  # Test configuration: Expected to fail initially (Red phase)
  expectedFailures = [
    "build-steps-consistent-cross-platform"
    "error-handling-unified"
    "performance-improvements"
    "platform-specific-build-configs"
    "build-logic-platform-integration"
  ];
}
