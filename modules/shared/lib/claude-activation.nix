# Shared Claude configuration management system
# This module provides cross-platform Claude configuration file management
# with intelligent preservation of user modifications and automatic backups.

{ config, lib, self ? null, platform ? "unknown" }:

let
  claudeDir = "${config.home.homeDirectory}/.claude";
  # Fallback to relative path if self is not available
  sourceDir = if self != null
    then "${self}/modules/shared/config/claude"
    else "./modules/shared/config/claude";

  # Platform-specific hash command selection
  hashCommand = if platform == "darwin" then ''
    # macOS에서는 shasum 또는 sha256sum 사용
    local source_hash=""
    local target_hash=""

    if command -v shasum >/dev/null 2>&1; then
      source_hash=$(shasum -a 256 "$source" | cut -d' ' -f1)
      target_hash=$(shasum -a 256 "$target" | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
      source_hash=$(sha256sum "$source" | cut -d' ' -f1)
      target_hash=$(sha256sum "$target" | cut -d' ' -f1)
    else
      # Fallback: Nix의 nix-hash 사용
      source_hash=$(nix-hash --type sha256 --flat "$source")
      target_hash=$(nix-hash --type sha256 --flat "$target")
    fi
  '' else ''
    # Linux에서는 sha256sum 사용
    local source_hash=$(sha256sum "$source" | cut -d' ' -f1)
    local target_hash=$(sha256sum "$target" | cut -d' ' -f1)
  '';

in ''
  set -euo pipefail  # Enable strict error handling

  # DRY_RUN_CMD 변수 초기화 (DRY_RUN이 정의되지 않은 경우 기본값 설정)
  DRY_RUN_CMD=""
  if [[ "''${DRY_RUN:-}" == "1" ]]; then
    DRY_RUN_CMD="echo '[DRY RUN]'"
  fi

  $DRY_RUN_CMD mkdir -p "${claudeDir}/commands"

  CLAUDE_DIR="${claudeDir}"
  SOURCE_DIR="${sourceDir}"
  echo "=== 스마트 Claude 설정 업데이트 시작 ==="
  echo "Claude 디렉토리: $CLAUDE_DIR"
  echo "소스 디렉토리: $SOURCE_DIR"

  # 파일 해시 비교 함수
  files_differ() {
    local source="$1"
    local target="$2"

    if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
      return 0  # 파일이 없으면 다른 것으로 간주
    fi

    ${hashCommand}
    [[ "$source_hash" != "$target_hash" ]]
  }

  # 백업 생성 함수
  create_backup() {
    local file="$1"
    local backup_dir="$CLAUDE_DIR/.backups"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    if [[ -f "$file" ]]; then
      $DRY_RUN_CMD mkdir -p "$backup_dir"
      $DRY_RUN_CMD cp "$file" "$backup_dir/$(basename "$file").backup.$timestamp"
      echo "백업 생성: $backup_dir/$(basename "$file").backup.$timestamp"
    fi
  }

  # 조건부 복사 함수 (사용자 수정 보존)
  smart_copy() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")

    echo "처리 중: $file_name"

    if [[ ! -f "$source_file" ]]; then
      echo "  소스 파일 없음, 건너뜀"
      return 0
    fi

    if [[ ! -f "$target_file" ]]; then
      echo "  새 파일 복사"
      $DRY_RUN_CMD cp "$source_file" "$target_file"
      $DRY_RUN_CMD chmod 644 "$target_file"
      return 0
    fi

    if files_differ "$source_file" "$target_file"; then
      echo "  사용자 수정 감지됨"

      # 높은 우선순위 파일들은 보존 (settings.json, CLAUDE.md)
      case "$file_name" in
        "settings.json"|"CLAUDE.md")
          echo "  사용자 버전 보존, 새 버전을 .new로 저장"
          $DRY_RUN_CMD cp "$source_file" "$target_file.new"
          $DRY_RUN_CMD chmod 644 "$target_file.new"

          # 사용자 알림 메시지 생성
          if [[ "$DRY_RUN_CMD" == "" ]]; then
            cat > "$target_file.update-notice" << EOF
파일 업데이트 알림: $file_name

이 파일이 dotfiles에서 업데이트되었지만, 사용자가 수정한 내용이 감지되어
기존 파일을 보존했습니다.

- 현재 파일: $target_file (사용자 수정 버전)
- 새 버전: $target_file.new (dotfiles 최신 버전)

변경 사항을 확인하고 수동으로 병합하세요:
  diff "$target_file" "$target_file.new"

병합 완료 후 다음 파일들을 삭제하세요:
  rm "$target_file.new" "$target_file.update-notice"

