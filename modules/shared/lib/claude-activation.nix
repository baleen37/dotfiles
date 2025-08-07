# Shared Claude configuration management system
# This module provides cross-platform Claude configuration file management
# with simple "dotfiles -> ~/.claude" symlink approach.

{ config, lib, self ? null }:

let
  claudeDir = "${config.home.homeDirectory}/.claude";

  # Intelligent source directory resolution with fallback system
  # Priority: 1. self (Nix store path) 2. relative path 3. absolute fallback
  sourceDir =
    if self != null then "${self}/modules/shared/config/claude"
    else "./modules/shared/config/claude";

  # Backup source directories to try if primary fails
  fallbackSources = [
    "${config.home.homeDirectory}/dev/dotfiles/modules/shared/config/claude"
    "/Users/jito/dev/dotfiles/modules/shared/config/claude"  # jito's typical path
  ];

in ''
  set -euo pipefail  # Enable strict error handling

  CLAUDE_DIR="${claudeDir}"
  SOURCE_DIR="${sourceDir}"
  FALLBACK_SOURCES=(${lib.concatStringsSep " " (map (s: "\"${s}\"") fallbackSources)})

  echo "=== Starting Claude config folder symlink update ==="
  echo "Claude directory: $CLAUDE_DIR"
  echo "Default source directory: $SOURCE_DIR"

  # Source directory validation and fallback
  ACTUAL_SOURCE_DIR=""

  if [[ -d "$SOURCE_DIR" ]]; then
    ACTUAL_SOURCE_DIR="$SOURCE_DIR"
    echo "✓ Default source directory confirmed: $SOURCE_DIR"
  else
    echo "⚠ Default source directory not found: $SOURCE_DIR"
    echo "Checking fallback directories..."

    for fallback_dir in "''${FALLBACK_SOURCES[@]}"; do
      echo "  Trying: $fallback_dir"
      if [[ -d "$fallback_dir" ]]; then
        ACTUAL_SOURCE_DIR="$fallback_dir"
        echo "  ✓ Fallback source found: $fallback_dir"
        break
      fi
    done

    if [[ -z "$ACTUAL_SOURCE_DIR" ]]; then
      echo "❌ Error: Cannot find Claude config source directory!"
      echo "Checked paths:"
      echo "  - $SOURCE_DIR"
      for fallback_dir in "''${FALLBACK_SOURCES[@]}"; do
        echo "  - $fallback_dir"
      done
      echo ""
      echo "Solutions:"
      echo "1. Verify dotfiles are cloned to correct location"
      echo "2. Run 'make build' or 'make switch'"
      echo "3. Verify Nix flake is properly configured"
      exit 1
    fi
  fi

  echo "Using source directory: $ACTUAL_SOURCE_DIR"

  # Create Claude directory (preserve other folders managed by Claude Code)
  mkdir -p "$CLAUDE_DIR"

  # Clean up existing temporary files
  echo "Cleaning existing temporary files..."
  rm -f "$CLAUDE_DIR"/*.new "$CLAUDE_DIR"/*.update-notice

  # Folder symlink creation function
  create_folder_symlink() {
    local source_folder="$1"
    local target_folder="$2"
    local folder_name=$(basename "$source_folder")

    echo "Processing: $folder_name/"

    if [[ ! -d "$source_folder" ]]; then
      echo "  Source folder not found, skipping"
      return 0
    fi

    # Remove existing folder or link if present
    if [[ -e "$target_folder" || -L "$target_folder" ]]; then
      echo "  Removing existing $folder_name folder/link"
      rm -rf "$target_folder"
    fi

    # Create folder symlink
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

  # 파일 복사 함수 (사용자가 수정해야 하는 파일용)
  copy_user_file() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")

    echo "처리 중: $file_name (복사)"

    if [[ ! -f "$source_file" ]]; then
      echo "  소스 파일 없음, 건너뜸"
      return 0
    fi

    # 기존 파일/링크 제거 (항상 실제 파일로 교체)
    if [[ -e "$target_file" || -L "$target_file" ]]; then
      echo "  기존 파일/링크 제거하여 실제 파일로 교체"
      rm -f "$target_file"
    fi

    # 파일 복사 (쓰기 가능하게)
    cp "$source_file" "$target_file"
    chmod 644 "$target_file"
    echo "  파일 복사 완료 (쓰기 가능): $target_file"
  }

  echo ""
  echo "=== Claude 설정 심볼릭 링크 생성 ==="

  # 1. 폴더 단위 심볼릭 링크 생성
  create_folder_symlink "$ACTUAL_SOURCE_DIR/commands" "$CLAUDE_DIR/commands"
  create_folder_symlink "$ACTUAL_SOURCE_DIR/agents" "$CLAUDE_DIR/agents"

  # 2. 루트 레벨 설정 파일들 (.md, .json)
  for source_file in "$ACTUAL_SOURCE_DIR"/*.md "$ACTUAL_SOURCE_DIR"/*.json; do
    if [[ -f "$source_file" ]]; then
      file_name=$(basename "$source_file")

      # settings.json은 사용자가 수정할 수 있어야 하므로 복사
      if [[ "$file_name" == "settings.json" ]]; then
        copy_user_file "$source_file" "$CLAUDE_DIR/$file_name"
      else
        create_file_symlink "$source_file" "$CLAUDE_DIR/$file_name"
      fi
    fi
  done

  echo ""
  echo "✅ Claude 설정이 성공적으로 업데이트되었습니다!"
  echo ""
  echo "확인해보세요:"
  ls -la "$CLAUDE_DIR"/settings.json
  echo ""
  echo "settings.json이 일반 파일로 복사되어 Claude Code가 수정할 수 있습니다."
''
