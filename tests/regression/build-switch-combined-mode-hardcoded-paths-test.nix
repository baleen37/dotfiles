{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildLogicScript = "${src}/scripts/lib/build-logic.sh";
in
pkgs.runCommand "build-switch-combined-mode-hardcoded-paths-regression-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Combined Mode Hardcoded Paths Regression Tests"}

  # Test 1: Check for hardcoded paths in error messages (current bug)
  ${testHelpers.testSubsection "Hardcoded Path Detection in Error Messages"}

  # Create a clean test environment
  mkdir -p test_workspace
  cd test_workspace

  # Copy the build-logic script to test workspace
  cp "${buildLogicScript}" ./build-logic-test.sh
  chmod +x ./build-logic-test.sh

  # Test 2: Verify REBUILD_COMMAND_PATH variable is used in error messages
  ${testHelpers.testSubsection "Combined Mode Error Message Uses Variable"}

  # Check that error messages use REBUILD_COMMAND_PATH instead of hardcoded paths
  if grep -q "sudo \''${REBUILD_COMMAND_PATH}" ./build-logic-test.sh; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Fixed: Combined mode error message uses REBUILD_COMMAND_PATH variable"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Error: Combined mode still uses hardcoded path"
    exit 1
  fi

  # Test 3: Verify no hardcoded paths remain in error messages
  ${testHelpers.testSubsection "No Hardcoded Paths in Error Messages"}

  # Check that no hardcoded paths remain in error messages (simplified check)
  if ! grep -q "sudo \./result/sw/bin/darwin-rebuild" ./build-logic-test.sh; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Fixed: No hardcoded paths found in error messages"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Error: Still found hardcoded paths in error messages"
    exit 1
  fi

  # Test 4: Document expected fix behavior
  ${testHelpers.testSubsection "Expected Fixed Behavior"}

  echo "${testHelpers.colors.blue}Expected fix: Error messages should use REBUILD_COMMAND_PATH variable instead of hardcoded paths${testHelpers.colors.reset}"
  echo "1. Combined mode error message should use \$REBUILD_COMMAND_PATH"
  echo "2. Legacy switch mode error message should use \$REBUILD_COMMAND_PATH"
  echo "3. Both error messages should work with fallback path resolution"

  # Test 5: Verify REBUILD_COMMAND_PATH variable is used in normal execution
  ${testHelpers.testSubsection "Variable Usage Verification"}

  # Check that REBUILD_COMMAND_PATH is properly used in main execution paths
  if grep -q "\$REBUILD_COMMAND_PATH" ./build-logic-test.sh || grep -q "\''${REBUILD_COMMAND_PATH}" ./build-logic-test.sh; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} REBUILD_COMMAND_PATH variable is used in main execution"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} REBUILD_COMMAND_PATH variable not found in main execution"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Combined Mode Hardcoded Paths Regression Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Regression test successfully identified hardcoded paths in error messages!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Fix implementation needed to replace hardcoded paths with REBUILD_COMMAND_PATH variable${testHelpers.colors.reset}"

  touch $out
''
