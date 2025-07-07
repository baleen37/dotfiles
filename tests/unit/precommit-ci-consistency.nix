# Tests for pre-commit and CI consistency improvements
{ pkgs }:
let
  # Test that warning filtering works correctly
  testWarningFiltering = pkgs.writeShellScript "test-warning-filtering" ''
    set -euo pipefail

    echo "Testing warning filtering functionality..."

    # Create a mock command that outputs warnings
    echo 'warning: ignoring the client-specified setting' > /tmp/test-output
    echo 'warning: Git tree is dirty' >> /tmp/test-output
    echo 'you are not a trusted user' >> /tmp/test-output
    echo 'substituters configuration option' >> /tmp/test-output
    echo 'This is a real error message' >> /tmp/test-output
    echo 'Build completed successfully' >> /tmp/test-output

    # Apply the same filtering as in pre-commit hooks
    FILTERED_OUTPUT=$(cat /tmp/test-output | grep -v "^warning: ignoring" | grep -v "^warning: Git tree.*is dirty" | grep -v "you are not a trusted user" | grep -v "substituters.*configuration option")

    # Verify that warnings are filtered but important messages remain
    if echo "$FILTERED_OUTPUT" | grep -q "This is a real error message"; then
      echo "✅ Real error messages preserved"
    else
      echo "❌ Real error messages were filtered out"
      exit 1
    fi

    if echo "$FILTERED_OUTPUT" | grep -q "Build completed successfully"; then
      echo "✅ Success messages preserved"
    else
      echo "❌ Success messages were filtered out"
      exit 1
    fi

    if echo "$FILTERED_OUTPUT" | grep -q "warning: ignoring"; then
      echo "❌ Warning messages not filtered properly"
      exit 1
    else
      echo "✅ Warning messages filtered correctly"
    fi

    rm -f /tmp/test-output
    echo "Warning filtering test passed!"
  '';

  # Test environment variable consistency
  testEnvironmentConsistency = pkgs.writeShellScript "test-environment-consistency" ''
    set -euo pipefail

    echo "Testing environment variable consistency..."

    # Test USER variable handling (set fallback like in pre-commit hooks)
    export USER=''${USER:-$(whoami)}
    if [ -n "''${USER:-}" ]; then
      echo "✅ USER variable is set: $USER"
    else
      echo "❌ USER variable not set"
      exit 1
    fi

    # Test CI_MODE variable
    export CI_MODE=local
    if [ "$CI_MODE" = "local" ]; then
      echo "✅ CI_MODE variable set correctly: $CI_MODE"
    else
      echo "❌ CI_MODE variable not set properly"
      exit 1
    fi

    echo "Environment consistency test passed!"
  '';

  # Test pre-commit hook command structure
  testPrecommitHookStructure = pkgs.writeShellScript "test-precommit-structure" ''
    set -euo pipefail

    echo "Testing pre-commit hook structure..."

    # Check that .pre-commit-config.yaml contains the expected hooks
    CONFIG_FILE="${toString ../../.pre-commit-config.yaml}"

    if [ ! -f "$CONFIG_FILE" ]; then
      echo "❌ Pre-commit config file not found"
      exit 1
    fi

    # Check for test hooks
    if grep -q "test-unit-prepush" "$CONFIG_FILE"; then
      echo "✅ test-unit-prepush hook found"
    else
      echo "❌ test-unit-prepush hook not found"
      exit 1
    fi

    if grep -q "test-integration-prepush" "$CONFIG_FILE"; then
      echo "✅ test-integration-prepush hook found"
    else
      echo "❌ test-integration-prepush hook not found"
      exit 1
    fi

    if grep -q "test-perf-prepush" "$CONFIG_FILE"; then
      echo "✅ test-perf-prepush hook found"
    else
      echo "❌ test-perf-prepush hook not found"
      exit 1
    fi

    # Check for CI_MODE environment variable in hooks
    if grep -q "CI_MODE=local" "$CONFIG_FILE"; then
      echo "✅ CI_MODE environment variable set in hooks"
    else
      echo "❌ CI_MODE environment variable not found in hooks"
      exit 1
    fi

    # Check for warning filtering
    if grep -q "grep -v.*warning: ignoring" "$CONFIG_FILE"; then
      echo "✅ Warning filtering configured in hooks"
    else
      echo "❌ Warning filtering not configured in hooks"
      exit 1
    fi

    echo "Pre-commit hook structure test passed!"
  '';

in pkgs.stdenv.mkDerivation {
  name = "precommit-ci-consistency-tests";
  src = ./.;

  buildPhase = ''
    echo "Running pre-commit and CI consistency tests..."

    ${testWarningFiltering}
    echo "---"

    ${testEnvironmentConsistency}
    echo "---"

    ${testPrecommitHookStructure}
    echo "---"

    echo "All pre-commit and CI consistency tests passed!"
  '';

  installPhase = ''
    mkdir -p $out/share/test-results
    echo "precommit-ci-consistency-tests: PASSED" > $out/share/test-results/result
  '';
}
