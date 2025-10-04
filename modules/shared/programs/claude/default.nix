# Claude Code 설정 관리 모듈
#
# dotfiles/modules/shared/config/claude/ 디렉토리의 설정 파일들을
# ~/.claude/로 심볼릭 링크하여 Claude Code IDE 설정을 관리
#
# 관리하는 설정 파일:
#   - settings.json: Claude Code 기본 설정 (변경 감지 및 자동 알림)
#   - CLAUDE.md: 프로젝트별 AI 지침 문서
#   - hooks/: Git 훅 스크립트 디렉토리
#   - commands/: 커스텀 Claude 명령어 디렉토리
#   - agents/: AI 에이전트 설정 디렉토리
#
# 지원 플랫폼: macOS (Darwin), Linux
# 패키지 추가: 없음 (Claude Code는 별도 설치 필요)
#
# VERSION: 4.0.0 (Multi-platform symlink-based)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

let
  inherit (userInfo) homePath name;
  inherit (platformInfo) isDarwin isLinux;

  # Path to actual Claude config files
  claudeConfigDir = "${homePath}/dev/dotfiles/modules/shared/config/claude";

  # Claude Code uses ~/.claude for both platforms
  claudeHomeDir = ".claude";

in
{
  # No packages needed - Claude Code installed separately
  home.packages = [ ];

  # Symlink all Claude configuration files
  home.file = {
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

    # Hooks directory
    "${claudeHomeDir}/hooks" = {
      source = "${claudeConfigDir}/hooks";
      recursive = true;
    };

    # Commands directory
    "${claudeHomeDir}/commands" = {
      source = "${claudeConfigDir}/commands";
      recursive = true;
    };

    # Agents directory
    "${claudeHomeDir}/agents" = {
      source = "${claudeConfigDir}/agents";
      recursive = true;
    };
  };

  # No programs configuration needed
  programs = { };
}
