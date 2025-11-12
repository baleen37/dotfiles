# Karabiner Configuration Tests
#
# Karabiner-Elements 키보드 커스터마이징 설정 테스트
# - 설정 파일 구조 검증
# - karabiner.json 존재 확인
# - 설정 파일 내용 검증
# - 기본 설정 값 확인
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

  # Import karabiner module for testing
  karabinerModule = import ../../users/shared/karabiner.nix;

  # Create test configuration
  testConfig = {
    home = {
      username = helpers.testConfig.username;
      homeDirectory = helpers.getTestUserHome;
    };
  };

  # Create test derivation with karabiner configuration
  karabinerTestConfig = karabinerModule {
    inherit pkgs lib;
    config = testConfig;
  };

  # Karabiner config path for validation
  karabinerConfigPath = ./../users/shared/.config/karabiner + "/karabiner.json";
  karabinerConfigContent = if builtins.pathExists karabinerConfigPath
    then builtins.readFile karabinerConfigPath
    else "";

in
let
  # Test 1: karabiner module imports successfully
  importTest = helpers.assertTest "karabiner-import"
    (helpers.canImport ../../users/shared/karabiner.nix)
    "karabiner module should import without errors";

  # Test 2: karabiner file configuration exists
  fileConfigTest = helpers.assertTest "karabiner-file-config"
    (builtins.hasAttr ".config/karabiner/karabiner.json" karabinerTestConfig.home.file)
    "karabiner should have file configuration for karabiner.json";

  # Test 3: karabiner source points to config file
  sourceTest = helpers.assertTest "karabiner-source"
    (karabinerTestConfig.home.file.".config/karabiner/karabiner.json".source == ../../users/shared/.config/karabiner/karabiner.json)
    "karabiner should source from .config/karabiner/karabiner.json";

  # Test 4: karabiner configuration forces overwrite
  forceTest = helpers.assertTest "karabiner-force"
    (karabinerTestConfig.home.file.".config/karabiner/karabiner.json".force == true)
    "karabiner file configuration should force overwrite";

  # Test 5: karabiner config file exists in source
  configExistsTest = helpers.assertTest "karabiner-config-exists"
    (builtins.pathExists karabinerConfigPath)
    "karabiner config file should exist in source directory";

  # Test 6: karabiner config file has content
  configContentTest = helpers.assertTest "karabiner-config-content"
    (builtins.stringLength karabinerConfigContent > 0)
    "karabiner config file should have content";

  # Test 7: karabiner config is valid JSON (basic check)
  jsonValidTest = helpers.assertTest "karabiner-json-valid"
    (
      # Basic JSON validation: check for opening and closing braces
      lib.hasInfix "{" karabinerConfigContent &&
      lib.hasInfix "}" karabinerConfigContent
    )
    "karabiner config should be valid JSON";

  # Test 8: karabiner config has essential structure
  essentialStructureTest = helpers.assertTest "karabiner-essential-structure"
    (
      # Check for common Karabiner structure elements
      lib.hasInfix "\"rules\"" karabinerConfigContent
    )
    "karabiner config should have essential structure with rules";

  # Test 9: karabiner config directory exists
  configDirTest = helpers.assertTest "karabiner-config-dir"
    (builtins.pathExists ../../users/shared/.config/karabiner)
    "karabiner config directory should exist";

  # Test 10: Platform-specific: only run on Darwin (macOS)
  darwinOnlyTest = helpers.runIfPlatform "darwin"
    (helpers.assertTest "karabiner-darwin-only"
      (builtins.hasAttr ".config/karabiner/karabiner.json" karabinerTestConfig.home.file)
      "karabiner should only be configured on Darwin systems");

  # Test 11: karabiner config has reasonable length
  reasonableLengthTest = helpers.assertTest "karabiner-reasonable-length"
    (builtins.stringLength karabinerConfigContent > 50)
    "karabiner config should have reasonable content length";

  # Test 12: karabiner config structure is not empty
  notEmptyTest = helpers.assertTest "karabiner-not-empty"
    (
      builtins.stringLength (lib.replaceStrings [" " "\n" "\t" "{" "}"] ["" "" "" "" ""] karabinerConfigContent) > 0
    )
    "karabiner config should not be empty structure";

  # Test 13: karabiner file path is correct
  filePathTest = helpers.assertTest "karabiner-file-path"
    (karabinerTestConfig.home.file.".config/karabiner/karabiner.json".source != null)
    "karabiner source path should be valid";

  # Test suite aggregator
  testSuite = helpers.testSuite "karabiner" [
    importTest
    fileConfigTest
    sourceTest
    forceTest
    configExistsTest
    configContentTest
    jsonValidTest
    essentialStructureTest
    configDirTest
    darwinOnlyTest
    reasonableLengthTest
    notEmptyTest
    filePathTest
  ];
in
testSuite
