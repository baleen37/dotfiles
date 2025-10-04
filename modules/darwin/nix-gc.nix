# Darwin-specific Nix Garbage Collection Configuration
#
# macOS용 nix-darwin에서 자동 갈비지 컬렉션 설정 (베스트 프랙티스)
# launchd를 통한 스케줄링 지원

{ config
, pkgs
, lib
, ...
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
