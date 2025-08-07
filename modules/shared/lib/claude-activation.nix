# Shared Claude configuration management system
# This module provides cross-platform Claude configuration file management
# with simple "dotfiles -> ~/.claude" symlink approach.

{ config, lib, self ? null, platform ? "unknown" }:

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

  echo "=== Claude 설정 폴더 심볼릭 링크 업데이트 시작 ==="
  echo "Claude 디렉토리: $CLAUDE_DIR"
  echo "기본 소스 디렉토리: $SOURCE_DIR"

  # 소스 디렉토리 유효성 검사 및 fallback
  ACTUAL_SOURCE_DIR=""

  if [[ -d "$SOURCE_DIR" ]]; then
    ACTUAL_SOURCE_DIR="$SOURCE_DIR"
    echo "✓ 기본 소스 디렉토리 확인됨: $SOURCE_DIR"
  else
    echo "⚠ 기본 소스 디렉토리 없음: $SOURCE_DIR"
    echo "Fallback 디렉토리들 확인 중..."

    for fallback_dir in "''${FALLBACK_SOURCES[@]}"; do
      echo "  시도 중: $fallback_dir"
      if [[ -d "$fallback_dir" ]]; then
        ACTUAL_SOURCE_DIR="$fallback_dir"
        echo "  ✓ Fallback 소스 발견: $fallback_dir"
        break
      fi
    done

    if [[ -z "$ACTUAL_SOURCE_DIR" ]]; then
      echo "❌ 오류: Claude 설정 소스 디렉토리를 찾을 수 없습니다!"
      echo "확인한 경로들:"
      echo "  - $SOURCE_DIR"
      for fallback_dir in "''${FALLBACK_SOURCES[@]}"; do
        echo "  - $fallback_dir"
      done
      echo ""
      echo "해결 방법:"
      echo "1. dotfiles를 올바른 위치에 clone했는지 확인"
      echo "2. 'make build' 또는 'make switch' 실행"
      echo "3. Nix flake가 올바르게 설정되었는지 확인"
      exit 1
    fi
  fi

  echo "사용할 소스 디렉토리: $ACTUAL_SOURCE_DIR"

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

    # 대상 파일이 이미 존재하는 경우 업데이트 여부 확인
    if [[ -f "$target_file" && ! -L "$target_file" ]]; then
      # 파일 내용이 동일한지 확인
      if cmp -s "$source_file" "$target_file"; then
        echo "  파일이 이미 최신 상태임"
        return 0
      else
        echo "  기존 파일과 다름, 백업 후 업데이트"
        cp "$target_file" "$target_file.bak.$(date +%Y%m%d_%H%M%S)"
      fi
    elif [[ -L "$target_file" ]]; then
      echo "  기존 심볼릭 링크 제거"
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
