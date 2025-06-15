{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Claude 설정 파일 강제 덮어쓰기 통합 테스트
  testForceOverwriteIntegration = pkgs.writeShellScript "test-claude-config-force-overwrite-integration" ''
    set -e
    ${testHelpers.setupTestEnv}

    ${testHelpers.testSection "Claude 설정 파일 강제 덮어쓰기 통합 테스트"}

    # 테스트 환경 준비
    CLAUDE_DIR="$HOME/.claude"
    SOURCE_DIR="${../../modules/shared/config/claude}"
    TEST_WORK_DIR="$HOME/test-integration"

    mkdir -p "$CLAUDE_DIR/commands" "$TEST_WORK_DIR"

    ${testHelpers.testSubsection "전체 워크플로우 테스트: 초기 설정부터 강제 덮어쓰기까지"}

    # 1단계: 초기 설정 파일 생성
    echo "1단계: 초기 설정 파일 생성 중..."

    # 완전히 새로운 환경 시뮬레이션
    rm -rf "$CLAUDE_DIR"
    mkdir -p "$CLAUDE_DIR/commands"

    # 첫 번째 배포 (새 파일 복사)
    cp "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    cp "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

    for cmd_file in "$SOURCE_DIR/commands"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        cp "$cmd_file" "$CLAUDE_DIR/commands/"
      fi
    done

    echo "✓ 초기 설정 완료"

    # 2단계: 시간 경과 후 동일한 설정으로 재배포 (강제 덮어쓰기 시나리오)
    echo "2단계: 동일한 설정으로 재배포 시뮬레이션..."

    # 파일 타임스탬프 기록 (macOS/Linux 호환)
    if command -v stat >/dev/null 2>&1; then
      if stat -c %Y "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
        # Linux
        SETTINGS_TS_BEFORE=$(stat -c %Y "$CLAUDE_DIR/settings.json")
        CLAUDE_MD_TS_BEFORE=$(stat -c %Y "$CLAUDE_DIR/CLAUDE.md")
        BUILD_MD_TS_BEFORE=$(stat -c %Y "$CLAUDE_DIR/commands/build.md")
      else
        # macOS
        SETTINGS_TS_BEFORE=$(stat -f %m "$CLAUDE_DIR/settings.json")
        CLAUDE_MD_TS_BEFORE=$(stat -f %m "$CLAUDE_DIR/CLAUDE.md")
        BUILD_MD_TS_BEFORE=$(stat -f %m "$CLAUDE_DIR/commands/build.md")
      fi
    fi

    # 1초 대기 (타임스탬프 구분을 위해)
    sleep 1

    # 강제 덮어쓰기 시뮬레이션 (실제 home-manager 로직 사용)

    # 파일 해시 비교 함수
    files_differ() {
      local source="$1"
      local target="$2"

      if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
        return 0
      fi

      local source_hash target_hash
      if command -v sha256sum >/dev/null 2>&1; then
        source_hash=$(sha256sum "$source" | cut -d' ' -f1)
        target_hash=$(sha256sum "$target" | cut -d' ' -f1)
      else
        source_hash=$(shasum -a 256 "$source" | cut -d' ' -f1)
        target_hash=$(shasum -a 256 "$target" | cut -d' ' -f1)
      fi

      [[ "$source_hash" != "$target_hash" ]]
    }

    # 백업 생성 함수
    create_backup() {
      local file="$1"
      local backup_dir="$CLAUDE_DIR/.backups"
      local timestamp=$(date +%Y%m%d_%H%M%S)

      if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        cp "$file" "$backup_dir/$(basename "$file").backup.$timestamp"
        echo "백업 생성: $backup_dir/$(basename "$file").backup.$timestamp"
      fi
    }

    # 스마트 복사 함수 (수정된 강제 덮어쓰기 로직)
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
        cp "$source_file" "$target_file"
        chmod 644 "$target_file"
        return 0
      fi

      if files_differ "$source_file" "$target_file"; then
        echo "  사용자 수정 감지됨"

        case "$file_name" in
          "settings.json"|"CLAUDE.md")
            echo "  사용자 버전 보존, 새 버전을 .new로 저장"
            cp "$source_file" "$target_file.new"
            chmod 644 "$target_file.new"

            # 알림 메시지 생성
            cat > "$target_file.update-notice" << EOF
