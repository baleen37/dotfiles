# Claude Code 설정 관리 모듈
#
# dotfiles/modules/shared/config/claude/ 디렉토리의 설정 파일들을
# ~/.claude/로 심볼릭 링크하여 Claude Code IDE 설정을 관리
#
# 관리하는 설정 파일:
#   - settings.json: Claude Code 기본 설정 (변경 감지 및 자동 알림)
#   - CLAUDE.md: 프로젝트별 AI 지침 문서 (소스 디렉토리 직접 링크)
#   - hooks/: Git 훅 스크립트 디렉토리 (Go 바이너리 자동 빌드)
#   - commands/: 커스텀 Claude 명령어 디렉토리
#   - agents/: AI 에이전트 설정 디렉토리
#
# 지원 플랫폼: macOS (Darwin), Linux
# 패키지 추가: go (hooks 빌드용)
#
# CLAUDE.md 직접 링크: Nix store를 거치지 않고 소스 디렉토리를 직접 가리킴
# 이를 통해 재빌드 없이 즉시 변경사항 반영 가능
#
# VERSION: 5.3.0 (Direct source link for CLAUDE.md)
# LAST UPDATED: 2025-10-17

{ pkgs, config, ... }:

let
  # Dotfiles root directory (where the user cloned the repository)
  # This is dynamically resolved from the flake's self.outPath
  dotfilesRoot =
    config.home.sessionVariables.DOTFILES_ROOT or "${config.home.homeDirectory}/dev/dotfiles";

  # Path to actual Claude config files
  # For files that need direct source linking (CLAUDE.md), use absolute path
  # For files that need Nix store (settings.json, hooks), use relative path
  claudeConfigDirNix = ../../config/claude;
  claudeConfigDirSource = "${dotfilesRoot}/modules/shared/config/claude";

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
      # Main settings file - via Nix store for immutability
      "${claudeHomeDir}/settings.json" = {
        source = "${claudeConfigDirNix}/settings.json";
        onChange = ''
          echo "Claude settings.json updated"
        '';
      };

      # CLAUDE.md documentation - direct link to source directory (editable without rebuild)
      "${claudeHomeDir}/CLAUDE.md" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/CLAUDE.md";
      };

      # Commands directory - direct symlink to dotfiles
      "${claudeHomeDir}/commands" = {
        source = "${claudeConfigDirNix}/commands";
      };

      # Agents directory - direct symlink to dotfiles
      "${claudeHomeDir}/agents" = {
        source = "${claudeConfigDirNix}/agents";
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
