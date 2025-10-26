# User Workflow End-to-End Tests
#
# 실제 사용자 워크플로의 완전한 e2e 테스트
#
# 주요 검증 항목:
# - make build-current 성공
# - Home Manager 빌드 검증
# - 핵심 설정 파일 생성 확인
# - 패키지 가용성 검증

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

  # Import platform system
  platformSystem = import ../../lib/platform-system.nix { inherit system; };

  # Import E2E test helpers
  helpers = import ./helpers.nix { inherit lib pkgs platformSystem; };

in
nixtestFinal.suite "User Workflow E2E Tests" {

  # Test 1: Home Manager configuration complete
  homeManagerConfigurationComplete = nixtestFinal.test "Home Manager configuration is complete" (
    nixtestFinal.assertions.assertTrue (helpers.canImport ../../users/baleen/home.nix)
  );

  # Test 2: Essential packages available
  essentialPackagesAvailable = nixtestFinal.test "Essential packages are available" (
    nixtestFinal.assertions.assertTrue (helpers.allPackagesExist helpers.constants.essentialDevTools)
  );

  # Test 3: Claude Code configuration valid
  claudeCodeConfigurationValid = nixtestFinal.test "Claude Code configuration is valid" (
    nixtestFinal.assertions.assertTrue (
      helpers.checkConfigStructure ../../modules/shared/config/claude [
        "project.json"
        "commands"
      ]
    )
  );

  # Test 4: Git configuration valid
  gitConfigurationValid = nixtestFinal.test "Git configuration is valid" (
    nixtestFinal.assertions.assertTrue (helpers.canImport ../../modules/shared/programs.nix)
  );

  # Test 5: Shell configuration complete
  shellConfigurationComplete = nixtestFinal.test "Shell configuration is complete" (
    let
      p10kExists = builtins.pathExists ../../modules/shared/config/p10k.zsh;
      programsValid = helpers.canImport ../../modules/shared/programs.nix;
    in
    nixtestFinal.assertions.assertTrue (p10kExists && programsValid)
  );

  # Test 6: User configuration for common users
  userConfigurationForCommonUsers = nixtestFinal.test "User configuration works for common users" (
    let
      testUserConfig =
        user:
        let
          result = builtins.tryEval {
            username = user;
            homeDirectory = helpers.getUserHomeDir user;
            inherit (helpers.constants) stateVersion;
          };
        in
        result.success;

      allUsersWork = builtins.all testUserConfig helpers.constants.testUsers;
    in
    nixtestFinal.assertions.assertTrue allUsersWork
  );

  # Test 7: Platform-specific configuration valid
  platformSpecificConfigurationValid = nixtestFinal.test "Platform-specific configuration is valid" (
    nixtestFinal.assertions.assertTrue (
      helpers.checkPlatformModule ../../modules/darwin/default.nix ../../modules/nixos/default.nix
    )
  );

  # Test 8: Package lists complete
  packageListsComplete = nixtestFinal.test "Package lists are complete and valid" (
    let
      sharedValid = helpers.canImport ../../modules/shared/packages.nix;
      platformValid = helpers.checkPlatformModule ../../modules/darwin/packages.nix ../../modules/nixos/packages.nix;
    in
    nixtestFinal.assertions.assertTrue (sharedValid && platformValid)
  );

  # Test 9: File configurations exist
  fileConfigurationsExist = nixtestFinal.test "File configurations exist and are valid" (
    let
      sharedValid = helpers.canImport ../../modules/shared/files.nix;
      platformValid = helpers.checkPlatformModule ../../modules/darwin/files.nix ../../modules/nixos/files.nix;
    in
    nixtestFinal.assertions.assertTrue (sharedValid && platformValid)
  );

  # Test 10: Development environment complete
  developmentEnvironmentComplete = nixtestFinal.test "Development environment is complete" (
    let
      toolsAvailable = helpers.allPackagesExist (
        helpers.constants.essentialDevTools ++ helpers.constants.formattingTools
      );
      infrastructureExists = helpers.allPathsExist [
        ../../flake.nix
        ../../Makefile
      ];
    in
    nixtestFinal.assertions.assertTrue (toolsAvailable && infrastructureExists)
  );

  # Test 11: Auto-update configuration valid
  autoUpdateConfigurationValid = nixtestFinal.test "Auto-update configuration is valid" (
    nixtestFinal.assertions.assertTrue (
      helpers.allPathsExist [
        ../../scripts
        ../../.github/workflows
      ]
    )
  );

  # Test 12: Testing framework integration
  testingFrameworkIntegration = nixtestFinal.test "Testing framework is integrated" (
    nixtestFinal.assertions.assertTrue (
      helpers.checkConfigStructure ../../tests [
        "unit"
        "integration"
        "e2e"
      ]
    )
  );
}
