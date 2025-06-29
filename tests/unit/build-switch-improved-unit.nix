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

  # Test 2: Platform configuration
  ${testHelpers.testSubsection "Platform Configuration"}

  ${testHelpers.assertContains "${buildSwitchScript}" "SYSTEM_TYPE=" "System type defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "FLAKE_SYSTEM=" "Flake system defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "PLATFORM_TYPE=" "Platform type defined"}
  ${testHelpers.assertContains "${buildSwitchScript}" "REBUILD_COMMAND=" "Rebuild command defined"}

  # Test 3: Common script integration
  ${testHelpers.testSubsection "Common Script Integration"}

  ${testHelpers.assertContains "${buildSwitchScript}" "build-switch-common.sh" "Common script sourced"}
  ${testHelpers.assertContains "${buildSwitchScript}" "execute_build_switch" "Main function called"}

  # Test 4: Environment setup
  ${testHelpers.testSubsection "Environment Setup"}

  ${testHelpers.assertContains "${buildSwitchScript}" "NIXPKGS_ALLOW_UNFREE=1" "Unfree packages allowed"}
  ${testHelpers.assertContains "${buildSwitchScript}" "PROJECT_ROOT=" "Project root variable set"}

  # Test 5: Script structure validation
  ${testHelpers.testSubsection "Script Structure"}

  ${testHelpers.assertContains "${buildSwitchScript}" "#!/bin/sh -e" "Proper shebang with error handling"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\\\$@" "Arguments passed through"}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved Unit Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All unit tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