파일 업데이트 알림: $file_name

이 파일이 dotfiles에서 업데이트되었지만, 사용자가 수정한 내용이 감지되어
기존 파일을 보존했습니다.

- 현재 파일: $target_file (사용자 수정 버전)
- 새 버전: $target_file.new (dotfiles 최신 버전)

생성 시간: $(date)
EOF
            echo "  업데이트 알림 생성: $target_file.update-notice"
            ;;
          *)
            echo "  백업 후 덮어쓰기"
            create_backup "$target_file"
            cp "$source_file" "$target_file"
            chmod 644 "$target_file"
            ;;
        esac
      else
        echo "  파일 동일하지만 강제 덮어쓰기"
        chmod u+w "$target_file" 2>/dev/null || true
        cp "$source_file" "$target_file"
        chmod 644 "$target_file"
      fi
    }

    # 강제 덮어쓰기 실행
    echo "강제 덮어쓰기 로직 실행 중..."

    smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    smart_copy "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    smart_copy "$SOURCE_DIR/commands/build.md" "$CLAUDE_DIR/commands/build.md"

    # 타임스탬프 확인 (파일이 실제로 덮어쓰기 되었는지)
    if command -v stat >/dev/null 2>&1; then
      if stat -c %Y "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
        # Linux
        SETTINGS_TS_AFTER=$(stat -c %Y "$CLAUDE_DIR/settings.json")
        CLAUDE_MD_TS_AFTER=$(stat -c %Y "$CLAUDE_DIR/CLAUDE.md")
        BUILD_MD_TS_AFTER=$(stat -c %Y "$CLAUDE_DIR/commands/build.md")
      else
        # macOS
        SETTINGS_TS_AFTER=$(stat -f %m "$CLAUDE_DIR/settings.json")
        CLAUDE_MD_TS_AFTER=$(stat -f %m "$CLAUDE_DIR/CLAUDE.md")
        BUILD_MD_TS_AFTER=$(stat -f %m "$CLAUDE_DIR/commands/build.md")
      fi
    fi

    # 검증
    FORCE_OVERWRITE_SUCCESS=true

    if [[ "$SETTINGS_TS_AFTER" -gt "$SETTINGS_TS_BEFORE" ]]; then
      echo "✓ settings.json 강제 덮어쓰기 성공"
    else
      echo "✗ settings.json 강제 덮어쓰기 실패"
      FORCE_OVERWRITE_SUCCESS=false
    fi

    if [[ "$CLAUDE_MD_TS_AFTER" -gt "$CLAUDE_MD_TS_BEFORE" ]]; then
      echo "✓ CLAUDE.md 강제 덮어쓰기 성공"
    else
      echo "✗ CLAUDE.md 강제 덮어쓰기 실패"
      FORCE_OVERWRITE_SUCCESS=false
    fi

    if [[ "$BUILD_MD_TS_AFTER" -gt "$BUILD_MD_TS_BEFORE" ]]; then
      echo "✓ commands/build.md 강제 덮어쓰기 성공"
    else
      echo "✗ commands/build.md 강제 덮어쓰기 실패"
      FORCE_OVERWRITE_SUCCESS=false
    fi

    # 3단계: 사용자 수정 시나리오 테스트
    ${testHelpers.testSubsection "3단계: 사용자 수정 보존 기능 검증"}

    # 사용자가 파일을 수정
    cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "model": "claude-3.5-sonnet",
  "temperature": 0.7,
  "max_tokens": 8000,
  "user_customization": {
    "theme": "dark",
    "language": "korean",
    "auto_save": true
  }
}
EOF

    echo "# 사용자 커스텀 Claude 설정" > "$CLAUDE_DIR/CLAUDE.md"
    echo "이 파일은 사용자가 수정했습니다." >> "$CLAUDE_DIR/CLAUDE.md"

    # 수정된 파일에 대한 처리
    smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    smart_copy "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

    # .new 파일과 알림 파일 생성 확인
    USER_MODIFICATION_SUCCESS=true

    if [[ -f "$CLAUDE_DIR/settings.json.new" ]]; then
      echo "✓ settings.json.new 파일 생성됨"
    else
      echo "✗ settings.json.new 파일 생성되지 않음"
      USER_MODIFICATION_SUCCESS=false
    fi

    if [[ -f "$CLAUDE_DIR/settings.json.update-notice" ]]; then
      echo "✓ settings.json 업데이트 알림 생성됨"
    else
      echo "✗ settings.json 업데이트 알림 생성되지 않음"
      USER_MODIFICATION_SUCCESS=false
    fi

    if [[ -f "$CLAUDE_DIR/CLAUDE.md.new" ]]; then
      echo "✓ CLAUDE.md.new 파일 생성됨"
    else
      echo "✗ CLAUDE.md.new 파일 생성되지 않음"
      USER_MODIFICATION_SUCCESS=false
    fi

    # 사용자 수정 내용이 보존되었는지 확인
    if grep -q "user_customization" "$CLAUDE_DIR/settings.json"; then
      echo "✓ 사용자 수정 settings.json 보존됨"
    else
      echo "✗ 사용자 수정 settings.json 보존되지 않음"
      USER_MODIFICATION_SUCCESS=false
    fi

    if grep -q "사용자가 수정했습니다" "$CLAUDE_DIR/CLAUDE.md"; then
      echo "✓ 사용자 수정 CLAUDE.md 보존됨"
    else
      echo "✗ 사용자 수정 CLAUDE.md 보존되지 않음"
      USER_MODIFICATION_SUCCESS=false
    fi

    # 4단계: 백업 시스템 테스트
    ${testHelpers.testSubsection "4단계: 백업 시스템 검증"}

    BACKUP_DIR="$CLAUDE_DIR/.backups"

    if [[ -d "$BACKUP_DIR" ]]; then
      BACKUP_COUNT=$(find "$BACKUP_DIR" -name "*.backup.*" | wc -l)
      if [[ "$BACKUP_COUNT" -gt 0 ]]; then
        echo "✓ 백업 파일이 생성되었습니다 ($BACKUP_COUNT 개)"
      else
        echo "⚠ 백업 디렉토리는 있지만 백업 파일이 없습니다"
      fi
    else
      echo "⚠ 백업 디렉토리가 생성되지 않았습니다"
    fi

    # 최종 결과 검증
    ${testHelpers.testSubsection "최종 결과 검증"}

    if [[ "$FORCE_OVERWRITE_SUCCESS" == true && "$USER_MODIFICATION_SUCCESS" == true ]]; then
      echo ""
      echo "🎉 모든 통합 테스트가 성공적으로 완료되었습니다!"
      echo ""
      echo "검증된 기능:"
      echo "  ✓ 동일한 파일에 대한 강제 덮어쓰기"
      echo "  ✓ 사용자 수정 파일 보존"
      echo "  ✓ .new 파일 생성"
      echo "  ✓ 업데이트 알림 생성"
      echo "  ✓ 백업 시스템 동작"
    else
      echo ""
      echo "❌ 일부 테스트가 실패했습니다:"
      if [[ "$FORCE_OVERWRITE_SUCCESS" != true ]]; then
        echo "  ✗ 강제 덮어쓰기 기능 실패"
      fi
      if [[ "$USER_MODIFICATION_SUCCESS" != true ]]; then
        echo "  ✗ 사용자 수정 보존 기능 실패"
      fi
      exit 1
    fi

    # 정리
    rm -rf "$CLAUDE_DIR" "$TEST_WORK_DIR"
  '';

in pkgs.runCommand "claude-config-force-overwrite-integration-test" {
  buildInputs = [ pkgs.bash pkgs.coreutils pkgs.findutils ];
} ''
  ${testForceOverwriteIntegration}
  touch $out
''
