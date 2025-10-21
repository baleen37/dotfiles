# Claude Code 설정 관리 모듈
#
# dotfiles/modules/shared/config/claude/ 디렉토리의 설정 파일들을
# ~/.claude/로 심볼릭 링크하여 Claude Code IDE 설정을 관리
#
# 관리하는 설정 파일:
#   - settings.json: Claude Code 기본 설정 (직접 링크, 재빌드 불필요)
#   - CLAUDE.md: 프로젝트별 AI 지침 (직접 링크, 재빌드 불필요)
#   - commands/: 커스텀 Claude 명령어 (직접 링크, 재빌드 불필요)
#   - agents/: AI 에이전트 설정 (직접 링크, 재빌드 불필요)
#   - skills/: Claude 스킬 설정 (직접 링크, 재빌드 불필요)
#   - hooks/: Git 훅 스크립트 (Nix store, Go 바이너리 자동 빌드)
#
# 지원 플랫폼: macOS (Darwin), Linux
# 패키지 추가: claude-hooks (CLI 및 hooks 바이너리)
#
# mkOutOfStoreSymlink 사용:
#   - Home Manager의 config.lib.file.mkOutOfStoreSymlink 함수 사용
#   - 소스 디렉토리를 직접 가리키는 심볼릭 링크 생성
#   - 재빌드 없이 즉시 변경사항 반영 가능
#   - self.outPath 사용으로 dotfiles 경로 자동 해석
#   - Nix store를 거치지 않음 (out-of-store direct symlink)
#
# Nix Store 링크:
#   - hooks/: 빌드된 Go 바이너리 (컴파일 필요하므로 Nix store 사용)
#
# VERSION: 7.0.0 (Removed activation script, use mkOutOfStoreSymlink only)
# LAST UPDATED: 2025-10-21

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
  # All files use absolute path with mkOutOfStoreSymlink (except hooks)
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

    # Direct symlinks to dotfiles using mkOutOfStoreSymlink
    # mkOutOfStoreSymlink creates out-of-store direct symlinks (not through Nix store)
    file = {
      # Settings file - editable without rebuild
      "${claudeHomeDir}/settings.json" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/settings.json";
        force = true;
      };

      # Documentation - editable without rebuild
      "${claudeHomeDir}/CLAUDE.md" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/CLAUDE.md";
        force = true;
      };

      # Commands directory - editable without rebuild
      "${claudeHomeDir}/commands" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/commands";
        force = true;
      };

      # Agents directory - editable without rebuild
      "${claudeHomeDir}/agents" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/agents";
        force = true;
      };

      # Skills directory - editable without rebuild
      "${claudeHomeDir}/skills" = {
        source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/skills";
        force = true;
      };

      # Hooks directory - Nix store (contains compiled Go binary)
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
