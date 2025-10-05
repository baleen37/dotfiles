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
# VERSION: 5.0.0 (Go hooks auto-build)
# LAST UPDATED: 2025-10-05

{ pkgs, ... }:

let
  # Path to actual Claude config files (relative to this module)
  claudeConfigDir = ../../config/claude;

  # Claude Code uses ~/.claude for both platforms
  claudeHomeDir = ".claude";

  # Build Go hooks binary
  claudeHooks = pkgs.buildGoModule {
    pname = "claude-hooks";
    version = "1.0.0";
    src = ./../../config/claude/hooks-go;
    vendorHash = null;
    subPackages = [ "cmd/claude-hooks" ];
  };

  # Create hooks directory with built binary and wrapper scripts
  hooksDir = pkgs.runCommand "claude-hooks-dir" { } ''
        mkdir -p $out

        # Copy built Go binary
        cp ${claudeHooks}/bin/claude-hooks $out/claude-hooks
        chmod +x $out/claude-hooks

        # Create git-commit-validator wrapper
        cat > $out/git-commit-validator <<'EOF'
    #!/usr/bin/env bash
    # Git commit validation hook wrapper
    HOOK_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
    exec "''${HOOK_DIR}/claude-hooks" git-commit-validator
    EOF
        chmod +x $out/git-commit-validator

        # Create message-cleaner wrapper
        cat > $out/message-cleaner <<'EOF'
    #!/usr/bin/env bash
    # Message cleaner hook wrapper
    HOOK_DIR="$(cd "$(dirname "''${BASH_SOURCE[0]}")" && pwd)"
    exec "''${HOOK_DIR}/claude-hooks" message-cleaner
    EOF
        chmod +x $out/message-cleaner
  '';

  # Dotfiles repo path for direct symlinks (development mode)
  dotfilesPath = builtins.toString claudeConfigDir;

in
{
  # Home Manager configuration
  home = {
    # No packages needed - Claude Code installed separately
    packages = [ ];

    # Symlink configuration files via Nix store
    file = {
      # Main settings file
      "${claudeHomeDir}/settings.json" = {
        source = "${claudeConfigDir}/settings.json";
        onChange = ''
          echo "Claude settings.json updated"
        '';
      };

      # CLAUDE.md documentation
      "${claudeHomeDir}/CLAUDE.md" = {
        source = "${claudeConfigDir}/CLAUDE.md";
      };

      # Hooks directory (with built Go binary)
      "${claudeHomeDir}/hooks" = {
        source = hooksDir;
        recursive = true;
      };
    };

    # Direct symlinks for commands/agents (bypass Nix store for instant updates)
    activation = {
      claudeDirectSymlinks = pkgs.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        $DRY_RUN_CMD rm -f $HOME/${claudeHomeDir}/commands $HOME/${claudeHomeDir}/agents
        $DRY_RUN_CMD ln -sf ${dotfilesPath}/commands $HOME/${claudeHomeDir}/commands
        $DRY_RUN_CMD ln -sf ${dotfilesPath}/agents $HOME/${claudeHomeDir}/agents
        echo "Created direct symlinks for Claude commands and agents"
      '';
    };
  };

  # No programs configuration needed
  programs = { };
}
