{ lib, pkgs, ... }:

let
  # Import test utilities
  testUtils = import ../lib/test-helpers.nix { inherit lib pkgs; };

  # Test configuration for lib consolidation
  testConfig = {
    platforms = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" "x86_64-darwin" ];
    commonLibFiles = [
      "sudo-management.sh"
      "logging.sh"
      "performance.sh"
      "token-replacement.sh"
      "ui-utils.sh"
      "user-input.sh"
      "platform-config.sh"
      "progress.sh"
      "build-logic.sh"
    ];
  };

in

{
  # Test that shared lib functions work across platforms
  test_shared_lib_functions_work_across_platforms = testUtils.runShellTest {
    name = "shared-lib-functions-cross-platform";
    script = ''
      # Test that common library functions are accessible from all platforms
      source ${../lib/portable-paths.nix}

      # Verify that consolidated lib functions exist
      if [ ! -f "scripts/lib/sudo-management.sh" ]; then
        echo "FAIL: Consolidated sudo-management.sh not found"
        exit 1
      fi

      if [ ! -f "scripts/lib/logging.sh" ]; then
        echo "FAIL: Consolidated logging.sh not found"
        exit 1
      fi

      # Test that functions can be sourced successfully
      source scripts/lib/sudo-management.sh
      source scripts/lib/logging.sh

      # Test basic function existence
      if ! declare -f check_sudo_available >/dev/null 2>&1; then
        echo "FAIL: check_sudo_available function not found"
        exit 1
      fi

      if ! declare -f log_info >/dev/null 2>&1; then
        echo "FAIL: log_info function not found"
        exit 1
      fi

      echo "PASS: Shared lib functions accessible across platforms"
    '';
  };

  # Test that platform-specific overrides work
  test_platform_specific_overrides_work = testUtils.runShellTest {
    name = "platform-specific-overrides";
    script = ''
      # Test platform detection and override loading
      source scripts/lib/platform-config.sh

      # Mock platform detection
      export PLATFORM_OVERRIDE_TEST=true

      # Test that platform-specific configurations are applied
      platform=$(detect_platform)
      if [ -z "$platform" ]; then
        echo "FAIL: Platform detection failed"
        exit 1
      fi

      # Test that platform-specific overrides directory exists
      if [ ! -d "scripts/platform" ]; then
        echo "FAIL: Platform overrides directory not found"
        exit 1
      fi

      # Test that platform-specific override files can be loaded
      if [ -f "scripts/platform/$platform-overrides.sh" ]; then
        source "scripts/platform/$platform-overrides.sh"
        echo "PASS: Platform-specific overrides loaded successfully"
      else
        echo "PASS: No platform-specific overrides needed for $platform"
      fi
    '';
  };

  # Test that existing functionality is preserved
  test_existing_functionality_preserved = testUtils.runShellTest {
    name = "existing-functionality-preserved";
    script = ''
      # Test that all existing functions still work after consolidation
      source scripts/lib/sudo-management.sh
      source scripts/lib/logging.sh
      source scripts/lib/performance.sh

      # Test sudo management functions
      if ! declare -f check_sudo_available >/dev/null 2>&1; then
        echo "FAIL: check_sudo_available function missing"
        exit 1
      fi

      if ! declare -f handle_sudo_prompt >/dev/null 2>&1; then
        echo "FAIL: handle_sudo_prompt function missing"
        exit 1
      fi

      # Test logging functions
      if ! declare -f log_info >/dev/null 2>&1; then
        echo "FAIL: log_info function missing"
        exit 1
      fi

      if ! declare -f log_error >/dev/null 2>&1; then
        echo "FAIL: log_error function missing"
        exit 1
      fi

      # Test performance functions
      if ! declare -f start_timer >/dev/null 2>&1; then
        echo "FAIL: start_timer function missing"
        exit 1
      fi

      echo "PASS: All existing functions preserved"
    '';
  };

  # Test that no duplicate code exists after consolidation
  test_no_duplicate_code_after_consolidation = testUtils.runShellTest {
    name = "no-duplicate-code";
    script = ''
      # Check that platform-specific lib directories don't contain duplicates
      duplicate_count=0

      for platform in ${toString testConfig.platforms}; do
        for lib_file in ${toString testConfig.commonLibFiles}; do
          if [ -f "apps/$platform/lib/$lib_file" ] && [ -f "scripts/lib/$lib_file" ]; then
            # Check if files are identical
            if diff -q "apps/$platform/lib/$lib_file" "scripts/lib/$lib_file" >/dev/null 2>&1; then
              echo "DUPLICATE: $lib_file exists in both apps/$platform/lib and scripts/lib"
              duplicate_count=$((duplicate_count + 1))
            fi
          fi
        done
      done

      if [ $duplicate_count -gt 0 ]; then
        echo "FAIL: Found $duplicate_count duplicate files"
        exit 1
      fi

      echo "PASS: No duplicate code found"
    '';
  };

  # Test that platform-specific build logic works
  test_platform_build_logic_integration = testUtils.runShellTest {
    name = "platform-build-logic-integration";
    script = ''
      # Test that build logic can access consolidated libraries
      source scripts/lib/build-logic.sh
      source scripts/lib/platform-config.sh

      # Test basic build function existence
      if ! declare -f prepare_build_environment >/dev/null 2>&1; then
        echo "FAIL: prepare_build_environment function not found"
        exit 1
      fi

      if ! declare -f execute_build_steps >/dev/null 2>&1; then
        echo "FAIL: execute_build_steps function not found"
        exit 1
      fi

      # Test platform-specific build configuration
      platform=$(detect_platform)
      if [ -f "scripts/platform/$platform-build.sh" ]; then
        source "scripts/platform/$platform-build.sh"
        echo "PASS: Platform-specific build configuration loaded"
      else
        echo "PASS: Using default build configuration for $platform"
      fi
    '';
  };

  # Test configuration: Expected to fail initially (Red phase)
  expectedFailures = [
    "shared-lib-functions-cross-platform"
    "platform-specific-overrides"
    "existing-functionality-preserved"
    "no-duplicate-code"
    "platform-build-logic-integration"
  ];
}
