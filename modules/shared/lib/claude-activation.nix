# Shared Claude configuration management system
# This module provides cross-platform Claude configuration file management
# with simple symlink-based approach for reliability.

{ config, lib, self ? null, platform ? "unknown" }:

let
  claudeDir = "${config.home.homeDirectory}/.claude";
  # Fallback to relative path if self is not available
  sourceDir = if self != null
    then "${self}/modules/shared/config/claude"
    else "./modules/shared/config/claude";

in ''
  set -euo pipefail  # Enable strict error handling

  CLAUDE_DIR="${claudeDir}"
  SOURCE_DIR="${sourceDir}"
  echo "=== Claude 설정 심볼릭 링크 업데이트 시작 ==="
  echo "Claude 디렉토리: $CLAUDE_DIR"
  echo "소스 디렉토리: $SOURCE_DIR"

  # Claude 디렉토리 생성
  mkdir -p "$CLAUDE_DIR/commands/git"
  mkdir -p "$CLAUDE_DIR/agents"

  # 기존 .new, .update-notice 파일들 정리
  echo "기존 알림 파일들 정리..."
  rm -f "$CLAUDE_DIR"/*.new "$CLAUDE_DIR"/*.update-notice
  rm -f "$CLAUDE_DIR"/*.bak "$CLAUDE_DIR/commands"/*.bak

  # 심볼릭 링크 생성 함수
  create_symlink() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")

    echo "처리 중: $file_name"

    if [[ ! -f "$source_file" ]]; then
      echo "  소스 파일 없음, 건너뜀"
      return 0
    fi

    # 기존 파일이나 링크가 있으면 제거
    if [[ -e "$target_file" || -L "$target_file" ]]; then
      rm -f "$target_file"
    fi

    # 심볼릭 링크 생성
    ln -sf "$source_file" "$target_file"
    echo "  심볼릭 링크 생성: $target_file -> $source_file"
  }

  echo ""
  echo "=== Claude 설정 파일 심볼릭 링크 생성 ==="

  # 메인 설정 파일들 처리
  for config_file in "settings.json" "CLAUDE.md"; do
    create_symlink "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
  done

  # commands 디렉토리 처리 (서브디렉토리 지원)
  if [[ -d "$SOURCE_DIR/commands" ]]; then
    # find를 사용하여 모든 서브디렉토리의 .md 파일 처리
    find "$SOURCE_DIR/commands" -name "*.md" -type f | while read -r source_cmd_file; do
      # 소스에서 commands 디렉토리를 기준으로 한 상대 경로 계산
      relative_cmd_path="''${source_cmd_file#$SOURCE_DIR/commands/}"
      target_cmd_file="$CLAUDE_DIR/commands/$relative_cmd_path"

      # 타겟 디렉토리가 없으면 생성
      target_cmd_dir=$(dirname "$target_cmd_file")
      mkdir -p "$target_cmd_dir"

      create_symlink "$source_cmd_file" "$target_cmd_file"
    done
  fi

  # agents 디렉토리 처리
  if [[ -d "$SOURCE_DIR/agents" ]]; then
    for agent_file in "$SOURCE_DIR/agents"/*.md; do
      if [[ -f "$agent_file" ]]; then
        base_name=$(basename "$agent_file")
        create_symlink "$agent_file" "$CLAUDE_DIR/agents/$base_name"
      fi
    done
  fi

  # 소스에 없는 심볼릭 링크 정리
  cleanup_orphaned_links() {
    echo ""
    echo "소스에 없는 심볼릭 링크 정리 중..."

    # 루트 레벨 파일들 확인
    for target_file in "$CLAUDE_DIR"/*.md "$CLAUDE_DIR"/*.json; do
      if [[ -L "$target_file" ]]; then
        local link_target=$(readlink "$target_file")
        if [[ ! -f "$link_target" ]]; then
          echo "  끊어진 링크 삭제: $(basename "$target_file")"
          rm -f "$target_file"
        fi
      fi
    done

    # commands 디렉토리 파일들 확인
    if [[ -d "$CLAUDE_DIR/commands" ]]; then
      find "$CLAUDE_DIR/commands" -name "*.md" -type l | while read -r target_file; do
        local link_target=$(readlink "$target_file")
        if [[ ! -f "$link_target" ]]; then
          echo "  끊어진 링크 삭제: ''${target_file#$CLAUDE_DIR/}"
          rm -f "$target_file"
        fi
      done
    fi

    # agents 디렉토리 파일들 확인
    for target_file in "$CLAUDE_DIR/agents"/*.md; do
      if [[ -L "$target_file" ]]; then
        local link_target=$(readlink "$target_file")
        if [[ ! -f "$link_target" ]]; then
          echo "  끊어진 링크 삭제: agents/$(basename "$target_file")"
          rm -f "$target_file"
        fi
      fi
    done
  }

  # 끊어진 심볼릭 링크 정리
  cleanup_orphaned_links

  echo "=== Claude 설정 심볼릭 링크 업데이트 완료 ==="
''
