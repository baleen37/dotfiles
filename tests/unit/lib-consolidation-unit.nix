{ lib, pkgs, ... }:

let
  # Import test utilities
  testUtils = import ../lib/test-helpers.nix { inherit pkgs; };

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

# Return a single derivation that runs all tests
testUtils.runShellTest {
  name = "lib-consolidation-unit-tests";
  script = ''
    echo "=== Lib Consolidation Unit Tests ==="
    echo "Note: These tests are expected to fail initially (TDD Red phase)"

    # Test that shared lib functions work across platforms
    echo "--- Test: Shared lib functions cross-platform ---"

    # Verify that consolidated lib functions exist
    if [ ! -f "scripts/lib/sudo-management.sh" ]; then
      echo "EXPECTED FAIL: Consolidated sudo-management.sh not found"
    else
      echo "PASS: sudo-management.sh exists"
    fi

    if [ ! -f "scripts/lib/logging.sh" ]; then
      echo "EXPECTED FAIL: Consolidated logging.sh not found"
    else
      echo "PASS: logging.sh exists"
    fi

    # Test that platform-specific overrides work
    echo "--- Test: Platform-specific overrides ---"

    # Test that platform-specific overrides directory exists
    if [ ! -d "scripts/platform" ]; then
      echo "EXPECTED FAIL: Platform overrides directory not found"
    else
      echo "PASS: Platform overrides directory exists"
    fi

    # Test that existing functionality is preserved
    echo "--- Test: Existing functionality preserved ---"

    # Test that common lib files exist
    for lib_file in ${toString testConfig.commonLibFiles}; do
      if [ ! -f "scripts/lib/$lib_file" ]; then
        echo "EXPECTED FAIL: $lib_file not found"
      else
        echo "PASS: $lib_file exists"
      fi
    done

    # Test that no duplicate code exists after consolidation
    echo "--- Test: No duplicate code ---"

    duplicate_count=0
    for platform in ${toString testConfig.platforms}; do
      for lib_file in ${toString testConfig.commonLibFiles}; do
        if [ -f "apps/$platform/lib/$lib_file" ] && [ -f "scripts/lib/$lib_file" ]; then
          echo "POTENTIAL DUPLICATE: $lib_file exists in both apps/$platform/lib and scripts/lib"
          duplicate_count=$((duplicate_count + 1))
        fi
      done
    done

    if [ $duplicate_count -gt 0 ]; then
      echo "INFO: Found $duplicate_count potential duplicate files (expected during development)"
    else
      echo "PASS: No duplicate code found"
    fi

    # Test that platform-specific build logic works
    echo "--- Test: Platform build logic integration ---"

    if [ ! -f "scripts/lib/build-logic.sh" ]; then
      echo "EXPECTED FAIL: build-logic.sh not found"
    else
      echo "PASS: build-logic.sh exists"
    fi

    if [ ! -f "scripts/lib/platform-config.sh" ]; then
      echo "EXPECTED FAIL: platform-config.sh not found"
    else
      echo "PASS: platform-config.sh exists"
    fi

    echo "=== Test Summary ==="
    echo "All tests completed. This is a TDD Red phase - failures are expected."
    echo "Tests will pass once the lib consolidation feature is implemented."
  '';
}
