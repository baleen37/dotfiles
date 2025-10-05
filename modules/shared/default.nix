# Shared Modules Default Import
#
# 모든 플랫폼(macOS, NixOS)에서 공통으로 사용되는 모듈들을 통합 제공합니다.
# hosts/*/default.nix에서 ../../modules/shared로 import할 때 자동으로 로드됩니다.
#
# 역할:
#   - 플랫폼 공통 시스템 설정 통합
#   - Nix garbage collection 및 store 최적화 설정
#   - 공통 서비스 및 보안 설정 (필요시)
#
# 아키텍처:
#   - 시스템 레벨 설정만 포함 (Home Manager 설정 제외)
#   - 플랫폼별 차이가 없는 설정만 관리
#   - 각 모듈은 단일 책임 원칙(SRP) 준수
#
# 사용:
#   hosts/darwin/default.nix, hosts/nixos/default.nix에서 자동 import

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # 공통 모듈들을 여기에 import
  imports = [
    # Claude 관련 설정은 각 플랫폼의 home-manager에서 간단한 symlink로 관리
    ./nix-gc.nix # Nix 자동 갈비지 컬렉션 설정
  ];

  # 시스템 레벨 공통 설정들을 여기에 추가할 수 있습니다
  # 예: 네트워킹, 보안, 공통 패키지 등
}
