{ pkgs, lib, src }:

let
  # Test for Makefile usability improvements (USER auto-detection)
  testScript = pkgs.writeShellScript "test-makefile-usability" ''
    set -euo pipefail

    echo "=== Testing Makefile usability improvements ==="

    MAKEFILE="${src}/Makefile"
    FAILED_TESTS=()

    # Test 1: Check for automatic USER variable detection
    echo "🔍 Testing for automatic USER variable detection..."

    if grep -q "USER.*?=.*whoami\|USER.*:=.*whoami" "$MAKEFILE"; then
      echo "✅ PASS: Makefile has automatic USER detection"
    else
      echo "❌ FAIL: Makefile doesn't automatically detect USER"
      FAILED_TESTS+=("Missing automatic USER detection")
    fi

    # Test 2: Check for helpful error messages when USER is not set
    echo ""
    echo "🔍 Testing for helpful USER error messages..."

    if grep -q "USER.*not.*set\|Please.*set.*USER" "$MAKEFILE"; then
      echo "✅ PASS: Makefile has helpful USER error messages"
    else
      echo "❌ FAIL: Makefile should provide helpful error when USER not set"
      FAILED_TESTS+=("Missing helpful USER error messages")
    fi

    # Test 3: Check for consistent USER usage across targets
    echo ""
    echo "🔍 Testing for consistent USER usage..."

    # Check for check-user dependency in important targets
    targets_with_check_user=$(grep -E "^(build|switch).*: check-user" "$MAKEFILE" | wc -l)
    important_targets=$(grep -E "^(build|switch):" "$MAKEFILE" | wc -l)

    echo "Important targets: $important_targets"
    echo "Targets with check-user: $targets_with_check_user"

    if [[ $targets_with_check_user -ge $important_targets ]]; then
      echo "✅ PASS: Consistent USER usage across targets"
    else
      echo "❌ FAIL: Some important targets missing check-user dependency"
      FAILED_TESTS+=("Inconsistent USER usage")
    fi

    # Test 4: Check for user-friendly target descriptions in help
    echo ""
    echo "🔍 Testing for user-friendly help descriptions..."

    if grep -q "help:" "$MAKEFILE" && grep -A10 "help:" "$MAKEFILE" | grep -q "echo"; then
      echo "✅ PASS: Makefile has help target with descriptions"
    else
      echo "❌ FAIL: Makefile should have helpful target descriptions"
      FAILED_TESTS+=("Missing helpful target descriptions")
    fi

    echo ""
    echo "=== Test Results ==="
    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "  - $test"
      done
      echo "Makefile usability issues found!"
      exit 1
    else
      echo "✅ All Makefile usability tests passed!"
      exit 0
    fi
  '';

in
pkgs.runCommand "makefile-usability-test"
{
  buildInputs = [ pkgs.bash pkgs.gnugrep pkgs.coreutils ];
} ''
  echo "Running Makefile usability tests..."
  ${testScript}

  echo "Makefile usability test completed"
  touch $out
''
