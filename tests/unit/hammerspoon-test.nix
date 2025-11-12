# Hammerspoon Configuration Tests
#
# Hammerspoon macOS 자동화 설정 테스트
# - 설정 파일 구조 검증
# - 필수 파일 존재 확인
# - Spoons 설정 확인
# - Lua 스크립트 유효성 검사
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

  # Import hammerspoon module for testing
  hammerspoonModule = import ../../users/shared/hammerspoon.nix;

  # Create test configuration
  testConfig = {
    home = {
      username = helpers.testConfig.username;
      homeDirectory = helpers.getTestUserHome;
    };
  };

  # Create test derivation with hammerspoon configuration
  hammerspoonTestConfig = hammerspoonModule {
    config = testConfig;
  };

  # Check if Lua syntax is valid (basic check)
  validateLuaSyntax = luaCode:
    let
      # Basic validation: check for balanced quotes and brackets
      hasBalancedQuotes =
        let
          singleQuoteCount = lib.stringLength (lib.replaceStrings ["'"] [""] luaCode) - lib.stringLength (lib.replaceStrings [""] ["'"] luaCode);
          doubleQuoteCount = lib.stringLength (lib.replaceStrings ["\""] [""] luaCode) - lib.stringLength (lib.replaceStrings [""] ["\""] luaCode);
        in
        (singleQuoteCount % 2) == 0 && (doubleQuoteCount % 2) == 0;

      hasBasicStructure =
        lib.hasInfix "hs.loadSpoon" luaCode &&
        lib.hasInfix "require(" luaCode;
    in
    hasBalancedQuotes && hasBasicStructure;

in
{
  # Test 1: hammerspoon module imports successfully
  importTest = helpers.assertTest "hammerspoon-import"
    (helpers.canImport ../../users/shared/hammerspoon.nix)
    "hammerspoon module should import without errors";

  # Test 2: hammerspoon file configuration exists
  fileConfigTest = helpers.assertTest "hammerspoon-file-config"
    (builtins.hasAttr ".hammerspoon" hammerspoonTestConfig.home.file)
    "hammerspoon should have file configuration for .hammerspoon directory";

  # Test 3: hammerspoon source points to config directory
  sourceTest = helpers.assertTest "hammerspoon-source"
    (hammerspoonTestConfig.home.file.".hammerspoon".source == ./../users/shared/.config/hammerspoon)
    "hammerspoon should source from .config/hammerspoon directory";

  # Test 4: hammerspoon configuration is recursive
  recursiveTest = helpers.assertTest "hammerspoon-recursive"
    (hammerspoonTestConfig.home.file.".hammerspoon".recursive == true)
    "hammerspoon file configuration should be recursive";

  # Test 5: hammerspoon configuration forces overwrite
  forceTest = helpers.assertTest "hammerspoon-force"
    (hammerspoonTestConfig.home.file.".hammerspoon".force == true)
    "hammerspoon file configuration should force overwrite";

  # Test 6: init.lua file exists in source
  initExistsTest = helpers.assertTest "hammerspoon-init-exists"
    (builtins.pathExists (./../users/shared/.config/hammerspoon + "/init.lua"))
    "hammerspoon init.lua should exist in source directory";

  # Test 7: configApplications.lua file exists
  configAppsExistsTest = helpers.assertTest "hammerspoon-config-apps-exists"
    (builtins.pathExists (./../users/shared/.config/hammerspoon + "/configApplications.lua"))
    "hammerspoon configApplications.lua should exist in source directory";

  # Test 8: Spoons directory exists
  spoonsDirTest = helpers.assertTest "hammerspoon-spoons-dir"
    (builtins.pathExists (./../users/shared/.config/hammerspoon + "/Spoons"))
    "hammerspoon Spoons directory should exist";

  # Test 9: Hyper spoon exists
  hyperSpoonTest = helpers.assertTest "hammerspoon-hyper-spoon"
    (builtins.pathExists (./../users/shared/.config/hammerspoon + "/Spoons/Hyper.spoon/init.lua"))
    "hammerspoon Hyper spoon should exist";

  # Test 10: HyperModal spoon exists
  hyperModalSpoonTest = helpers.assertTest "hammerspoon-hypermodal-spoon"
    (builtins.pathExists (./../users/shared/.config/hammerspoon + "/Spoons/HyperModal.spoon/init.lua"))
    "hammerspoon HyperModal spoon should exist";

  # Test 11: init.lua has valid Lua syntax (basic check)
  initSyntaxTest =
    let
      initContent = builtins.readFile (./../users/shared/.config/hammerspoon + "/init.lua");
      syntaxCheck = validateLuaSyntax initContent;
    in
    helpers.assertTest "hammerspoon-init-syntax"
      syntaxCheck
      "hammerspoon init.lua should have valid Lua syntax";

  # Test 12: init.lua loads required spoons
  initSpoonLoadTest =
    let
      initContent = builtins.readFile (./../users/shared/.config/hammerspoon + "/init.lua");
    in
    helpers.assertTest "hammerspoon-spoon-loading"
      (
        lib.hasInfix "hs.loadSpoon('Hyper')" initContent &&
        lib.hasInfix "hs.loadSpoon('HyperModal')" initContent
      )
      "hammerspoon init.lua should load Hyper and HyperModal spoons";

  # Test 13: init.lua has hyper key configuration
  hyperKeyTest =
    let
      initContent = builtins.readFile (./../users/shared/.config/hammerspoon + "/init.lua");
    in
    helpers.assertTest "hammerspoon-hyper-key"
      (lib.hasInfix "F19" initContent)
      "hammerspoon should configure F19 as hyper key";

  # Test 14: configApplications.lua exists and is readable
  configAppsReadableTest =
    let
      configAppsPath = ./../users/shared/.config/hammerspoon + "/configApplications.lua";
      configAppsContent = if builtins.pathExists configAppsPath
        then builtins.readFile configAppsPath
        else "";
    in
    helpers.assertTest "hammerspoon-config-apps-readable"
      (builtins.pathExists configAppsPath && builtins.stringLength configAppsContent > 0)
      "hammerspoon configApplications.lua should be readable and non-empty";

  # Test 15: Essential hammerspoon structure is present
  structureTest = helpers.assertTest "hammerspoon-structure"
    (
      builtins.pathExists (./../users/shared/.config/hammerspoon) &&
      builtins.pathExists (./../users/shared/.config/hammerspoon + "/init.lua") &&
      builtins.pathExists (./../users/shared/.config/hammerspoon + "/Spoons")
    )
    "hammerspoon should have essential directory structure";

  # Test 16: Platform-specific: only run on Darwin (macOS)
  darwinOnlyTest = helpers.runIfPlatform "darwin"
    (helpers.assertTest "hammerspoon-darwin-only"
      (builtins.hasAttr ".hammerspoon" hammerspoonTestConfig.home.file)
      "hammerspoon should only be configured on Darwin systems");
}
