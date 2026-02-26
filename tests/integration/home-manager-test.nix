# tests/integration/home-manager-test.nix
#
# Tests the Home Manager configuration in users/shared/home-manager.nix
# Verifies imports, currentSystemUser usage, dynamic home directory configuration, and XDG settings.
{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  patterns = import ../lib/patterns.nix { inherit pkgs lib; helpers = helpers; };

  # Expected imports list
  expectedImports = [
    "./git.nix"
    "./vim.nix"
    "./zsh"
    "./starship.nix"
    "./tmux.nix"
    "./claude-code.nix"
    "./opencode.nix"
    "./hammerspoon.nix"
    "./karabiner.nix"
    "./ghostty.nix"
  ];

  # Expected packages
  expectedPackages = [
    "claude-code"
    "opencode"
    "git"
    "vim"
  ];

  # Test with default user (baleen)
  hmConfig = import ../../users/shared/home-manager.nix {
    inherit pkgs lib inputs;
    currentSystemUser = "baleen";
    config = {
      home = {
        homeDirectory = "/Users/baleen";
      };
    };
  };

  # Test with alternative user (jito.hello)
  hmConfigJito = import ../../users/shared/home-manager.nix {
    inherit pkgs lib inputs;
    currentSystemUser = "jito.hello";
    config = {
      home = {
        homeDirectory = "/Users/jito.hello";
      };
    };
  };

in
helpers.testSuite "home-manager" [
  # ===== 기본 구조 검증 =====

  # 설정 구조 검증 (patterns 사용)
  (patterns.testBasicHomeConfig "hm-basic-structure" hmConfig {
    checkHome = true;
    checkXDG = true;
    checkStateVersion = true;
    checkPackages = true;
  })

  # ===== 사용자 설정 검증 =====

  # 사용자 이름 검증 (patterns 사용)
  (patterns.testUsername "hm-username-baleen" hmConfig "baleen")
  (patterns.testUsername "hm-username-jito" hmConfigJito "jito.hello")

  # 홈 디렉토리 검증 (patterns 사용)
  (patterns.testHomeDirectory "hm-home-dir-baleen" hmConfig "/Users/baleen")
  (patterns.testHomeDirectory "hm-home-dir-jito" hmConfigJito "/Users/jito.hello")

  # XDG 활성화 검증 (patterns 사용)
  (patterns.testXDGEnabled "hm-xdg-enabled" hmConfig true)

  # ===== 모듈 임포트 검증 =====

  # 모든 예상 모듈이 임포트되었는지 확인 (patterns 사용)
  (helpers.testSuite "hm-module-imports" (
    builtins.attrValues (patterns.testModuleImports "tool-modules" hmConfig expectedImports)
  ))

  # ===== 패키지 설치 검증 =====

  # 필수 패키지가 설치되었는지 확인 (patterns 사용)
  (helpers.testSuite "hm-package-installation" (
    builtins.attrValues (patterns.testPackagesInstalled "essential-packages" hmConfig expectedPackages)
  ))

  # ===== 상세 검증 (assertions 사용) =====

  # 속성 존재 확인
  (assertions.assertAttrExists "hm-has-imports" hmConfig "imports" null)
  (assertions.assertAttrExists "hm-has-home" hmConfig "home" null)

  # 리스트 길이 검증
  (assertions.assertListNotEmpty "hm-imports-not-empty" (hmConfig.imports or []) null)
  (assertions.assertListNotEmpty "hm-packages-not-empty" (hmConfig.home.packages or []) null)

  # stateVersion이 null이 아닌지 확인
  (assertions.assertNotNull "hm-state-version-not-null" hmConfig.home.stateVersion null)

  # XDG 활성화 확인
  (assertions.assertAttrEquals "hm-xdg-enable-true" hmConfig.xdg "enable" true null)
]
