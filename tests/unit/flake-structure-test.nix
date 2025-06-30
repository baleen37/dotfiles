{ pkgs, lib, src, flake ? null }:

let
  # Test for code duplication and structure issues in flake.nix
  testScript = pkgs.writeShellScript "test-flake-structure" ''
    set -euo pipefail

    echo "=== Testing flake.nix structure and modularity ==="

    FLAKE_FILE="${src}/flake.nix"
    FAILED_TESTS=()

    # Test 1: Check for modular structure
    echo "🔍 Testing for modular structure..."

    # Check if flake imports modular components
    if grep -q "import ./lib/flake-config.nix" "$FLAKE_FILE" && \
       grep -q "import ./lib/system-configs.nix" "$FLAKE_FILE" && \
       grep -q "import ./lib/check-builders.nix" "$FLAKE_FILE"; then
      echo "✅ PASS: Flake uses modular structure"
    else
      echo "❌ FAIL: Flake should use modular imports"
      FAILED_TESTS+=("Missing modular imports")
    fi

    # Test 2: Check that flake.nix is concise
    echo ""
    echo "🔍 Testing flake.nix conciseness..."

    line_count=$(wc -l < "$FLAKE_FILE")
    echo "Flake.nix has $line_count lines"

    if [[ $line_count -lt 100 ]]; then
      echo "✅ PASS: Flake.nix is concise (<100 lines)"
    else
      echo "❌ FAIL: Flake.nix is too long (>100 lines)"
      FAILED_TESTS+=("Flake.nix should be more concise")
    fi

    # Test 3: Check for proper module separation
    echo ""
    echo "🔍 Testing module separation..."

    # Check that app configurations are in separate module
    if grep -q "mkAppConfigurations" "$FLAKE_FILE" && \
       [[ -f "${src}/lib/system-configs.nix" ]] && \
       grep -q "mkLinuxApps\|mkDarwinApps" "${src}/lib/system-configs.nix"; then
      echo "✅ PASS: App configurations are properly modularized"
    else
      echo "❌ FAIL: App configurations should be in separate modules"
      FAILED_TESTS+=("App configurations not properly modularized")
    fi

    # Test 4: Check that checks are in separate module
    echo ""
    echo "🔍 Testing check modularization..."

    if [[ -f "${src}/lib/check-builders.nix" ]] && \
       grep -q "mkChecks" "${src}/lib/check-builders.nix"; then
      echo "✅ PASS: Checks are properly modularized"
    else
      echo "❌ FAIL: Checks should be in separate module"
      FAILED_TESTS+=("Checks not properly modularized")
    fi

    # Test 5: Check that flake doesn't have inline app definitions
    echo ""
    echo "🔍 Testing for inline definitions..."

    inline_apps=$(grep -c "type = \"app\"" "$FLAKE_FILE" || true)
    if [[ $inline_apps -eq 0 ]]; then
      echo "✅ PASS: No inline app definitions in flake.nix"
    else
      echo "❌ FAIL: Flake.nix contains inline app definitions"
      FAILED_TESTS+=("Inline app definitions should be in modules")
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
pkgs.runCommand "flake-structure-test"
{
  buildInputs = [ pkgs.bash pkgs.gnugrep pkgs.coreutils ];
} ''
  echo "Running flake structure tests..."
  ${testScript}
  echo "Test completed successfully"
  touch $out
''
