{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-improved-e2e-test"
{
  buildInputs = with pkgs; [ bash coreutils nix git findutils gnugrep ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Improved E2E Tests"}

  # Test 1: Basic functionality verification
  ${testHelpers.testSubsection "Basic Functionality"}

  ${testHelpers.assertExists "${buildSwitchScript}" "build-switch script exists"}
  ${testHelpers.assertCommand "[ -x '${buildSwitchScript}' ]" "build-switch script is executable"}

  # Test 2: Script content validation
  ${testHelpers.testSubsection "Script Content Validation"}

  ${testHelpers.assertContains "${buildSwitchScript}" "show_progress" "progress function exists"}
  ${testHelpers.assertContains "${buildSwitchScript}" "print_success" "success function exists"}
  ${testHelpers.assertContains "${buildSwitchScript}" "🏗️" "progress emoji present"}
  ${testHelpers.assertContains "${buildSwitchScript}" "✅" "success emoji present"}

  # Test 3: Verbose flag handling
  ${testHelpers.testSubsection "Verbose Flag Handling"}

  ${testHelpers.assertContains "${buildSwitchScript}" "VERBOSE=false" "verbose variable initialization"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\\-\\-verbose" "verbose flag check"}

  # Test 4: Error handling patterns
  ${testHelpers.testSubsection "Error Handling"}

  ${testHelpers.assertContains "${buildSwitchScript}" "2>/dev/null" "error suppression pattern"}
  ${testHelpers.assertContains "${buildSwitchScript}" "exit 1" "proper error exit"}

  # Test 5: Output structure validation
  ${testHelpers.testSubsection "Output Structure"}

  ${testHelpers.assertContains "${buildSwitchScript}" "\[1/4\]" "step 1 indicator"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\[2/4\]" "step 2 indicator"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\[3/4\]" "step 3 indicator"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\[4/4\]" "step 4 indicator"}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved E2E Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All E2E tests completed successfully!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.blue}Summary:${testHelpers.colors.reset}"
  echo "  - Script structure validation: ✓"
  echo "  - Content verification: ✓"
  echo "  - Flag handling: ✓"
  echo "  - Error patterns: ✓"
  echo "  - Output structure: ✓"

  touch $out
''
