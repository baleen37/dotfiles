# Unified Test Helper Functions
#
# 통합된 테스트 헬퍼 함수 모음으로 tests/lib/test-helpers.nix와 tests/e2e/helpers.nix의
# 중복을 제거하고 핵심 기능을 제공
{
  pkgs,
  lib,
  # Parameterized test configuration to eliminate external dependencies
  testConfig ? {
    username = "testuser";
    homeDirPrefix = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    platformSystem = {
      isDarwin = pkgs.stdenv.isDarwin;
      isLinux = pkgs.stdenv.isLinux;
    };
  },
}:

rec {
  # Core assertion helpers (from test-helpers.nix)

  # Basic assertion helper
  assertTest =
    name: condition: message:
    if condition then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL - ${message}"
        exit 1
      '';

  # File content validation check - tests usability, not just existence
  assertFileExists =
    name: derivation: path:
    let
      fullPath = "${derivation}/${path}";
      readResult = builtins.tryEval (builtins.readFile fullPath);
    in
    assertTest name (
      readResult.success && builtins.stringLength readResult.value > 0
    ) "File ${path} not readable or empty in derivation";

  # Attribute existence check
  assertHasAttr =
    name: attrName: set:
    assertTest name (builtins.hasAttr attrName set) "Attribute ${attrName} not found";

  # String contains check
  assertContains =
    name: needle: haystack:
    assertTest name (lib.hasInfix needle haystack) "${needle} not found in ${haystack}";

  # Import validation helpers (from e2e/helpers.nix)

  # 모듈 import 성공 여부 검증
  canImport =
    path:
    let
      result = builtins.tryEval (import path);
    in
    result.success;

  # 모듈 import 후 특정 조건 검증
  canImportWith =
    path: args:
    let
      result = builtins.tryEval (import path args);
    in
    result.success;

  # Platform-agnostic helpers (consolidated from both files)

  # Get user home directory in a platform-agnostic way
  getUserHomeDir = user: isDarwin:
    if isDarwin then "/Users/${user}" else "/home/${user}";

  # Get user home directory using current platform
  getCurrentPlatformUserHome = user: getUserHomeDir user testConfig.platformSystem.isDarwin;

  # Get current test user home directory
  getTestUserHome = getCurrentPlatformUserHome testConfig.username;

  # Package validation helpers

  # 패키지 리스트 검증 - 모든 패키지가 null이 아닌지 확인
  allPackagesExist = packages: builtins.all (pkg: pkg != null) packages;

  # Derivation builds successfully
  assertBuilds =
    name: drv:
    pkgs.runCommand "test-${name}-builds" { buildInputs = [ drv ]; } ''
      echo "Testing if ${drv.name} builds..."
      ${drv}/bin/* --version 2>/dev/null || echo "Version check not available"
      echo "✅ ${name}: Builds successfully"
      touch $out
    '';

  # Test creation helpers

  # Simple test helper to reduce boilerplate code
  mkTest =
    name: testLogic:
    pkgs.runCommand "test-${name}-results" { } ''
      echo "Running ${name}..."
      ${testLogic}
      echo "✅ ${name}: PASS"
      touch $out
    '';

  # Test suite aggregator
  testSuite =
    name: tests:
    pkgs.runCommand "test-suite-${name}" { } ''
      echo "Running test suite: ${name}"
      ${lib.concatMapStringsSep "\n" (t: "cat ${t}") tests}
      echo "✅ Test suite ${name}: All tests passed"
      touch $out
    '';

  # Configuration helpers

  # Create test configuration with parameterized user
  createTestUserConfig =
    additionalConfig:
    {
      home = {
        username = testConfig.username;
        homeDirectory = getTestUserHome;
      }
      // (additionalConfig.home or { });
    }
    // (additionalConfig.config or { });

  # Platform-conditional test execution
  runIfPlatform =
    platform: test:
    if platform == "darwin" && testConfig.platformSystem.isDarwin then
      test
    else if platform == "linux" && testConfig.platformSystem.isLinux then
      test
    else if platform == "any" then
      test
    # Create a placeholder test that reports platform skip
    else
      pkgs.runCommand "test-skipped-${platform}" { } ''
        echo "⏭️  Skipped (${platform}-only test on current platform)"
        touch $out
      '';

  # Constants (from e2e/helpers.nix)
  constants = {
    # 공통 테스트 사용자
    testUsers = [
      "baleen"
      "jito"
      "user"
      "runner"
      "ubuntu"
    ];

    # 필수 빌드 패키지
    requiredBuildPackages = [
      pkgs.git
      pkgs.nix
      pkgs.gnumake
    ];

    # 필수 개발 도구
    essentialDevTools = [
      pkgs.git
      pkgs.vim
      pkgs.zsh
      pkgs.tmux
      pkgs.gnumake
    ];

    # 필수 포맷팅 도구
    formattingTools = [
      pkgs.nixfmt-rfc-style
      pkgs.pre-commit
    ];

    # Home Manager 상태 버전
    stateVersion = "24.05";
  };

  # File structure validation helpers (behavioral)

  # 여러 경로 존재 여부 동시 검증
  allPathsExist =
    paths:
    builtins.all (
      path:
      let
        readResult = builtins.tryEval (builtins.readFile path);
      in
      readResult.success && builtins.stringLength readResult.value > 0
    ) paths;

  # 설정 디렉토리 구조 검증
  checkConfigStructure =
    basePath: requiredPaths:
    let
      fullPaths = builtins.map (p: "${basePath}/${p}") requiredPaths;
    in
    allPathsExist fullPaths;

  # Platform-specific helpers (consolidated from e2e/helpers.nix)

  # 플랫폼별 경로 검증 (behavioral)
  checkPlatformPath =
    darwinPath: linuxPath:
    if testConfig.platformSystem.isDarwin then
      let
        readResult = builtins.tryEval (builtins.readFile darwinPath);
      in
      readResult.success && builtins.stringLength readResult.value > 0
    else if testConfig.platformSystem.isLinux then
      let
        readResult = builtins.tryEval (builtins.readFile linuxPath);
      in
      readResult.success && builtins.stringLength readResult.value > 0
    else
      true;

  # 플랫폼별 모듈 import 검증
  checkPlatformModule =
    darwinModule: linuxModule:
    if testConfig.platformSystem.isDarwin then
      let
        result = builtins.tryEval (import darwinModule);
      in
      result.success
    else if testConfig.platformSystem.isLinux then
      let
        result = builtins.tryEval (import linuxModule);
      in
      result.success
    else
      true;

  # Backward compatibility aliases
  mkSimpleTest = mkTest;
}
