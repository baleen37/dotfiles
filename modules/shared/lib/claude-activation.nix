# Shared Claude configuration management system
# This module provides cross-platform Claude configuration file management
# with simple folder-level symlink approach for maximum simplicity.

{ config, lib, self ? null, platform ? "unknown" }:

let
  claudeDir = "${config.home.homeDirectory}/.claude";

  # Intelligent source directory resolution with fallback system
  # Priority: 1. dev/dotfiles path 2. dotfiles path 3. relative path 4. self (Nix store) as last resort
  sourceDir = "${config.home.homeDirectory}/dev/dotfiles/modules/shared/config/claude";

  # Backup source directories to try if primary fails
  fallbackSources = [
    "${config.home.homeDirectory}/dotfiles/modules/shared/config/claude" # legacy dotfiles location
    "./modules/shared/config/claude" # relative path fallback
    "/Users/jito/dev/dotfiles/modules/shared/config/claude" # absolute path fallback (for jito)
  ] ++ (if self != null then [ "${self}/modules/shared/config/claude" ] else [ ]);

in
''
  set -euo pipefail  # Enable strict error handling

  CLAUDE_DIR="${claudeDir}"
  SOURCE_DIR="${sourceDir}"
  FALLBACK_SOURCES=(${lib.concatStringsSep " " (map (s: "\"${s}\"") fallbackSources)})

  echo "=== Claude 설정 심볼릭 링크 업데이트 시작 ==="
  echo "Claude 디렉토리: $CLAUDE_DIR"
  echo "기본 소스 디렉토리: $SOURCE_DIR"
  echo "Self 매개변수: ${if self != null then "사용 중 (Nix store)" else "없음 (상대 경로)"}"
  echo ""

  # Claude 설정 완전성 검증 함수
  validate_claude_config_completeness() {
    local config_dir="$1"
    local commands_dir="$config_dir/commands"

    # 핵심 설정 파일들 확인
    local essential_files=(
      "$config_dir/CLAUDE.md"
      "$config_dir/settings.json"
      "$commands_dir"
    )

    # 중요한 명령어 파일들 확인 (누락되면 문제가 되는 파일들)
    local essential_commands=(
      "$commands_dir/analyze.md"
      "$commands_dir/build.md"
      "$commands_dir/do-todo.md"
      "$commands_dir/implement.md"
      "$commands_dir/test.md"
    )

    # 기본 구조 확인
    for file in "''${essential_files[@]}"; do
      if [[ ! -e "$file" ]]; then
        echo "  누락된 핵심 파일/디렉토리: $(basename "$file")"
        return 1
      fi
    done

    # 명령어 파일들 확인 (전체가 아니라 핵심만)
    local missing_commands=0
    for cmd_file in "''${essential_commands[@]}"; do
      if [[ ! -f "$cmd_file" ]]; then
        echo "  누락된 핵심 명령어: $(basename "$cmd_file")"
        ((missing_commands++))
      fi
    done

    # 핵심 명령어 중 50% 이상 누락되면 불완전하다고 판단
    local total_commands=''${#essential_commands[@]}
    local threshold=$((total_commands / 2))

    if [[ $missing_commands -gt $threshold ]]; then
      echo "  너무 많은 핵심 명령어 누락 ($missing_commands/$total_commands)"
      return 1
    fi

    return 0
  }

  # 소스 디렉토리 유효성 검사 및 fallback (완전성 검증 포함)
  ACTUAL_SOURCE_DIR=""

  if [[ -d "$SOURCE_DIR" ]] && validate_claude_config_completeness "$SOURCE_DIR"; then
    ACTUAL_SOURCE_DIR="$SOURCE_DIR"
    echo "✓ 기본 소스 디렉토리가 완전함: $SOURCE_DIR"
  else
    if [[ -d "$SOURCE_DIR" ]]; then
      echo "⚠ 기본 소스 디렉토리가 불완전함: $SOURCE_DIR"
    else
      echo "⚠ 기본 소스 디렉토리 없음: $SOURCE_DIR"
    fi
    echo "Fallback 디렉토리들 확인 중..."

    for fallback_dir in "''${FALLBACK_SOURCES[@]}"; do
      echo "  시도 중: $fallback_dir"
      if [[ -d "$fallback_dir" ]] && validate_claude_config_completeness "$fallback_dir"; then
        ACTUAL_SOURCE_DIR="$fallback_dir"
        echo "  ✓ 완전한 Fallback 소스 발견: $fallback_dir"
        break
      elif [[ -d "$fallback_dir" ]]; then
        echo "  ⚠ Fallback 디렉토리는 존재하지만 불완전함: $fallback_dir"
      fi
    done

    if [[ -z "$ACTUAL_SOURCE_DIR" ]]; then
      echo "❌ 오류: 완전한 Claude 설정 소스 디렉토리를 찾을 수 없습니다!"
      echo "확인한 경로들:"
      echo "  - $SOURCE_DIR (기본)"
      for fallback_dir in "''${FALLBACK_SOURCES[@]}"; do
        echo "  - $fallback_dir (fallback)"
      done
      echo ""
      echo "해결 방법:"
      echo "1. dotfiles를 올바른 위치에 clone했는지 확인"
      echo "2. Claude 설정 파일들이 모두 존재하는지 확인"
      echo "3. 'make build' 또는 'make switch' 실행"
      echo "4. Nix flake가 올바르게 설정되었는지 확인"
      exit 1
    fi
  fi

  echo "사용할 소스 디렉토리: $ACTUAL_SOURCE_DIR"

  # Claude 디렉토리 생성 (Claude Code가 관리하는 다른 폴더들 보존)
  mkdir -p "$CLAUDE_DIR"

  # 기존 개별 파일 심볼릭 링크들과 .new, .update-notice 파일들 정리
  echo "기존 설정 파일들 정리..."
  rm -f "$CLAUDE_DIR"/*.new "$CLAUDE_DIR"/*.update-notice "$CLAUDE_DIR"/*.bak

  # 폴더 심볼릭 링크 생성 함수 (검증 포함)
  create_folder_symlink() {
    local source_folder="$1"
    local target_folder="$2"
    local folder_name=$(basename "$source_folder")

    echo "처리 중: $folder_name/"

    if [[ ! -d "$source_folder" ]]; then
      echo "  소스 폴더 없음, 건너뜀"
      return 0
    fi

    # 소스 폴더 내용 검증 (commands 폴더의 경우)
    if [[ "$folder_name" == "commands" ]]; then
      local file_count
      file_count=$(find "$source_folder" -name "*.md" -type f 2>/dev/null | wc -l)
      file_count=$(echo "$file_count" | tr -d ' ')  # 공백 제거

      if [[ $file_count -lt 5 ]]; then
        echo "  ⚠ 경고: commands 폴더에 파일이 적음 (''${file_count}개). 불완전한 설정일 수 있음"
      else
        echo "  ✓ commands 폴더 검증 통과 (''${file_count}개 명령어 파일)"
      fi

      # 핵심 명령어 파일 존재 확인
      local essential_commands=("analyze.md" "build.md" "do-todo.md" "implement.md" "test.md")
      local missing_count=0
      for cmd in "''${essential_commands[@]}"; do
        if [[ ! -f "$source_folder/$cmd" ]]; then
          ((missing_count++))
        fi
      done

      if [[ $missing_count -gt 0 ]]; then
        echo "  ⚠ 경고: ''${missing_count}개의 핵심 명령어 파일이 누락됨"
      else
        echo "  ✓ 모든 핵심 명령어 파일 존재 확인"
      fi
    fi

    # 기존 폴더나 링크가 있으면 제거
    if [[ -e "$target_folder" || -L "$target_folder" ]]; then
      echo "  기존 $folder_name 폴더/링크 제거"
      rm -rf "$target_folder"
    fi

    # 폴더 심볼릭 링크 생성
    ln -sf "$source_folder" "$target_folder"
    echo "  폴더 심볼릭 링크 생성: $target_folder -> $source_folder"

    # 생성된 심볼릭 링크 검증
    if [[ -L "$target_folder" && -d "$target_folder" ]]; then
      echo "  ✓ 심볼릭 링크 생성 및 접근 확인"

      # commands 폴더의 경우 핵심 파일 접근성 테스트
      if [[ "$folder_name" == "commands" ]]; then
        if [[ -f "$target_folder/do-todo.md" ]]; then
          echo "  ✓ do-todo.md 파일 접근 가능 확인"
        else
          echo "  ⚠ 경고: do-todo.md 파일에 접근할 수 없음"
        fi
      fi
    else
      echo "  ❌ 오류: 심볼릭 링크 생성 실패 또는 접근 불가"
      return 1
    fi
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
  create_folder_symlink "$ACTUAL_SOURCE_DIR/commands" "$CLAUDE_DIR/commands"
  create_folder_symlink "$ACTUAL_SOURCE_DIR/agents" "$CLAUDE_DIR/agents"
  create_folder_symlink "$ACTUAL_SOURCE_DIR/hooks" "$CLAUDE_DIR/hooks"

  # 2. 루트 레벨 설정 파일들 (.md, .json)
  for source_file in "$ACTUAL_SOURCE_DIR"/*.md "$ACTUAL_SOURCE_DIR"/*.json; do
    if [[ -f "$source_file" ]]; then
      file_name=$(basename "$source_file")

      # 모든 설정 파일들을 심볼릭 링크로 유지
      create_file_symlink "$source_file" "$CLAUDE_DIR/$file_name"
    fi
  done

  # 끊어진 심볼릭 링크 정리

  # 루트 레벨에서 끊어진 링크 찾아 제거
  find "$CLAUDE_DIR" -maxdepth 1 -type l | while read -r link_file; do
    if [[ ! -e "$link_file" ]]; then
      echo "  끊어진 링크 삭제: $(basename "$link_file")"
      rm -f "$link_file"
    fi
  done

  echo ""
  echo "✅ Claude 설정 심볼릭 링크 생성 완료!"
  echo "=== Claude 설정 심볼릭 링크 업데이트 완료 ==="
''
