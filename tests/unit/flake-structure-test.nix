{ pkgs, lib, src }:

let
  # Test for code duplication and structure issues in flake.nix
  testScript = pkgs.writeShellScript "test-flake-structure" ''
    set -euo pipefail

    echo "=== Testing flake.nix structure and duplication ==="

    FLAKE_FILE="${src}/flake.nix"
    FAILED_TESTS=()

    # Test 1: Check for duplicate app definitions (mkLinuxApps vs mkDarwinApps)
    echo "🔍 Testing for duplicate app definitions..."

    # Count duplicate lines between mkLinuxApps and mkDarwinApps
    linux_apps=$(grep -A 30 "mkLinuxApps = system:" "$FLAKE_FILE" | grep -E "(apply|build|build-switch|test)" | wc -l)
    darwin_apps=$(grep -A 50 "mkDarwinApps = system:" "$FLAKE_FILE" | grep -E "(apply|build|build-switch|test)" | wc -l)

    echo "Linux apps: $linux_apps, Darwin apps: $darwin_apps"

    # If there's significant duplication (>80% similar), it's a problem
    if [[ $linux_apps -gt 5 && $darwin_apps -gt 5 ]]; then
      # Count actual duplicate patterns
      duplicate_count=$(grep -E "(apply|build|build-switch)" "$FLAKE_FILE" | sort | uniq -d | wc -l)
      if [[ $duplicate_count -gt 3 ]]; then
        echo "❌ FAIL: Significant code duplication detected ($duplicate_count duplicates)"
        FAILED_TESTS+=("Code duplication in app definitions")
      else
        echo "✅ PASS: Acceptable level of duplication"
      fi
    else
      echo "✅ PASS: No significant duplication"
    fi

    # Test 2: Check for extracted common functions
    echo ""
    echo "🔍 Testing for common function extraction..."

    if grep -q "mkCommonApps\|commonApps\|sharedApps" "$FLAKE_FILE"; then
      echo "✅ PASS: Common app functions extracted"
    else
      echo "❌ FAIL: No common app functions found"
      FAILED_TESTS+=("Missing common function extraction")
    fi

    # Test 3: Check for proper function organization
    echo ""
    echo "🔍 Testing for function organization..."

    # Count helper functions vs inline definitions
    helper_functions=$(grep -c "= system:" "$FLAKE_FILE" || true)
    inline_definitions=$(grep -c "type = \"app\"" "$FLAKE_FILE" || true)

    echo "Helper functions: $helper_functions, Inline definitions: $inline_definitions"

    # Should have good ratio of helper functions to inline definitions
    if [[ $helper_functions -gt 0 ]] && [[ $inline_definitions -lt 50 ]]; then
      echo "✅ PASS: Good function organization"
    else
      echo "❌ FAIL: Too many inline definitions, need more helper functions"
      FAILED_TESTS+=("Poor function organization")
    fi

    # Test 4: Check for DRY principle in test definitions
    echo ""
    echo "🔍 Testing for DRY principle in test definitions..."

    test_duplicates=$(grep -E "test-.*=" "$FLAKE_FILE" | cut -d= -f1 | sort | uniq -d | wc -l)
    if [[ $test_duplicates -eq 0 ]]; then
      echo "✅ PASS: No duplicate test definitions"
    else
      echo "❌ FAIL: Duplicate test definitions found"
      FAILED_TESTS+=("Duplicate test definitions")
    fi

    echo ""
    echo "=== Test Results ==="
    if [[ ''${#FAILED_TESTS[@]} -gt 0 ]]; then
      echo "❌ FAILED TESTS:"
      for test in "''${FAILED_TESTS[@]}"; do
        echo "  - $test"
      done
      echo "Flake structure issues found!"
      exit 1
    else
      echo "✅ All flake structure tests passed!"
      exit 0
    fi
  '';

in
pkgs.runCommand "flake-structure-test" {
  buildInputs = [ pkgs.bash pkgs.gnugrep pkgs.coreutils ];
} ''
  echo "Running flake structure tests..."
  ${testScript}

  echo "Flake structure test completed"
  touch $out
''
