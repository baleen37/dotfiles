# Zsh 셸 환경 설정
#
# 전체 Zsh 설정을 단일 파일로 관리하는 모듈 (YAGNI 원칙 준수)
#
# 주요 기능:
#   - Powerlevel10k 테마: 고급 프롬프트 테마 및 설정 적용
#   - 1Password SSH 에이전트: 플랫폼별 소켓 자동 감지 및 연결
#   - PATH 관리: npm, pnpm, 로컬 bin 디렉토리 자동 추가
#   - IntelliJ IDEA 런처: 플랫폼별 설치 경로 자동 감지
#   - Claude CLI 통합:
#       - cc: Claude Code 빠른 실행 (권한 검사 생략)
#       - ccw: Git worktree 생성/전환 + Claude 실행
#   - SSH 래퍼: autossh를 통한 자동 재연결 지원
#   - dotfiles 자동 업데이트: 셸 시작 시 백그라운드 업데이트
#
# 환경 변수:
#   - EDITOR/VISUAL: vim
#   - LANG/LC_ALL: en_US.UTF-8
#   - SSH_AUTH_SOCK: 1Password 에이전트 소켓 자동 설정
#
# VERSION: 3.1.0 (Single file configuration)
# LAST UPDATED: 2024-10-04

{
  pkgs,
  lib,
  platformInfo,
  ...
}:

let
  inherit (platformInfo) isDarwin isLinux;
in
{
  programs.zsh = {
    enable = true;
    autocd = false;

    shellAliases = {
      # Claude CLI shortcut
      cc = "claude --dangerously-skip-permissions";

      # Use difftastic for syntax-aware diffing
      diff = "difft";

      # Always color ls and group directories
      ls = "ls --color=auto";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ../../config;
        file = "p10k.zsh";
      }
    ];

    initContent = lib.mkAfter ''
      # Nix daemon initialization
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # PATH configuration
      export PATH=$HOME/.pnpm-packages/bin:$HOME/.pnpm-packages:$PATH
      export PATH=$HOME/.npm-global/bin:$HOME/.npm-packages/bin:$HOME/bin:$PATH
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$HOME/.local/bin:$PATH

      # History configuration
      export HISTIGNORE="pwd:ls:cd"

      # Locale settings for UTF-8 support
      export LANG="en_US.UTF-8"
      export LC_ALL="en_US.UTF-8"

      # Editor preferences
      export EDITOR="vim"
      export VISUAL="vim"

      # Optimized 1Password SSH agent detection with platform awareness
      _setup_1password_agent() {
        # Early exit if already configured
        [[ -n "$${SSH_AUTH_SOCK:-}" ]] && [[ -S "$SSH_AUTH_SOCK" ]] && return 0

        local socket_paths=()

        # Platform-specific socket detection
        ${lib.optionalString isDarwin ''
          # macOS: Check Group Containers efficiently
          for container in ~/Library/Group\ Containers/*.com.1password; do
            [[ -d "$container" ]] && socket_paths+=("$container/t/agent.sock")
          done 2>/dev/null
        ''}

        # Common cross-platform locations
        socket_paths+=(
          ~/.1password/agent.sock
          /tmp/1password-ssh-agent.sock
          ~/Library/Containers/com.1password.1password/Data/tmp/agent.sock
        )

        # Find first available socket
        for sock in "$${socket_paths[@]}"; do
          if [[ -S "$sock" ]]; then
            export SSH_AUTH_SOCK="$sock"
            return 0
          fi
        done

        return 1
      }

      _setup_1password_agent

      # nix shortcuts
      shell() {
          nix-shell '<nixpkgs>' -A "$1"
      }

      # Auto-update dotfiles on shell startup (with TTL)
      if [[ -x "$HOME/dotfiles/scripts/auto-update-dotfiles" ]]; then
        (nohup "$HOME/dotfiles/scripts/auto-update-dotfiles" --silent &>/dev/null &)
      fi

      # Optimized IntelliJ IDEA launcher with platform detection
      idea() {
        # Cached command resolution for performance
        local idea_cmd=""
        local search_paths=()

        # Build platform-specific search paths
        search_paths+=("intellij-idea-ultimate" "intellij-idea-community")

        ${lib.optionalString isDarwin ''
          search_paths+=("/opt/homebrew/bin/idea" "/Applications/IntelliJ IDEA.app/Contents/MacOS/idea" "/Applications/IntelliJ IDEA Ultimate.app/Contents/MacOS/idea")
        ''}
        ${lib.optionalString isLinux ''
          search_paths+=("/home/linuxbrew/.linuxbrew/bin/idea" "/usr/local/bin/idea")
        ''}

        # Find first available IDEA installation
        for cmd in "$${search_paths[@]}"; do
          if command -v "$cmd" >/dev/null 2>&1; then
            idea_cmd="$cmd"
            break
          elif [[ -x "$cmd" ]]; then
            idea_cmd="$cmd"
            break
          fi
        done

        if [[ -z "$idea_cmd" ]]; then
          echo "❌ IntelliJ IDEA not found. Install options:"
          echo "   • Nix: nix-env -iA nixpkgs.jetbrains.idea-ultimate"
          ${lib.optionalString isDarwin ''echo "   • Homebrew: brew install --cask intellij-idea"''}
          ${lib.optionalString isLinux ''echo "   • Package manager or direct download"''}
          return 1
        fi

        # Launch with proper background handling
        echo "🚀 Starting IntelliJ IDEA: $idea_cmd"
        nohup "$idea_cmd" "$@" >/dev/null 2>&1 & disown
      }

      # Claude CLI with Git Worktree workflow
      ccw() {
        local branch_name="$1"

        if [[ -z "$branch_name" ]]; then
          echo "Usage: ccw <branch-name>"
          echo "Creates/switches to git worktree at ../<branch-name> and starts Claude"
          return 1
        fi

        if ! git rev-parse --git-dir >/dev/null 2>&1; then
          echo "Error: Not in a git repository"
          return 1
        fi

        local worktree_path="../$branch_name"

        if [[ -d "$worktree_path" ]]; then
          echo "Switching to existing worktree: $worktree_path"
          cd "$worktree_path"
        else
          echo "Creating new git worktree for branch '$branch_name'..."

          if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
            git worktree add "$worktree_path" "origin/$branch_name"
          else
            git worktree add -b "$branch_name" "$worktree_path"
          fi

          cd "$worktree_path"
        fi

        echo "Worktree: $(pwd) | Branch: $(git branch --show-current)"
        cc
      }

      # Enhanced SSH wrapper with intelligent reconnection
      ssh() {
        # Optimized connection wrapper with autossh fallback
        if command -v autossh >/dev/null 2>&1; then
          # Use autossh with optimized settings for reliability
          AUTOSSH_POLL=60 AUTOSSH_FIRST_POLL=30 autossh -M 0 \
            -o "ServerAliveInterval=30" \
            -o "ServerAliveCountMax=3" \
            "$@"
        else
          # Enhanced regular SSH with connection optimization
          command ssh \
            -o "ServerAliveInterval=60" \
            -o "ServerAliveCountMax=3" \
            -o "TCPKeepAlive=yes" \
            "$@"
        fi
      }
    '';
  };
}
