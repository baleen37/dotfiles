# macOS System Configuration Entry Point
#
# nix-darwin 기반 macOS 시스템 설정의 최상위 진입점입니다.
# 플랫폼별 모듈들을 import하고 시스템 전역 설정을 정의합니다.
#
# 주요 구성:
#   - Home Manager 통합 (사용자 환경 관리)
#   - Nix 앱 링크 시스템 (app-links.nix)
#   - Garbage Collection 설정 (nix-gc.nix)
#   - 공유 모듈 import (modules/shared)
#
# 시스템 설정:
#   - unfree 패키지 허용 (VSCode, Chrome 등)
#   - zsh 활성화
#   - Determinate Nix와의 호환성 유지
#
# 참고: Nix 고급 설정은 Determinate Nix가 /etc/nix/nix.conf에서 관리

{
  config,
  pkgs,
  lib,
  ...
}:

let
  getUser = import ../../lib/user-resolution.nix {
    returnFormat = "string";
  };
  user = getUser;
in

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/app-links.nix
    ../../modules/darwin/nix-gc.nix # macOS 전용 갈비지 컬렉션 설정
    ../../modules/shared/cachix # Binary cache configuration
    ../../modules/shared
  ];

  # Allow unfree packages (system level for useGlobalPkgs)
  nixpkgs.config.allowUnfree = true;

  # Minimal Nix configuration compatible with Determinate Nix
  # Advanced settings managed by Determinate Nix in /etc/nix/nix.conf
  nix = {
    # Disabled to prevent conflicts with Determinate Nix
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
}
