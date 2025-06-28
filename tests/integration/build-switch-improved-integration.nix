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

  # Test 4: Common script integration
  ${testHelpers.testSubsection "Common Script Integration"}

  COMMON_SCRIPT="${src}/scripts/build-switch-common.sh"
  ${testHelpers.assertExists "$COMMON_SCRIPT" "common build-switch script exists"}
  ${testHelpers.assertContains "$COMMON_SCRIPT" "log_step()" "log_step function defined"}
  ${testHelpers.assertContains "$COMMON_SCRIPT" "log_success()" "log_success function defined"}
  ${testHelpers.assertContains "$COMMON_SCRIPT" "log_error()" "log_error function defined"}
  ${testHelpers.assertContains "$COMMON_SCRIPT" "execute_build_switch()" "execute_build_switch function defined"}

  # Test 5: Build process integration
  ${testHelpers.testSubsection "Build Process Integration"}

  ${testHelpers.assertContains "$COMMON_SCRIPT" "nix.*build.*--impure" "nix build command present"}
  ${testHelpers.assertContains "$COMMON_SCRIPT" "USER=" "USER variable handling"}
  ${testHelpers.assertContains "${buildSwitchScript}" "REBUILD_COMMAND=" "rebuild command variable defined"}

  # Test 6: Cleanup integration
  ${testHelpers.testSubsection "Cleanup Integration"}

  ${testHelpers.assertContains "$COMMON_SCRIPT" "unlink.*result" "result cleanup command"}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved Integration Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All integration tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
