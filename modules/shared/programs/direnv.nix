# Direnv 환경 관리 설정
#
# 디렉토리별 환경 변수 자동 로드 및 Nix 셸 통합 모듈
#
# 주요 기능:
#   - Zsh 통합: 디렉토리 진입 시 .envrc 자동 실행
#   - nix-direnv: Nix 셸 환경 캐싱으로 성능 향상
#   - .env 파일 자동 로드: load_dotenv 활성화
#
# 사용 예시:
#   프로젝트 디렉토리에 .envrc 생성:
#     use nix           # flake.nix 또는 shell.nix 사용
#     dotenv .env       # .env 파일 로드
#
# VERSION: 3.1.0 (Extracted from productivity.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config = {
      global = {
        load_dotenv = true;
      };
    };
  };
}
