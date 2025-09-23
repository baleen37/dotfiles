# Darwin-specific Nix Garbage Collection Configuration
#
# macOS용 nix-darwin에서 자동 갈비지 컬렉션 설정 (베스트 프랙티스)
# launchd를 통한 스케줄링 지원

{ config, pkgs, lib, ... }:

{
  # nix-darwin 갈비지 컬렉션 설정 (자동 실행)
  nix.gc = {
    # 자동 갈비지 컬렉션 활성화
    automatic = true;

    # 매주 일요일 새벽 3시에 실행 (launchd 스케줄)
    interval = {
      Weekday = 0; # 일요일
      Hour = 3;
      Minute = 0;
    };

    # 7일 이상된 항목 삭제
    options = "--delete-older-than 7d";
  };

  # Nix store 최적화 (자동 실행)
  nix.optimise = {
    automatic = true;
    interval = {
      Weekday = 0; # 일요일
      Hour = 3;
      Minute = 30; # 갈비지 컬렉션 후 30분 뒤
    };
  };
}
