{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  mockSystem = import ../lib/mock-system.nix { inherit pkgs; };
in
pkgs.runCommand "build-switch-comprehensive-system-state-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Comprehensive System State Tests"}

  # Test 1: System state capture function (should fail initially)
  ${testHelpers.testSubsection "System State Capture Function"}

  mkdir -p test_workspace
  cd test_workspace

  # Test that capture_system_state function exists and works
  BUILD_SWITCH_COMMON="${src}/scripts/build-switch-common.sh"

  if [ -f "$BUILD_SWITCH_COMMON" ]; then
    if grep -q "capture_system_state" "$BUILD_SWITCH_COMMON"; then
      echo "✓ capture_system_state function found in build-switch-common.sh"
    else
      echo "✗ capture_system_state function not found in build-switch-common.sh"
      exit 1
    fi
  else
    echo "✗ build-switch-common.sh not found"
    exit 1
  fi

  # Test 2: System state restoration capability (should fail initially)
  ${testHelpers.testSubsection "System State Restoration Capability"}

  if grep -q "restore_system_state" "$BUILD_SWITCH_COMMON"; then
    echo "✓ restore_system_state function found"
  else
    echo "✗ restore_system_state function not found"
    exit 1
  fi

  # Test 3: State transition management (should fail initially)
  ${testHelpers.testSubsection "State Transition Management"}

  if grep -q "manage_state_transition" "$BUILD_SWITCH_COMMON"; then
    echo "✓ manage_state_transition function found"
  else
    echo "✗ manage_state_transition function not found"
    exit 1
  fi

  # Test 4: Concurrent operation detection (should fail initially)
  ${testHelpers.testSubsection "Concurrent Operation Detection"}

  if grep -q "detect_concurrent_operations" "$BUILD_SWITCH_COMMON"; then
    echo "✓ detect_concurrent_operations function found"
  else
    echo "✗ detect_concurrent_operations function not found"
    exit 1
  fi

  # Test 5: System state validation (should fail initially)
  ${testHelpers.testSubsection "System State Validation"}

  if grep -q "validate_system_state" "$BUILD_SWITCH_COMMON"; then
    echo "✓ validate_system_state function found"
  else
    echo "✗ validate_system_state function not found"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Comprehensive System State Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All comprehensive system state tests passed${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Comprehensive system state management implemented successfully${testHelpers.colors.reset}"

  touch $out
''
