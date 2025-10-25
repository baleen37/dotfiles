# SSH 클라이언트 설정
#
# SSH 연결 최적화 및 보안 설정을 관리하는 모듈
#
# 주요 기능:
#   - 외부 SSH 설정 파일 통합 (~/.ssh/config_external)
#   - SSH 키 에이전트 자동 등록 (1Password 지원)
#   - 연결 유지 설정 (ServerAlive 60초 간격, 최대 3회 재시도)
#   - TCP KeepAlive를 통한 네트워크 안정성 향상
#   - identitiesOnly=true로 키 선택 최적화
#
# VERSION: 3.1.0 (Extracted from development.nix)
# LAST UPDATED: 2024-10-04

{
  userInfo,
  ...
}:

let
  inherit (userInfo) paths;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "${paths.ssh}/config_external"
    ];
    matchBlocks = {
      "*" = {
        identitiesOnly = true;
        addKeysToAgent = "yes";
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        extraOptions = {
          TCPKeepAlive = "yes";
        };
      };
    };
  };
}