생성 시간: $(date)
EOF
            echo "  업데이트 알림 생성: $target_file.update-notice"
          fi
          ;;
        *)
          echo "  백업 후 덮어쓰기"
          create_backup "$target_file"
          $DRY_RUN_CMD cp "$source_file" "$target_file"
          $DRY_RUN_CMD chmod 644 "$target_file"
          ;;
      esac
    else
      # 파일이 심볼릭 링크인 경우에만 실제 파일로 변환
      if [[ -L "$target_file" ]]; then
        echo "  심볼릭 링크를 실제 파일로 변환"
        local link_target=$(readlink "$target_file")
        $DRY_RUN_CMD rm "$target_file"
        $DRY_RUN_CMD cp "$link_target" "$target_file"
        $DRY_RUN_CMD chmod 644 "$target_file"
      else
        echo "  파일 동일, 건너뜀"
      fi
    fi
  }

  # symlink를 실제 파일로 변환하는 함수
  convert_symlink() {
    local file="$1"
    if [[ -L "$file" ]]; then
      local target=$(readlink "$file")
      if [[ -n "$target" && -f "$target" ]]; then
        echo "심볼릭 링크를 실제 파일로 변환: $(basename "$file")"
        $DRY_RUN_CMD rm "$file"
        $DRY_RUN_CMD cp "$target" "$file"
        $DRY_RUN_CMD chmod 644 "$file"
      fi
    fi
  }

  # 기존 home-manager backup 파일 정리 (우리가 직접 관리하므로)
  echo "기존 백업 파일 정리..."
  $DRY_RUN_CMD rm -f "$CLAUDE_DIR"/*.bak
  $DRY_RUN_CMD rm -f "$CLAUDE_DIR/commands"/*.bak

  # 먼저 symlink들을 실제 파일로 변환
  for config_file in "CLAUDE.md" "settings.json"; do
    target_file="$CLAUDE_DIR/$config_file"
    if [[ -L "$target_file" ]]; then
      convert_symlink "$target_file"
    fi
  done

  for cmd_file in "$CLAUDE_DIR/commands"/*.md; do
    if [[ -L "$cmd_file" ]]; then
      convert_symlink "$cmd_file"
    fi
  done

  # 스마트 복사 실행
  echo ""
  echo "=== Claude 설정 파일 업데이트 ==="

  # 메인 설정 파일들 처리
  for config_file in "settings.json" "CLAUDE.md"; do
    smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
  done

  # commands 디렉토리 처리
  if [[ -d "$SOURCE_DIR/commands" ]]; then
    for cmd_file in "$SOURCE_DIR/commands"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        base_name=$(basename "$cmd_file")
        smart_copy "$cmd_file" "$CLAUDE_DIR/commands/$base_name"
      fi
    done
  fi

  # 소스에 없는 파일을 찾아서 삭제하는 함수
  sync_and_clean_files() {
    echo ""
    echo "소스에 없는 파일 정리 중..."

    # 임시 파일로 소스 파일 목록 생성
    local source_list_file=$(mktemp)

    # 루트 디렉토리 파일들
    for f in "$SOURCE_DIR"/*.md "$SOURCE_DIR"/*.json; do
      [[ -f "$f" ]] && echo "$(basename "$f")" >> "$source_list_file"
    done

    # commands 디렉토리 파일들
    for f in "$SOURCE_DIR/commands"/*.md; do
      [[ -f "$f" ]] && echo "commands/$(basename "$f")" >> "$source_list_file"
    done

    # 타겟의 파일들 확인
    for target_file in "$CLAUDE_DIR"/*.md "$CLAUDE_DIR"/*.json "$CLAUDE_DIR/commands"/*.md; do
      [[ -f "$target_file" ]] || continue

      # 상대 경로 계산
      local rel_path="''${target_file#$CLAUDE_DIR/}"

      # .new, .bak, .update-notice 파일은 건너뛰기
      case "$rel_path" in
        *.new|*.bak|*.update-notice) continue ;;
      esac

      # 소스에 해당 파일이 있는지 확인
      if ! grep -Fxq "$rel_path" "$source_list_file"; then
        echo "  더 이상 사용하지 않는 파일 삭제: $rel_path"
        $DRY_RUN_CMD rm -f "$target_file"
      fi
    done

    # 임시 파일 정리
    rm -f "$source_list_file"
  }

  # 소스에 없는 파일 삭제
  sync_and_clean_files

  # 오래된 백업 파일 정리 (30일 이상)
  if [[ -d "$CLAUDE_DIR/.backups" ]]; then
    echo ""
    echo "오래된 백업 파일 정리 중..."
    $DRY_RUN_CMD find "$CLAUDE_DIR/.backups" -name "*.backup.*" -mtime +30 -delete 2>/dev/null || true
  fi

  # 사용자 알림 요약
  NOTICE_COUNT=$(find "$CLAUDE_DIR" -name "*.update-notice" 2>/dev/null | wc -l || echo "0")
  NOTICE_COUNT=$${NOTICE_COUNT:-0}
  if [[ $NOTICE_COUNT -gt 0 ]]; then
    echo ""
    echo "주의: $NOTICE_COUNT개의 업데이트 알림이 생성되었습니다."
    echo "다음 명령어로 확인하세요: find $CLAUDE_DIR -name '*.update-notice'"
    echo ""
  fi

  echo "=== Claude 설정 업데이트 완료 ==="
''
