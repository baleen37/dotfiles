# Claude Code 설정 관리 모듈
#
# dotfiles/modules/shared/config/claude/ 디렉토리의 설정 파일들을
# ~/.claude/로 심볼릭 링크하여 Claude Code IDE 설정을 관리
#
# 관리하는 설정 파일:
#   - settings.json: Claude Code 기본 설정 (변경 감지 및 자동 알림)
#   - CLAUDE.md: 프로젝트별 AI 지침 문서
#   - hooks/: Git 훅 스크립트 디렉토리 (Go 바이너리 자동 빌드)
#   - commands/: 커스텀 Claude 명령어 디렉토리
#   - agents/: AI 에이전트 설정 디렉토리
#
# 지원 플랫폼: macOS (Darwin), Linux
# 패키지 추가: go (hooks 빌드용)
#
# VERSION: 5.2.0 (Separated claude-hook module)
# LAST UPDATED: 2025-10-07

{ pkgs, ... }:

let
  # Path to actual Claude config files
  claudeConfigDir = ../../config/claude;

  # Claude Code uses ~/.claude for both platforms
  claudeHomeDir = ".claude";

  # Import claude-hooks binary from separate module
  claudeHooks = pkgs.callPackage ../claude-hook { };

  # Create hooks directory with claude-hooks binary and wrappers
  hooksDir = pkgs.runCommand "claude-hooks-dir" { } ''
        mkdir -p $out
        cp ${claudeHooks}/bin/claude-hooks $out/claude-hooks
        chmod +x $out/claude-hooks

        # Create wrapper scripts that call claude-hooks with appropriate subcommand
        cat > $out/git-commit-validator <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" git-commit-validator
    EOF
        chmod +x $out/git-commit-validator

        cat > $out/gh-pr-validator <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" gh-pr-validator
    EOF
        chmod +x $out/gh-pr-validator

        cat > $out/message-cleaner <<'EOF'
    #!/usr/bin/env bash
    SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
    exec "$SCRIPT_DIR/claude-hooks" message-cleaner
    EOF
        chmod +x $out/message-cleaner
  '';

in
{
  # Home Manager configuration
  home = {
    # Global claude-hooks binary for terminal use
    packages = [ claudeHooks ];

    # Direct symlinks to dotfiles for all Claude configuration
    file = {
      # Main settings file - direct symlink to dotfiles
      "${claudeHomeDir}/settings.json" = {
        source = "${claudeConfigDir}/settings.json";
        onChange = ''
          echo "Claude settings.json updated"
        '';
      };

      # CLAUDE.md documentation - direct symlink to dotfiles
      "${claudeHomeDir}/CLAUDE.md" = {
        source = "${claudeConfigDir}/CLAUDE.md";
      };

      # Commands directory - direct symlink to dotfiles
      "${claudeHomeDir}/commands" = {
        source = "${claudeConfigDir}/commands";
        recursive = true;
      };

      # Agents directory - direct symlink to dotfiles
      "${claudeHomeDir}/agents" = {
        source = "${claudeConfigDir}/agents";
        recursive = true;
      };

      # Hooks directory (with built Go binary)
      "${claudeHomeDir}/hooks" = {
        source = hooksDir;
        recursive = true;
      };
    };
  };

  # No programs configuration needed
  programs = { };
}
# Trigger rebuild
