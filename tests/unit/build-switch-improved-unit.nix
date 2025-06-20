{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
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

  # Test 2: Color constants definition
  ${testHelpers.testSubsection "Color Constants"}

  ${testHelpers.assertContains "${buildSwitchScript}" "GREEN=" "GREEN color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "YELLOW=" "YELLOW color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "RED=" "RED color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "BLUE=" "BLUE color constant defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "NC=" "No color constant defined"}

  # Test 3: Helper functions definition
  ${testHelpers.testSubsection "Helper Functions"}

  ${testHelpers.assertContains "${buildSwitchScript}" "print_step()" "print_step function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "print_success()" "print_success function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "print_error()" "print_error function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "show_progress()" "show_progress function defined"}

  # Test 4: Verbose flag handling
  ${testHelpers.testSubsection "Verbose Flag Handling"}

  ${testHelpers.assertContains "${buildSwitchScript}" "VERBOSE=false" "VERBOSE variable initialized"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\\-\\-verbose" "verbose flag check implemented"}
  ${testHelpers.assertContains "${buildSwitchScript}" "VERBOSE=true" "verbose flag setting implemented"}

  # Test 5: Progress indicator format
  ${testHelpers.testSubsection "Progress Indicator Format"}

  ${testHelpers.assertContains "${buildSwitchScript}" "🏗️  Dotfiles Build & Switch" "progress indicator with emoji"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\[\$step/\$total\]" "step counter format"}

  # Test 6: Error handling patterns
  ${testHelpers.testSubsection "Error Handling"}

  ${testHelpers.assertContains "${buildSwitchScript}" "2>/dev/null" "error suppression for non-verbose mode"}
  ${testHelpers.assertContains "${buildSwitchScript}" "Run with \\-\\-verbose for details" "verbose suggestion in error messages"}
  ${testHelpers.assertContains "${buildSwitchScript}" "exit 1" "proper exit code on failure"}

  # Test 7: Success indicators
  ${testHelpers.testSubsection "Success Indicators"}

  ${testHelpers.assertContains "${buildSwitchScript}" "✅" "success emoji used"}
  ${testHelpers.assertContains "${buildSwitchScript}" "System configuration built" "build success message"}
  ${testHelpers.assertContains "${buildSwitchScript}" "New generation activated" "switch success message"}
  ${testHelpers.assertContains "${buildSwitchScript}" "Cleanup complete" "cleanup success message"}

  # Test 8: Script content validation
  ${testHelpers.testSubsection "Script Content"}

  ${testHelpers.assertContains "${buildSwitchScript}" "🏗️.*Build.*Switch" "build progress pattern"}
  ${testHelpers.assertContains "${buildSwitchScript}" "💡.*verbose" "verbose hint pattern"}
  ${testHelpers.assertContains "${buildSwitchScript}" "Building system configuration" "build step message"}
  ${testHelpers.assertContains "${buildSwitchScript}" "Switching to new generation" "switch step message"}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved Unit Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All unit tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
