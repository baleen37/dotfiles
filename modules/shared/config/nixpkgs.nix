# Nixpkgs Configuration (Compatibility Stub)
#
# 이 파일은 이전 버전과의 호환성을 위해 유지되며, 실제 설정은 시스템 레벨에서 수행됩니다.
#
# 배경:
#   - useGlobalPkgs 사용으로 nixpkgs 설정이 시스템 레벨로 이동
#   - darwin/system.nix와 nixos/system.nix에서 nixpkgs.config 관리
#   - 이 파일은 기존 import 구조 유지를 위한 no-op 역할
#
# 실제 설정 위치:
#   - modules/darwin/system.nix (macOS)
#   - modules/nixos/system.nix (NixOS)

{ lib, ... }:
{
  # This is now set at system level (darwin/nixos) when using useGlobalPkgs
  # Keeping this file for compatibility but it's effectively a no-op
}
