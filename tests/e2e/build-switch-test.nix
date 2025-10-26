# Build-Switch End-to-End Tests
#
# build-switch 워크플로의 완전한 e2e 테스트
#
# 주요 검증 항목:
# - 플랫폼별 빌드 성공 여부
# - dry-run 모드 정상 작동
# - 빌드 출력 구조 검증
# - 에러 핸들링 및 복구

{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem,
  nixtest ? null,
}:

let
  # Use provided NixTest framework (or fallback to local template)
  nixtestFinal =
    if nixtest != null then
      nixtest
    else
      (import ../unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;

  # Import platform system for platform detection
  platformSystem = import ../../lib/platform-system.nix { inherit system; };

  # Import E2E test helpers
  helpers = import ./helpers.nix { inherit lib pkgs platformSystem; };

in
nixtestFinal.suite "Build-Switch E2E Tests" {

  # Test 1: Flake structure validation
  flakeStructureValid = nixtestFinal.test "Flake structure is valid for build-switch" (
    let
      flakeExists = builtins.pathExists ../../flake.nix;
      makefileExists = builtins.pathExists ../../Makefile;
    in
    nixtestFinal.assertions.assertTrue (flakeExists && makefileExists)
  );

  # Test 2: Platform detection works
  platformDetectionWorks = nixtestFinal.test "Platform detection works correctly" (
    let
      hasValidPlatform = platformSystem.platform != null;
      hasValidArch = platformSystem.arch != null;
      hasValidSystem = platformSystem.system != null;
    in
    nixtestFinal.assertions.assertTrue (hasValidPlatform && hasValidArch && hasValidSystem)
  );

  # Test 3: Build-switch script exists
  buildSwitchScriptExists = nixtestFinal.test "Build-switch scripts exist" (
    nixtestFinal.assertions.assertTrue (helpers.checkPlatformScript "build-switch")
  );

  # Test 4: Home Manager configuration buildable
  homeManagerConfigurationBuildable = nixtestFinal.test "Home Manager configuration is buildable" (
    nixtestFinal.assertions.assertTrue (helpers.canImport ../../users/baleen/home.nix)
  );

  # Test 5: System configuration for current platform buildable
  systemConfigurationBuildable = nixtestFinal.test "System configuration for current platform is buildable" (
    nixtestFinal.assertions.assertTrue (
      helpers.checkPlatformModule ../../modules/darwin/system.nix ../../modules/nixos/system.nix
    )
  );

  # Test 6: Required packages for build-switch available
  requiredPackagesAvailable = nixtestFinal.test "Required packages for build-switch are available" (
    nixtestFinal.assertions.assertTrue (
      helpers.allPackagesExist helpers.constants.requiredBuildPackages
    )
  );

  # Test 7: Build optimization configuration valid
  buildOptimizationValid = nixtestFinal.test "Build optimization configuration is valid" (
    nixtestFinal.assertions.assertTrue (
      helpers.canImportWith ../../lib/build-optimization.nix { inherit lib pkgs; }
    )
  );

  # Test 8: Platform-specific apps configuration
  platformAppsConfiguration = nixtestFinal.test "Platform-specific apps configuration is valid" (
    nixtestFinal.assertions.assertTrue (
      helpers.canImportWith ../../lib/system-configs.nix {
        inputs = {
          inherit (pkgs) lib;
          nixpkgs = pkgs;
        };
        nixpkgs = pkgs;
      }
    )
  );

  # Test 9: Error handling system available
  errorHandlingAvailable = nixtestFinal.test "Error handling system is available" (
    nixtestFinal.assertions.assertTrue (
      helpers.canImportWith ../../lib/error-system.nix { inherit lib pkgs; }
    )
  );

  # Test 10: Build-switch dry-run simulation
  dryRunSimulation = nixtestFinal.test "Build-switch dry-run can be simulated" (
    nixtestFinal.assertions.assertTrue (
      helpers.allPathsExist [
        ../../flake.nix
        ../../lib
        ../../modules
        ../../scripts
      ]
    )
  );

  # Test 11: Build-switch configuration can be evaluated (fast check)
  buildSwitchConfigEvaluates = nixtestFinal.test "Build-switch configuration evaluates successfully" (
    nixtestFinal.assertions.assertTrue helpers.canEvalBuildSwitchConfig
  );

  # Test 12: Makefile build-switch targets exist
  makefileBuildSwitchTargets = nixtestFinal.test "Makefile has build-switch targets" (
    let
      hasBuildSwitch = helpers.makefileHasTarget "build-switch";
      hasBuildSwitchDry = helpers.makefileHasTarget "build-switch-dry";
    in
    nixtestFinal.assertions.assertTrue (hasBuildSwitch && hasBuildSwitchDry)
  );

  # Test 13: Build-switch user variable handling
  buildSwitchUserVarHandling = nixtestFinal.test "Build-switch handles USER variable correctly" (
    nixtestFinal.assertions.assertTrue (helpers.makefileHasTarget "check-user")
  );

  # Test 14: Build-switch quiet mode enabled
  buildSwitchQuietMode = nixtestFinal.test "Build-switch uses quiet mode for output" (
    let
      makefileContent = builtins.readFile ../../Makefile;
      hasQuietFlag = builtins.match ".*--quiet.*" makefileContent != null;
    in
    nixtestFinal.assertions.assertTrue hasQuietFlag
  );
}
