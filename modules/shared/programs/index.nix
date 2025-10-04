# 공유 프로그램 설정 진입점
#
# modules/shared/programs/ 디렉토리의 모든 프로그램 설정 모듈을 통합하고
# 표준화된 인터페이스로 내보내는 인덱스 파일
#
# 아키텍처 설계 (YAGNI 원칙):
#   - 플랫 구조: 단순한 프로그램은 개별 .nix 파일로 관리
#   - 디렉토리 모듈: 복잡한 프로그램(zsh, tmux)은 별도 디렉토리로 분리
#   - 표준화된 입력: 모든 모듈에 동일한 moduleInputs 전달
#       - config: Home Manager 설정
#       - pkgs: Nixpkgs 패키지 집합
#       - lib: Nix 라이브러리 함수
#       - platformInfo: isDarwin, isLinux, system
#       - userInfo: name, email, homePath, paths
#
# 프로그램 모듈 목록:
#   디렉토리 모듈 (복잡한 설정):
#     - zsh/: 셸 환경 전체 설정 (테마, 별칭, 함수)
#     - tmux/: 터미널 멀티플렉서 (플러그인, 키 바인딩)
#     - claude/: Claude Code 설정 심볼릭 링크
#
#   플랫 파일 모듈 (단순한 설정):
#     - git.nix: Git 전역 설정 및 별칭
#     - vim.nix: Vim 에디터 플러그인 및 키맵
#     - alacritty.nix: Alacritty 터미널 테마
#     - ssh.nix: SSH 클라이언트 설정
#     - direnv.nix: 환경 변수 자동 로드
#     - fzf.nix: 퍼지 파인더 설정
#
# 출력 구조:
#   - programs: 모든 프로그램 설정 병합 (lib.mkMerge)
#   - home: 추가 홈 디렉토리 설정 (심볼릭 링크 등)
#
# VERSION: 3.1.0 (Flat structure with complex program directories)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, ...
}:

let
  # Import centralized user information
  userInfo = import ../../../lib/user-info.nix;

  # User configuration constants
  name = userInfo.name;
  email = userInfo.email;

  # Simple platform detection - direct system checking
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;

  # Standardized module interface data
  homePath = config.home.homeDirectory;
  moduleInputs = {
    inherit config pkgs lib;
    platformInfo = {
      inherit isDarwin isLinux;
      system = pkgs.system;
    };
    userInfo = {
      inherit name email homePath;
      # Legacy compatibility
      paths = {
        home = homePath;
        config = "${homePath}/.config";
        ssh = "${homePath}/.ssh";
      };
    };
  };

  # Import complex program modules (directories)
  zshConfig = import ./zsh/default.nix moduleInputs;
  tmuxConfig = import ./tmux/default.nix moduleInputs;
  claudeConfig = import ./claude/default.nix moduleInputs;

  # Import simple program modules (flat files)
  gitConfig = import ./git.nix moduleInputs;
  vimConfig = import ./vim.nix moduleInputs;
  alacrittyConfig = import ./alacritty.nix moduleInputs;
  sshConfig = import ./ssh.nix moduleInputs;
  direnvConfig = import ./direnv.nix moduleInputs;
  fzfConfig = import ./fzf.nix moduleInputs;

in
{
  # Merge all program configurations using lib.mkMerge for clean combination
  programs = lib.mkMerge [
    # Complex programs with their own directories
    zshConfig.programs
    tmuxConfig.programs
    (claudeConfig.programs or { })

    # Simple programs as flat files
    gitConfig.programs
    vimConfig.programs
    alacrittyConfig.programs
    sshConfig.programs
    direnvConfig.programs
    fzfConfig.programs
  ];

  # Additional home configurations from complex modules
  home = lib.mkMerge [
    (claudeConfig.home or { })
  ];
}
