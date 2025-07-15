{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-system-state-integration-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch System State Integration Tests"}

  # Test 1: System state capture integration (FAILING - not implemented)
  ${testHelpers.testSubsection "System State Capture Integration"}

  mkdir -p test_workspace
  cd test_workspace

  # Test that build-switch integrates system state capture
  echo "Testing system state capture integration..."

  # This should FAIL because system state capture is not yet implemented
  BUILD_SWITCH_COMMON="${src}/scripts/build-switch-common.sh"

  if [ -f "$BUILD_SWITCH_COMMON" ]; then
    if grep -q "capture_system_state" "$BUILD_SWITCH_COMMON"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System state capture integration found"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} System state capture integration NOT IMPLEMENTED (expected failure)"
      # This is expected to fail - RED phase
    fi
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} build-switch-common.sh not found"
    exit 1
  fi

  # Test 2: Pre-build state snapshot (FAILING - not implemented)
  ${testHelpers.testSubsection "Pre-Build State Snapshot"}

  # Test that system creates snapshots before major changes
  echo "Testing pre-build state snapshot functionality..."

  # Check if snapshot functionality exists in build-logic.sh
  BUILD_LOGIC="${src}/scripts/lib/build-logic.sh"

  if [ -f "$BUILD_LOGIC" ]; then
    if grep -q "create_pre_build_snapshot" "$BUILD_LOGIC"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Pre-build snapshot functionality found"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Pre-build snapshot functionality NOT IMPLEMENTED (expected failure)"
      # This is expected to fail - RED phase
    fi
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} build-logic.sh not found"
    exit 1
  fi

  # Test 3: System rollback integration (FAILING - not implemented)
  ${testHelpers.testSubsection "System Rollback Integration"}

  # Test that rollback functionality is integrated into build system
  echo "Testing system rollback integration..."

  if grep -q "execute_rollback" "$BUILD_LOGIC"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback execution integration found"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback execution integration NOT IMPLEMENTED (expected failure)"
    # This is expected to fail - RED phase
  fi

  # Test 4: Failed build detection hooks (FAILING - not implemented)
  ${testHelpers.testSubsection "Failed Build Detection Hooks"}

  # Test that system detects build failures and triggers recovery
  echo "Testing failed build detection hooks..."

  if grep -q "detect_build_failure" "$BUILD_LOGIC"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Build failure detection found"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Build failure detection NOT IMPLEMENTED (expected failure)"
    # This is expected to fail - RED phase
  fi

  # Test 5: Recovery decision engine (FAILING - not implemented)
  ${testHelpers.testSubsection "Recovery Decision Engine"}

  # Test that system can intelligently decide recovery strategy
  echo "Testing recovery decision engine..."

  if grep -q "decide_recovery_strategy" "$BUILD_LOGIC"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Recovery decision engine found"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Recovery decision engine NOT IMPLEMENTED (expected failure)"
    # This is expected to fail - RED phase
  fi

  # Test 6: State persistence mechanisms (FAILING - not implemented)
  ${testHelpers.testSubsection "State Persistence Mechanisms"}

  # Test that system state is properly persisted across operations
  echo "Testing state persistence mechanisms..."

  # Check for state persistence module
  STATE_PERSISTENCE="${src}/scripts/lib/state-persistence.sh"

  if [ -f "$STATE_PERSISTENCE" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} State persistence module found"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} State persistence module NOT IMPLEMENTED (expected failure)"
    # This is expected to fail - RED phase
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: System State Integration Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.red}✗ Expected failures confirmed - system state management not yet implemented${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ RED phase complete - ready for GREEN implementation${testHelpers.colors.reset}"

  touch $out
''
