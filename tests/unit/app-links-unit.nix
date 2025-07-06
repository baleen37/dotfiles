# app-links-unit.nix - app-links.nix 모듈 유닛 테스트
# nixAppLinks 모듈의 기본 기능과 옵션 검증

{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  appLinksModule = "${src}/modules/darwin/app-links.nix";
  darwinConfig = "${src}/hosts/darwin/default.nix";
in
pkgs.runCommand "app-links-unit-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "App-Links Module Unit Tests"}

  # Test 1: Module structure and imports
  ${testHelpers.testSubsection "Module Structure"}

  ${testHelpers.assertExists "${appLinksModule}" "app-links.nix module exists"}
  ${testHelpers.assertContains "${appLinksModule}" "system.nixAppLinks" "module defines nixAppLinks option"}
  ${testHelpers.assertContains "${appLinksModule}" "mkEnableOption" "module uses mkEnableOption"}

  # Test 2: Configuration options validation
  ${testHelpers.testSubsection "Configuration Options"}

  ${testHelpers.assertContains "${appLinksModule}" "enable = mkEnableOption" "enable option defined"}
  ${testHelpers.assertContains "${appLinksModule}" "apps = mkOption" "apps option defined"}
  ${testHelpers.assertContains "${appLinksModule}" "types.listOf types.str" "apps option has correct type"}

  # Test 3: Script generation logic
  ${testHelpers.testSubsection "Script Generation"}

  ${testHelpers.assertContains "${appLinksModule}" "findNixApp" "findNixApp function defined"}
  ${testHelpers.assertContains "${appLinksModule}" "createAppLink" "createAppLink function defined"}
  ${testHelpers.assertContains "${appLinksModule}" "find /nix/store" "nix store search logic"}

  # Test 4: Activation script integration
  ${testHelpers.testSubsection "Activation Script"}

  ${testHelpers.assertContains "${appLinksModule}" "system.activationScripts.nixAppLinks" "activation script defined"}
  ${testHelpers.assertContains "${appLinksModule}" "mkIf cfg.enable" "conditional activation"}

  # Test 5: App finding logic
  ${testHelpers.testSubsection "App Finding Logic"}

  ${testHelpers.assertContains "${appLinksModule}" "*/Applications/*" "Applications folder priority search"}
  ${testHelpers.assertContains "${appLinksModule}" "sort -V" "version sorting for latest app"}
  ${testHelpers.assertContains "${appLinksModule}" "for path in" "iterative version selection"}

  # Test 6: Symbolic link creation
  ${testHelpers.testSubsection "Symbolic Link Creation"}

  ${testHelpers.assertContains "${appLinksModule}" "ln -sf" "symbolic link creation with force"}
  ${testHelpers.assertContains "${appLinksModule}" "/Applications/" "target Applications directory"}
  ${testHelpers.assertContains "${appLinksModule}" "rm -rf" "cleanup old links"}

  # Test 7: Error handling and validation
  ${testHelpers.testSubsection "Error Handling"}

  ${testHelpers.assertContains "${appLinksModule}" "if.*then" "conditional logic for error handling"}
  ${testHelpers.assertContains "${appLinksModule}" "not found" "error message for missing apps"}
  ${testHelpers.assertContains "${appLinksModule}" "2>/dev/null" "error output suppression"}

  # Test 8: User guidance and messaging
  ${testHelpers.testSubsection "User Guidance"}

  ${testHelpers.assertContains "${appLinksModule}" "Remember to grant" "user guidance message"}
  ${testHelpers.assertContains "${appLinksModule}" "Privacy & Security" "macOS settings guidance"}
  ${testHelpers.assertContains "${appLinksModule}" "Input Monitoring" "specific permission guidance"}

  # Test 9: Configuration examples and documentation
  ${testHelpers.testSubsection "Documentation"}

  ${testHelpers.assertContains "${appLinksModule}" "example =" "configuration example provided"}
  ${testHelpers.assertContains "${appLinksModule}" "description =" "option description provided"}
  ${testHelpers.assertContains "${appLinksModule}" "Karabiner-Elements.app" "example app provided"}

  # Test 10: Module import validation
  ${testHelpers.testSubsection "Module Import"}

  ${testHelpers.assertContains "${darwinConfig}" "app-links.nix" "module imported in darwin config"}
  ${testHelpers.assertContains "${darwinConfig}" "system.nixAppLinks" "module configured in darwin config"}

  # Test 11: Multiple app support
  ${testHelpers.testSubsection "Multiple Apps Support"}

  ${testHelpers.assertContains "${appLinksModule}" "concatMapStrings" "multiple apps iteration"}
  ${testHelpers.assertContains "${appLinksModule}" "cfg.apps" "apps list reference"}

  # Test 12: Platform-specific checks
  ${testHelpers.testSubsection "Platform Compatibility"}

  # This test runs only on Darwin since it's a Darwin-specific module
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin-specific module" ''
    echo "✓ Module is intended for Darwin platforms"
  ''}

  # Test 13: Configuration validation logic
  ${testHelpers.testSubsection "Configuration Validation"}

  ${testHelpers.assertContains "${appLinksModule}" "with lib" "lib utilities usage"}
  ${testHelpers.assertContains "${appLinksModule}" "mkIf" "conditional configuration"}

  # Test 14: String interpolation safety
  ${testHelpers.testSubsection "String Safety"}

  ${testHelpers.assertContains "${appLinksModule}" "appName" "app name parameter usage"}

  # Test 15: Progress and status messaging
  ${testHelpers.testSubsection "Status Messages"}

  ${testHelpers.assertContains "${appLinksModule}" "🔗" "linking status emoji"}
  ${testHelpers.assertContains "${appLinksModule}" "✅" "success status emoji"}
  ${testHelpers.assertContains "${appLinksModule}" "⚠️" "warning status emoji"}

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: App-Links Module Unit Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ All unit tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
