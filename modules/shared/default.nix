# Shared Modules Default Import
#
# 이 파일은 모든 플랫폼에서 공통으로 사용되는 모듈들을 통합 제공합니다.
# hosts/*/default.nix에서 ../../modules/shared로 import할 때 자동으로 로드됩니다.

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
