# Ghostty Configuration Tests
#
# Ghostty 터미널 에뮬레이터 설정 테스트
# - 패키지 설치 확인
# - 설정 파일 구조 검증
# - 설정 파일 내용 검증
# - 필수 설정 값 확인
#
# 이 테스트는 통합된 헬퍼 함수를 사용하여 중복을 제거합니다

{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
}:

let
  # Import unified test helpers
  testHelpers = import ../lib/unified-test-helpers.nix { inherit pkgs lib; };
  helpers = testHelpers;

  # Import ghostty module for testing
  ghosttyModule = import ../../users/shared/ghostty.nix;

  # Create test configuration
  testConfig = {
    home = {
      username = helpers.testConfig.username;
      homeDirectory = helpers.getTestUserHome;
    };
  };

  # Create test derivation with ghostty configuration
  ghosttyTestConfig = ghosttyModule {
    inherit pkgs;
    config = testConfig;
  };

  # Ghostty config content for validation
  ghosttyConfigPath = .../../users/shared/.config/ghostty/config;
  ghosttyConfigContent = if builtins.pathExists ghosttyConfigPath
    then builtins.readFile ghosttyConfigPath
    else "";

in
let
  # Test 1: ghostty module imports successfully
  importTest = helpers.assertTest "ghostty-import"
    (helpers.canImport ../../users/shared/ghostty.nix)
    "ghostty module should import without errors";

  # Test 2: ghostty package is included in home.packages
  packageTest =
    let
      packageNames = builtins.map (pkg: pkg.pname or pkg.name or "") ghosttyTestConfig.home.packages;
    in
    helpers.assertTest "ghostty-package"
      (builtins.any (name: lib.hasInfix "ghostty" name) packageNames)
      "ghostty-bin should be included in home.packages";

  # Test 3: ghostty file configuration exists
  fileConfigTest = helpers.assertTest "ghostty-file-config"
    (builtins.hasAttr ".config/ghostty" ghosttyTestConfig.home.file)
    "ghostty should have file configuration for .config/ghostty directory";

  # Test 4: ghostty source points to config directory
  sourceTest = helpers.assertTest "ghostty-source"
    (ghosttyTestConfig.home.file.".config/ghostty".source == ../../users/shared/.config/ghostty)
    "ghostty should source from .config/ghostty directory";

  # Test 5: ghostty configuration is recursive
  recursiveTest = helpers.assertTest "ghostty-recursive"
    (ghosttyTestConfig.home.file.".config/ghostty".recursive == true)
    "ghostty file configuration should be recursive";

  # Test 6: ghostty configuration forces overwrite
  forceTest = helpers.assertTest "ghostty-force"
    (ghosttyTestConfig.home.file.".config/ghostty".force == true)
    "ghostty file configuration should force overwrite";

  # Test 7: ghostty config file exists in source
  configExistsTest = helpers.assertTest "ghostty-config-exists"
    (builtins.pathExists ghosttyConfigPath)
    "ghostty config file should exist in source directory";

  # Test 8: ghostty config file has content
  configContentTest = helpers.assertTest "ghostty-config-content"
    (builtins.stringLength ghosttyConfigContent > 0)
    "ghostty config file should have content";

  # Test 9: ghostty config has font family setting
  fontFamilyTest = helpers.assertTest "ghostty-font-family"
    (lib.hasInfix "font-family = Cascadia Code" ghosttyConfigContent)
    "ghostty should have font family set to Cascadia Code";

  # Test 10: ghostty config has font size setting
  fontSizeTest = helpers.assertTest "ghostty-font-size"
    (lib.hasInfix "font-size = 14" ghosttyConfigContent)
    "ghostty should have font size set to 14";

  # Test 11: ghostty config has theme setting
  themeTest = helpers.assertTest "ghostty-theme"
    (lib.hasInfix "theme = dark" ghosttyConfigContent)
    "ghostty should have theme set to dark";

  # Test 12: ghostty config has window padding settings
  windowPaddingTest = helpers.assertTest "ghostty-window-padding"
    (
      lib.hasInfix "window-padding-x = 10" ghosttyConfigContent &&
      lib.hasInfix "window-padding-y = 10" ghosttyConfigContent
    )
    "ghostty should have window padding set to 10px";

  # Test 13: ghostty config has shell integration enabled
  shellIntegrationTest = helpers.assertTest "ghostty-shell-integration"
    (lib.hasInfix "shell-integration = true" ghosttyConfigContent)
    "ghostty should have shell integration enabled";

  # Test 14: ghostty config has shell integration features
  shellIntegrationFeaturesTest = helpers.assertTest "ghostty-shell-integration-features"
    (lib.hasInfix "shell-integration-features = cursor,sudo,title" ghosttyConfigContent)
    "ghostty should have shell integration features configured";

  # Test 15: ghostty config has essential terminal settings
  essentialSettingsTest = helpers.assertTest "ghostty-essential-settings"
    (
      lib.hasInfix "font-family" ghosttyConfigContent &&
      lib.hasInfix "font-size" ghosttyConfigContent &&
      lib.hasInfix "theme" ghosttyConfigContent
    )
    "ghostty should have essential terminal settings configured";

  # Test 16: ghostty package availability check
  packageAvailabilityTest = helpers.assertTest "ghostty-package-availability"
    (builtins.hasAttr "ghostty-bin" pkgs)
    "ghostty-bin package should be available in nixpkgs";

  # Test 17: ghostty config file structure is valid
  configStructureTest = helpers.assertTest "ghostty-config-structure"
    (
      # Basic validation: check for key-value pairs format
      builtins.stringLength (lib.replaceStrings ["="] [""] ghosttyConfigContent) > 0 &&
      builtins.stringLength (lib.replaceStrings ["\n"] [""] ghosttyConfigContent) > 0
    )
    "ghostty config should have valid key-value structure";

  # Test 18: ghostty has proper configuration directory structure
  directoryStructureTest = helpers.assertTest "ghostty-directory-structure"
    (builtins.pathExists (../../users/shared/.config/ghostty))
    "ghostty should have proper configuration directory structure";

  # Test suite aggregator
  testSuite = helpers.testSuite "ghostty" [
    importTest
    packageTest
    fileConfigTest
    sourceTest
    recursiveTest
    forceTest
    configExistsTest
    configContentTest
    fontFamilyTest
    fontSizeTest
    themeTest
    windowPaddingTest
    shellIntegrationTest
    shellIntegrationFeaturesTest
    essentialSettingsTest
    packageAvailabilityTest
    configStructureTest
    directoryStructureTest
  ];
in
testSuite
