# Nix Garbage Collection Configuration
#
# 자동 갈비지 컬렉션 및 스토리지 최적화 설정
# NixOS와 nix-darwin 모두 지원

_:

{
  nix = {
    # Nix 갈비지 컬렉션 설정 (자동 실행)
    gc = {
      # 자동 갈비지 컬렉션 활성화
      automatic = true;

      # 7일 이상된 항목 삭제
      options = "--delete-older-than 7d";
    };

    # Nix store 최적화 설정 (자동 실행)
    optimise = {
      # 자동 store 최적화 활성화
      automatic = true;
    };

    # 고급 Nix 설정 (베스트 프랙티스)
    settings = {
      # 디스크 공간 부족 시 자동 갈비지 컬렉션
      min-free = 1024 * 1024 * 1024; # 1GB 여유공간 유지
      max-free = 3 * 1024 * 1024 * 1024; # 3GB까지 정리

      # 빌드 완료 후 임시 파일 자동 삭제
      keep-going = true;

      # 최대 job 수 제한으로 시스템 안정성 향상
      max-jobs = "auto";
    };
  };
}
