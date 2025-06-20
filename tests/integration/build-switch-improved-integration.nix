{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-improved-integration-test"
{
  buildInputs = with pkgs; [ bash coreutils nix git findutils gnugrep ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Improved Integration Tests"}

  # Test 1: Script integration with environment
  ${testHelpers.testSubsection "Environment Integration"}

  ${testHelpers.assertExists "${buildSwitchScript}" "build-switch script exists"}
  ${testHelpers.assertCommand "[ -x '${buildSwitchScript}' ]" "build-switch script is executable"}

  # Test 2: User variable handling
  ${testHelpers.testSubsection "User Variable Handling"}

  export USER="testuser"
  ${testHelpers.assertTrue ''[ "$USER" = "testuser" ]'' "USER variable properly set"}

  # Test 3: Script content verification
  ${testHelpers.testSubsection "Script Content Verification"}

  ${testHelpers.assertContains "${buildSwitchScript}" "SYSTEM_TYPE=" "system type variable defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "FLAKE_SYSTEM=" "flake system variable defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "NIXPKGS_ALLOW_UNFREE=1" "unfree packages enabled"}

  # Test 4: Function definitions
  ${testHelpers.testSubsection "Function Definitions"}

  ${testHelpers.assertContains "${buildSwitchScript}" "print_step()" "print_step function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "print_success()" "print_success function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "print_error()" "print_error function defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "show_progress()" "show_progress function defined"}

  # Test 5: Build process integration
  ${testHelpers.testSubsection "Build Process Integration"}

  ${testHelpers.assertContains "${buildSwitchScript}" "nix.*build.*--impure" "nix build command present"}
  ${testHelpers.assertContains "${buildSwitchScript}" "darwin-rebuild.*switch" "darwin-rebuild command present"}
  ${testHelpers.assertContains "${buildSwitchScript}" "sudo.*USER=" "sudo with USER variable"}

  # Test 6: Cleanup integration
  ${testHelpers.testSubsection "Cleanup Integration"}

  ${testHelpers.assertContains "${buildSwitchScript}" "unlink.*result" "result cleanup command"}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved Integration Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All integration tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
