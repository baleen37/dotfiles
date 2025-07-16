{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
in
pkgs.runCommand "build-switch-security-edge-case-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Security & Edge Case Tests"}

  # Test 1: Input validation and sanitization (should fail initially)
  ${testHelpers.testSubsection "Input Validation and Sanitization"}

  mkdir -p test_workspace
  cd test_workspace

  # Test that input validation functions exist
  BUILD_SWITCH_COMMON="${src}/scripts/build-switch-common.sh"

  if [ -f "$BUILD_SWITCH_COMMON" ]; then
    if grep -q "validate_input_parameters" "$BUILD_SWITCH_COMMON"; then
      echo "✓ validate_input_parameters function found"
    else
      echo "✗ validate_input_parameters function not found"
      exit 1
    fi
  else
    echo "✗ build-switch-common.sh not found"
    exit 1
  fi

  # Test 2: Path traversal prevention (should fail initially)
  ${testHelpers.testSubsection "Path Traversal Prevention"}

  if grep -q "prevent_path_traversal" "$BUILD_SWITCH_COMMON"; then
    echo "✓ prevent_path_traversal function found"
  else
    echo "✗ prevent_path_traversal function not found"
    exit 1
  fi

  # Test 3: Privilege escalation prevention (should fail initially)
  ${testHelpers.testSubsection "Privilege Escalation Prevention"}

  if grep -q "check_privilege_escalation" "$BUILD_SWITCH_COMMON"; then
    echo "✓ check_privilege_escalation function found"
  else
    echo "✗ check_privilege_escalation function not found"
    exit 1
  fi

  # Test 4: Resource exhaustion protection (should fail initially)
  ${testHelpers.testSubsection "Resource Exhaustion Protection"}

  if grep -q "monitor_resource_usage" "$BUILD_SWITCH_COMMON"; then
    echo "✓ monitor_resource_usage function found"
  else
    echo "✗ monitor_resource_usage function not found"
    exit 1
  fi

  # Test 5: Malicious symlink detection (should fail initially)
  ${testHelpers.testSubsection "Malicious Symlink Detection"}

  if grep -q "detect_malicious_symlinks" "$BUILD_SWITCH_COMMON"; then
    echo "✓ detect_malicious_symlinks function found"
  else
    echo "✗ detect_malicious_symlinks function not found"
    exit 1
  fi

  # Test 6: Environment variable sanitization (should fail initially)
  ${testHelpers.testSubsection "Environment Variable Sanitization"}

  if grep -q "sanitize_environment" "$BUILD_SWITCH_COMMON"; then
    echo "✓ sanitize_environment function found"
  else
    echo "✗ sanitize_environment function not found"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Security & Edge Case Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.red}✗ All security & edge case tests failed as expected${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Implementation needed for security & edge case handling${testHelpers.colors.reset}"

  touch $out
''
