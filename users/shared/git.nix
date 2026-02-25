# Git 버전 관리 설정
#
# Git 전역 설정, 별칭, 무시 파일 패턴을 관리하는 모듈
# modules/shared/programs/git.nix에서 users/shared/git.nix로 추출
#
# 주요 기능:
#   - 사용자 정보: 이름, 이메일 (lib/user-info.nix에서 자동 적용)
#   - Git LFS: 대용량 파일 지원 활성화
#   - 전역 gitignore: 에디터, OS, 빌드 파일 자동 제외
#   - Pull 전략: rebase 기본 설정 (autoStash 활성화)
#   - 별칭 (aliases):
#       - st: status
#       - co: checkout
#       - br: branch
#       - ci: commit
#       - df: diff
#       - lg: log --graph --oneline --decorate --all
#
# 무시 패턴:
#   - 에디터: .vscode/, .idea/, *.swp
#   - OS: .DS_Store, Thumbs.db
#   - 개발: .direnv/, node_modules/, .env.local
#   - 프로젝트: issues/, specs/, plans/
#

{ pkgs, lib, ... }:

let
  # User information from lib/user-info.nix
  userInfo = import ../../lib/user-info.nix;
  inherit (userInfo) name email;
in
{
  programs.git = {
    enable = true;
    lfs = {
      enable = true;
    };

    settings = {
      user = {
        name = name;
        email = email;
      };
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
        excludesFile = "~/.gitignore_global";
      };
      pull.rebase = true;
      rebase.autoStash = true;
      credential.helper = "!gh auth git-credential";
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        df = "diff";
        lg = "log --graph --oneline --decorate --all";
      };
    };

    ignores = [
      # Local files
      ".local/"

      # Editor files
      "*.swp"
      "*.swo"
      "*~"
      ".vscode/"
      ".idea/"

      # OS files
      ".DS_Store"
      "Thumbs.db"
      "desktop.ini"

      # Development files
      ".direnv/"
      "result"
      "result-*"
      "node_modules/"
      ".env.local"
      ".env.*.local"
      ".serena/"

      # Temporary files
      "*.tmp"
      "*.log"
      ".cache/"

      # Git worktrees
      ".worktrees/"

      # Build artifacts
      "dist/"
      "build/"
      "target/"

      # Issues (local project management)
      "issues/"

      # Plan files (project planning)
      "specs/"
      "plans/"
    ];
  };
}
