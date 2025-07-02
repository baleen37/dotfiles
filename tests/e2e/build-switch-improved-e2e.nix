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

  # Test 2: Platform-specific configuration
  ${testHelpers.testSubsection "Platform Configuration"}

  ${testHelpers.assertContains "${buildSwitchScript}" "aarch64-darwin" "correct system type"}
  ${testHelpers.assertContains "${buildSwitchScript}" "darwinConfigurations" "correct flake path"}
  ${testHelpers.assertContains "${buildSwitchScript}" "darwin-rebuild" "correct rebuild command"}

  # Test 3: Integration patterns
  ${testHelpers.testSubsection "Integration Patterns"}

  ${testHelpers.assertContains "${buildSwitchScript}" "build-switch-common.sh" "common script integration"}
  ${testHelpers.assertContains "${buildSwitchScript}" "execute_build_switch" "main execution function"}

  # Test 4: Environment setup
  ${testHelpers.testSubsection "Environment Setup"}

  ${testHelpers.assertContains "${buildSwitchScript}" "NIXPKGS_ALLOW_UNFREE=1" "unfree packages enabled"}
  ${testHelpers.assertContains "${buildSwitchScript}" "SCRIPT_DIR=" "script directory resolution"}

  # Test 5: Workflow structure validation
  ${testHelpers.testSubsection "Workflow Structure"}

  ${testHelpers.assertContains "${buildSwitchScript}" "PROJECT_ROOT=" "project root detection"}
  ${testHelpers.assertContains "${buildSwitchScript}" "\\\$@" "argument forwarding"}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Build-Switch Improved E2E Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All E2E tests completed successfully!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.blue}Summary:${testHelpers.colors.reset}"
  echo "  - Script structure validation: ✓"
  echo "  - Platform configuration: ✓"
  echo "  - Integration patterns: ✓"
  echo "  - Environment setup: ✓"
  echo "  - Workflow structure: ✓"

  touch $out
''
