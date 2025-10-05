# Fzf 퍼지 파인더 설정
#
# 파일 검색 및 명령어 히스토리 탐색을 위한 fzf 설정 모듈
#
# 주요 기능:
#   - Zsh 통합: Ctrl+R (히스토리 검색), Ctrl+T (파일 검색)
#   - 최적화된 파일 검색: ripgrep 기반, .git 디렉토리 제외
#   - UI 설정: 40% 높이, 역순 레이아웃, 테두리 표시
#   - 히스토리 검색: 정렬 활성화, 정확한 매칭 모드
#
# VERSION: 3.1.0 (Extracted from productivity.nix)
# LAST UPDATED: 2024-10-04

_:

{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "rg --files --hidden --follow --glob '!.git/*'";
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    historyWidgetOptions = [
      "--sort"
      "--exact"
    ];
  };
}
