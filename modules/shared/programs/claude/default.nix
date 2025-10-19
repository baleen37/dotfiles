# Claude Code 설정 관리 모듈
#
# dotfiles/modules/shared/config/claude/ 디렉토리의 설정 파일들을
# ~/.claude/로 심볼릭 링크하여 Claude Code IDE 설정을 관리
#
# 관리하는 설정 파일:
#   - settings.json: Claude Code 기본 설정 (Nix store, 변경 감지 및 자동 알림)
#   - CLAUDE.md: 프로젝트별 AI 지침 (직접 링크, 재빌드 불필요)
#   - commands/: 커스텀 Claude 명령어 (직접 링크, 재빌드 불필요)
#   - agents/: AI 에이전트 설정 (직접 링크, 재빌드 불필요)
#   - skills/: Claude 스킬 설정 (직접 링크, 재빌드 불필요)
#   - hooks/: Git 훅 스크립트 (Nix store, Go 바이너리 자동 빌드)
#
# 지원 플랫폼: macOS (Darwin), Linux
# 패키지 추가: go (hooks 빌드용)
#
# 직접 소스 링크 (mkOutOfStoreSymlink):
#   - CLAUDE.md, commands/, agents/, skills/는 소스 디렉토리를 직접 가리킴
#   - 재빌드 없이 즉시 변경사항 반영 가능
#   - self.outPath 사용으로 자동 경로 해석
#
# Nix Store 링크:
#   - settings.json: 설정 파일 무결성 보장
#   - hooks/: 빌드된 Go 바이너리 (소스 직접 링크 불가)
#
# VERSION: 6.2.0 (Added skills directory to Nix management)
# LAST UPDATED: 2025-10-19

{
  pkgs,
  config,
  self,
  ...
}:

let
  # Dotfiles root directory dynamically resolved from flake's actual location
  # self.outPath provides the absolute path to the flake repository
  dotfilesRoot = self.outPath;

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

      # Commands directory - direct source link (editable without rebuild)
      "${claudeHomeDir}/commands" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/commands";
      };

      # Agents directory - direct source link (editable without rebuild)
      "${claudeHomeDir}/agents" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/agents";
      };

      # Skills directory - direct source link (editable without rebuild)
      "${claudeHomeDir}/skills" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/skills";
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
