# macOS Nix Garbage Collection Configuration
#
# Determinate Nix 환경에서 안전한 garbage collection 설정을 제공합니다.
# Determinate Nix가 /etc/nix/nix.conf에서 GC를 직접 관리하므로
# nix-darwin의 자동 GC 기능은 비활성화하여 충돌을 방지합니다.
#
# 수동 실행 방법:
#   - Garbage collection: nix-collect-garbage -d
#   - Store optimization: nix-store --optimise
#
# 주의사항:
#   - lib.mkForce를 사용하여 shared 모듈의 설정을 강제로 덮어씀
#   - Determinate Nix와의 호환성을 위해 자동 GC 비활성화 필수

{
  config,
  pkgs,
  lib,
  ...
}:

{
  # nix-darwin 갈비지 컬렉션 설정 (Determinate Nix와 호환을 위해 비활성화)
  # Determinate Nix가 자체적으로 관리하므로 nix-darwin의 자동 기능 비활성화
  nix.gc = {
    automatic = lib.mkForce false; # shared 모듈 설정을 강제로 덮어씀
    # 수동 실행: nix-collect-garbage -d
  };

  # Nix store 최적화 (Determinate Nix와 호환을 위해 비활성화)
  nix.optimise = {
    automatic = lib.mkForce false; # shared 모듈 설정을 강제로 덮어씀
    # 수동 실행: nix-store --optimise
  };
}
