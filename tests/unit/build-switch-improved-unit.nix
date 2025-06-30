{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
  buildSwitchCommon = "${src}/scripts/build-switch-common.sh";
in
pkgs.runCommand "build-switch-improved-unit-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Improved Unit Tests"}

  # Test 1: Script structure and basic functionality
  ${testHelpers.testSubsection "Script Structure"}

  ${testHelpers.assertExists "${buildSwitchScript}" "build-switch script exists"}
  ${testHelpers.assertCommand "[ -x '${buildSwitchScript}' ]" "build-switch script is executable"}

  # Test 2: Color constants definition (check in common script)
  ${testHelpers.testSubsection "Color Constants"}

  ${testHelpers.assertContains "${buildSwitchCommon}" "GREEN=" "GREEN color constant defined"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "YELLOW=" "YELLOW color constant defined"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "RED=" "RED color constant defined"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "BLUE=" "BLUE color constant defined"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "NC=" "No color constant defined"}

  # Test 3: Helper functions definition (check in common script)
  ${testHelpers.testSubsection "Helper Functions"}

  ${testHelpers.assertContains "${buildSwitchCommon}" "print_step()" "print_step function defined"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "print_success()" "print_success function defined"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "print_error()" "print_error function defined"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "show_progress()" "show_progress function defined"}

  # Test 4: Verbose flag handling (check in common script)
  ${testHelpers.testSubsection "Verbose Flag Handling"}

  ${testHelpers.assertContains "${buildSwitchCommon}" "VERBOSE=false" "VERBOSE variable initialized"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "\\-\\-verbose" "verbose flag check implemented"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "VERBOSE=true" "verbose flag setting implemented"}

  # Test 5: Progress indicator format (check in common script)
  ${testHelpers.testSubsection "Progress Indicator Format"}

  ${testHelpers.assertContains "${buildSwitchCommon}" "🏗️  Dotfiles Build & Switch" "progress indicator with emoji"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "\[\$step/\$total\]" "step counter format"}

  # Test 6: Error handling patterns (check in common script)
  ${testHelpers.testSubsection "Error Handling"}

  ${testHelpers.assertContains "${buildSwitchCommon}" "2>/dev/null" "error suppression for non-verbose mode"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "Run with \\-\\-verbose for details" "verbose suggestion in error messages"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "exit 1" "proper exit code on failure"}

  # Test 7: Success indicators (check in common script)
  ${testHelpers.testSubsection "Success Indicators"}

  ${testHelpers.assertContains "${buildSwitchCommon}" "✅" "success emoji used"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "System configuration built" "build success message"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "New generation activated" "switch success message"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "Cleanup complete" "cleanup success message"}

  # Test 8: Script content validation (check in common script)
  ${testHelpers.testSubsection "Script Content"}

  ${testHelpers.assertContains "${buildSwitchCommon}" "🏗️.*Build.*Switch" "build progress pattern"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "💡.*verbose" "verbose hint pattern"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "Building system configuration" "build step message"}
  ${testHelpers.assertContains "${buildSwitchCommon}" "Switching to new generation" "switch step message"}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved Unit Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All unit tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
