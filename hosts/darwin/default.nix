# macOS System Configuration Entry Point
#
# nix-darwin 기반 macOS 시스템 설정의 최상위 진입점입니다.
# 플랫폼별 모듈들을 import하고 시스템 전역 설정을 정의합니다.
#
# 주요 구성:
#   - Home Manager 통합 (사용자 환경 관리)
#   - Nix 앱 링크 시스템 (app-links.nix)
#   - Garbage Collection 설정 (nix-gc.nix)
#   - macOS 성능 최적화 (performance-optimization.nix)
#   - macOS 앱 클린업 (macos-app-cleanup.nix)
#   - 공유 모듈 import (modules/shared)
#
# 시스템 설정:
#   - unfree 패키지 허용 (VSCode, Chrome 등)
#   - zsh 활성화
#   - Determinate Nix와의 호환성 유지
#
# 참고: Nix 고급 설정은 Determinate Nix가 /etc/nix/nix.conf에서 관리

_:

let
  getUser = import ../../lib/user-resolution.nix {
    returnFormat = "string";
    default = ""; # Allow empty for pure eval
  };
  user = getUser;
in

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/app-links.nix
    ../../modules/darwin/nix-gc.nix # macOS 전용 갈비지 컬렉션 설정
    ../../modules/darwin/performance-optimization.nix # macOS 성능 최적화
    ../../modules/darwin/macos-app-cleanup.nix # macOS 기본 앱 클린업
    ../../modules/darwin/aggressive-optimization.nix # 🚀 공격적 성능 최적화 (Spotlight 비활성화 등)
    ../../modules/shared/cachix # Binary cache configuration
    ../../modules/shared
  ];

  # Allow unfree packages (system level for useGlobalPkgs)
  nixpkgs.config.allowUnfree = true;

  # Minimal Nix configuration compatible with Determinate Nix
  # Advanced settings managed by Determinate Nix in /etc/nix/nix.conf
  nix = {
    # Disable nix-darwin's Nix management (Determinate Nix manages the installation)
    enable = false;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # zsh program activation
  programs.zsh.enable = true;

  # Disable automatic app links (requires root privileges)
  system.nixAppLinks.enable = false;

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;
  };

  # Disable documentation generation to avoid builtins.toFile warnings
  documentation.enable = false;
}
