# Darwin Configuration Test
#
# Tests the consolidated Darwin configuration in users/shared/darwin.nix
# Verifies that system settings, Homebrew config, and performance optimizations are properly defined.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  patterns = import ../lib/patterns.nix { inherit pkgs lib; helpers = helpers; };
  darwinHelpers = import ../lib/darwin-test-helpers.nix { inherit pkgs lib helpers; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };

  darwinConfig = import ../../users/shared/darwin.nix {
    inherit pkgs lib;
    config = mockConfig.mkEmptyConfig;
    currentSystemUser = "baleen"; # Test with default user
  };

in
# Platform filtering - this test should only run on Darwin systems
{
  platforms = ["darwin"];
  value = helpers.testSuite "darwin" (
    # ===== 기본 구조 검증 (assertions 사용) =====

    [
      # 시스템 설정 존재 확인
      (assertions.assertAttrExists "darwin-has-system-settings" darwinConfig "system" null)

      # Homebrew 설정 존재 확인
      (assertions.assertAttrExists "darwin-has-homebrew" darwinConfig "homebrew" null)

      # 성능 최적화 설정 존재 확인
      (assertions.assertAttrPathExists "darwin-has-ns-global-domain" darwinConfig "system.defaults.NSGlobalDomain" null)

      # Dock 최적화 설정 존재 확인
      (assertions.assertAttrPathExists "darwin-has-dock-settings" darwinConfig "system.defaults.dock" null)

      # ===== Homebrew 설정 검증 =====

      # Homebrew 활성화 확인
      (assertions.assertAttrEquals "homebrew-enabled" darwinConfig.homebrew "enable" true null)

      # Homebrew casks 목록이 비어있지 않은지 확인
      (assertions.assertListNotEmpty "homebrew-casks-not-empty" (darwinConfig.homebrew.casks or []) null)

      # Homebrew brews 목록은 mockConfig에서 비어있을 수 있음 (조건부 설정)
      # 실제 시스템에서는 brews가 추가됨
      (helpers.assertTest "homebrew-brews-is-list" (builtins.isList (darwinConfig.homebrew.brews or [])) "homebrew.brews should be a list")

      # ===== 시스템 설정 검증 (darwin-helpers 사용) =====

      # 앱 클린업 스크립트 구성 확인
      (darwinHelpers.assertCleanupScriptConfigured darwinConfig)

      # 문서 비활성화 확인 (빌드 속도 향상)
      (darwinHelpers.assertDocumentationDisabled darwinConfig)

      # 시스템 기본 사용자 확인
      (darwinHelpers.assertSystemPrimaryUser "baleen" darwinConfig)

      # ===== Spaces 설정 검증 =====

      # Spaces가 디스플레이 간 스패닝되지 않는지 확인
      (darwinHelpers.assertSpacesNoSpanDisplays darwinConfig)
    ]
    # ===== 성능 최적화 검증 (darwin-helpers 사용) =====
    ++ (darwinHelpers.assertDarwinOptimizationsLevel1 darwinConfig)
    ++ (darwinHelpers.assertDarwinOptimizationsLevel2 darwinConfig)
    ++ (darwinHelpers.assertDarwinOptimizationsLevel3 darwinConfig)
    ++ (darwinHelpers.assertDockOptimizations darwinConfig)
    ++ (darwinHelpers.assertFinderOptimizations darwinConfig)
    ++ (darwinHelpers.assertTrackpadOptimizations darwinConfig)
    ++ (darwinHelpers.assertLoginWindowOptimizations darwinConfig)
  );
}
