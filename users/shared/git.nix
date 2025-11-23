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
#       - 기본: st(status), co(checkout), br(branch), ci(commit), df(diff), lg(log graph)
#       - 커밋: ca(amend), ce(empty), cm(commit -m), aa(add all), ap(add patch)
#       - 브랜치: bd(delete), brv(verbose), bra(all), brdr(remote delete)
#       - 로그: lgf(first-parent), lgs(simplify), lgm(merges), lgg(stat), lp(patch)
#       - 리모트: pu(push), pf(force-with-lease), pl(pull), plo(pull origin)
#       - 스태시: ss(save), sp(pop), sl(list), sd(drop), sa(apply)
#       - 리셋: rs(soft), rh(hard), rc(head~1), unstage, discard
#       - 머지/리베이스: me(no-ff), mt(mergetool), rb, rba(abort), rbc(continue), rbi(interactive)
#       - 기타: bl(blame), gr(grep), wa(worktree add), cp(cherry-pick), rv(revert)
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

    settings = {
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
        excludesFile = "~/.gitignore_global";
      };
      pull.rebase = true;
      rebase.autoStash = true;
      alias = {
        # Basic shortcuts
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        df = "diff";
        lg = "log --graph --oneline --decorate --all";

        # Enhanced commit and amend
        ca = "commit --amend --no-edit";
        ce = "commit --allow-empty-message -m ''";
        cm = "commit -m";

        # Enhanced status and diff
        aa = "add --all";
        ap = "add --patch";
        ds = "diff --staged";
        dt = "difftool";

        # Branch management
        bd = "branch -d";
        bD = "branch -D";
        brv = "branch -v";
        bra = "branch -a";
        brd = "branch -d";
        brdr = "push origin --delete";

        # Log and history
        lgf = "log --graph --oneline --decorate --all --first-parent";
        lgs = "log --graph --oneline --decorate --all --simplify-by-decoration";
        lgm = "log --graph --oneline --decorate --all --merges";
        lgg = "log --graph --stat --decorate";
        lp = "log -p";

        # Remote and push/pull
        pu = "push";
        pf = "push --force-with-lease";
        pl = "pull";
        plo = "pull origin";
        puf = "push origin --force-with-lease";

        # Stash management
        ss = "stash save";
        sp = "stash pop";
        sl = "stash list";
        sd = "stash drop";
        sa = "stash apply";

        # Reset and checkout shortcuts
        rs = "reset --soft";
        rh = "reset --hard";
        rc = "reset --hard HEAD~1";
        unstage = "reset HEAD --";
        discard = "checkout --";

        # Merge and rebase
        me = "merge --no-ff";
        mt = "mergetool";
        rb = "rebase";
        rba = "rebase --abort";
        rbc = "rebase --continue";
        rbi = "rebase -i";

        # Show and blame
        sh = "show";
        shs = "show --stat";
        bl = "blame";
        bll = "blame -L";

        # Search and find
        gr = "grep --break --heading --line-number";
        gra = "grep --break --heading --line-number --all";

        # Submodule management
        smi = "submodule init";
        smu = "submodule update";
        sma = "submodule add";

        # Tag management
        tl = "tag -l";
        td = "tag -d";

        # Worktree management
        wa = "worktree add";
        wp = "worktree prune";
        wl = "worktree list";

        # Cherry-pick and revert
        cp = "cherry-pick";
        cpc = "cherry-pick --continue";
        cpa = "cherry-pick --abort";
        rv = "revert";

        # Bisect and clean
        bs = "bisect";
        bc = "clean -fd";

        # Utility shortcuts
        who = "shortlog -s -n";
        what = "whatchanged";
        recent = "for-each-ref --count=10 --sort=-committerdate refs/heads/ --format='%(refname:short)'";
      };
    };
  };
}
