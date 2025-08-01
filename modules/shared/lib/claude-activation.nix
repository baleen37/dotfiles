# Shared Claude configuration management system
# This module provides cross-platform Claude configuration file management
# with simple folder-level symlink approach for maximum simplicity.

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
  echo "=== Claude 설정 폴더 심볼릭 링크 업데이트 시작 ==="
  echo "Claude 디렉토리: $CLAUDE_DIR"
  echo "소스 디렉토리: $SOURCE_DIR"

  # Claude 디렉토리 생성 (Claude Code가 관리하는 다른 폴더들 보존)
  mkdir -p "$CLAUDE_DIR"

  # 기존 개별 파일 심볼릭 링크들과 .new, .update-notice 파일들 정리
  echo "기존 설정 파일들 정리..."
  rm -f "$CLAUDE_DIR"/*.new "$CLAUDE_DIR"/*.update-notice "$CLAUDE_DIR"/*.bak

  # 폴더 심볼릭 링크 생성 함수
  create_folder_symlink() {
    local source_folder="$1"
    local target_folder="$2"
    local folder_name=$(basename "$source_folder")

    echo "처리 중: $folder_name/"

    if [[ ! -d "$source_folder" ]]; then
      echo "  소스 폴더 없음, 건너뜀"
      return 0
    fi

    # 기존 폴더나 링크가 있으면 제거
    if [[ -e "$target_folder" || -L "$target_folder" ]]; then
      echo "  기존 $folder_name 폴더/링크 제거"
      rm -rf "$target_folder"
    fi

    # 폴더 심볼릭 링크 생성
    ln -sf "$source_folder" "$target_folder"
    echo "  폴더 심볼릭 링크 생성: $target_folder -> $source_folder"
  }

  # 개별 파일 심볼릭 링크 생성 함수 (루트 레벨 설정 파일용)
  create_file_symlink() {
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
    echo "  파일 심볼릭 링크 생성: $target_file -> $source_file"
  }

  echo ""
  echo "=== Claude 설정 심볼릭 링크 생성 ==="

  # 1. 폴더 단위 심볼릭 링크 생성
  create_folder_symlink "$SOURCE_DIR/commands" "$CLAUDE_DIR/commands"
  create_folder_symlink "$SOURCE_DIR/agents" "$CLAUDE_DIR/agents"

  # 2. 루트 레벨 설정 파일들 (.md, .json)
  for source_file in "$SOURCE_DIR"/*.md "$SOURCE_DIR"/*.json; do
    if [[ -f "$source_file" ]]; then
      file_name=$(basename "$source_file")
      create_file_symlink "$source_file" "$CLAUDE_DIR/$file_name"
    fi
  done

  # 끊어진 심볼릭 링크 정리
  echo ""
  echo "끊어진 심볼릭 링크 정리 중..."

  # 루트 레벨에서 끊어진 링크 찾아 제거
  find "$CLAUDE_DIR" -maxdepth 1 -type l | while read -r link_file; do
    if [[ ! -e "$link_file" ]]; then
      echo "  끊어진 링크 삭제: $(basename "$link_file")"
      rm -f "$link_file"
    fi
  done

  echo "=== Claude 설정 심볼릭 링크 업데이트 완료 ==="
''
