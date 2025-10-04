# Shared File Configurations
#
# 모든 플랫폼에서 공통으로 사용되는 파일 설정을 정의합니다.
# 현재는 플랫폼별 파일 관리를 위한 placeholder 역할을 합니다.
#
# 구조:
#   - 공통 파일: 현재는 비어있음 (필요시 추가)
#   - 플랫폼별 파일: modules/darwin/home-manager.nix, modules/nixos/home-manager.nix에서 관리
#
# 사용:
#   modules/shared/home-manager.nix에서 import하여 home.file로 설정
#
# 참고:
#   Claude Code 설정 등 플랫폼별 파일은 각 플랫폼 모듈에서 symlink로 관리

{ pkgs
, config
, lib
, ...
}:

{
  # Shared files configuration
  # Platform-specific files are managed in their respective modules
}
