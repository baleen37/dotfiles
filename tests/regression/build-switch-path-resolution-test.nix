{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-path-resolution-regression-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Path Resolution Regression Tests"}

  # Test 1: Current hardcoded path issue (this should FAIL initially)
  ${testHelpers.testSubsection "Hardcoded REBUILD_COMMAND_PATH Issue"}

  # Create a clean test environment without result symlink
  mkdir -p test_workspace
  cd test_workspace

  # Copy the build-switch script to test workspace
  cp "${buildSwitchScript}" ./build-switch-test
  chmod +x ./build-switch-test

  # Verify the script contains hardcoded path (current bug)
  ${testHelpers.assertContains "./build-switch-test" "./result/sw/bin/darwin-rebuild" "Script contains hardcoded path"}

  # Test 2: Path resolution without result symlink (should fail with current code)
  ${testHelpers.testSubsection "Path Resolution Scenarios"}

  # Scenario 1: No result symlink exists (current failure case)
  if [ -L "./result" ]; then
    rm -f ./result
  fi

  # Mock a scenario where darwin-rebuild is available in system PATH
  mkdir -p mock_bin
  echo '#!/bin/bash' > mock_bin/darwin-rebuild
  echo 'echo "mock darwin-rebuild called with: $@"' >> mock_bin/darwin-rebuild
  chmod +x mock_bin/darwin-rebuild
  export PATH="$(pwd)/mock_bin:$PATH"

  # This test documents the current broken behavior
  # With the current hardcoded path, this would fail
  echo "${testHelpers.colors.yellow}Testing current broken behavior (expected to expose the bug):${testHelpers.colors.reset}"

  # Extract REBUILD_COMMAND_PATH from the script
  EXTRACTED_PATH=$(grep 'REBUILD_COMMAND_PATH=' ./build-switch-test | head -1 | cut -d'"' -f2)
  echo "Extracted REBUILD_COMMAND_PATH: $EXTRACTED_PATH"

  # Test if the hardcoded path exists (it shouldn't in clean environment)
  if [ -f "$EXTRACTED_PATH" ]; then
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Bug not reproduced: hardcoded path unexpectedly exists"
    exit 1
  else
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Bug reproduced: hardcoded path does not exist as expected"
  fi

  # Test 3: Verify fallback paths are available
  ${testHelpers.testSubsection "Fallback Path Availability"}

  # Check if darwin-rebuild is available in PATH (should be via our mock)
  if command -v darwin-rebuild >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} darwin-rebuild available in PATH"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} darwin-rebuild not available in PATH"
    exit 1
  fi

  # Test the mock darwin-rebuild works
  MOCK_OUTPUT=$(darwin-rebuild test 2>&1)
  if echo "$MOCK_OUTPUT" | grep -q "mock darwin-rebuild called"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Mock darwin-rebuild responds correctly"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Mock darwin-rebuild failed to respond"
    exit 1
  fi

  # Test 4: Document expected fixed behavior
  ${testHelpers.testSubsection "Expected Fixed Behavior"}

  echo "${testHelpers.colors.blue}Expected fix: Script should try multiple paths in order:${testHelpers.colors.reset}"
  echo "1. ./result/sw/bin/darwin-rebuild (if exists)"
  echo "2. darwin-rebuild (from PATH)"
  echo "3. /run/current-system/sw/bin/darwin-rebuild (system fallback)"

  # This test will pass once we implement the fix
  # For now, we document what the fix should achieve
  echo "${testHelpers.colors.yellow}After fix: REBUILD_COMMAND_PATH should be 'darwin-rebuild' in this scenario${testHelpers.colors.reset}"

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Path Resolution Regression Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Regression test successfully reproduced the bug!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Fix implementation needed to resolve the hardcoded path issue${testHelpers.colors.reset}"

  touch $out
''
