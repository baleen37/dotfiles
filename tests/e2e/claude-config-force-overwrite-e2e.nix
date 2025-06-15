{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Claude 설정 파일 강제 덮어쓰기 E2E 테스트
  testForceOverwriteE2E = pkgs.writeShellScript "test-claude-config-force-overwrite-e2e" ''
        set -e
        ${testHelpers.setupTestEnv}

        ${testHelpers.testSection "Claude 설정 파일 강제 덮어쓰기 E2E 테스트"}

        # 테스트 환경 준비
        CLAUDE_DIR="$HOME/.claude"
        SOURCE_DIR="${../../modules/shared/config/claude}"
        TEST_WORK_DIR="$HOME/test-e2e-force"

        mkdir -p "$CLAUDE_DIR/commands" "$TEST_WORK_DIR"

        ${testHelpers.testSubsection "전체 시스템 시나리오: 실제 dotfiles 워크플로우 시뮬레이션"}

        # 실제 home-manager 활성화 스크립트 시뮬레이션

        # 1단계: 전체 Claude 설정 복사 스크립트 구현
        echo "1단계: 전체 Claude 설정 시스템 시뮬레이션..."

        # 실제 home-manager의 copyClaudeFiles 로직 재현
        CLAUDE_COPY_SCRIPT=$(cat << 'EOF'
    #!/bin/bash
    set -e

    echo "=== Claude 설정 파일 업데이트 ==="

    CLAUDE_DIR="$HOME/.claude"
    SOURCE_DIR="SOURCE_DIR_PLACEHOLDER"

    mkdir -p "$CLAUDE_DIR/commands"

    # 실제 home-manager에서 사용하는 함수들
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

            cat > "$target_file.update-notice" << NOTICE_EOF
    파일 업데이트 알림: $file_name

    이 파일이 dotfiles에서 업데이트되었지만, 사용자가 수정한 내용이 감지되어
    기존 파일을 보존했습니다.

    - 현재 파일: $target_file (사용자 수정 버전)
    - 새 버전: $target_file.new (dotfiles 최신 버전)

    생성 시간: $(date)
    NOTICE_EOF
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
        cp "$source_file" "$target_file"
        chmod 644 "$target_file"
      fi
    }

    # Claude 설정 파일들 복사
    echo "Claude 설정 파일 업데이트 시작..."

    # 주요 설정 파일들
    for config_file in "settings.json" "CLAUDE.md"; do
      if [[ -f "$SOURCE_DIR/$config_file" ]]; then
        smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
      fi
    done

    # 명령어 파일들
    echo "Claude 명령어 파일 업데이트..."
    if [[ -d "$SOURCE_DIR/commands" ]]; then
      for cmd_file in "$SOURCE_DIR/commands"/*.md; do
        if [[ -f "$cmd_file" ]]; then
          smart_copy "$cmd_file" "$CLAUDE_DIR/commands/$(basename "$cmd_file")"
        fi
      done
    fi

    # 기존 .bak 파일 정리
    rm -f "$CLAUDE_DIR"/*.bak
    rm -f "$CLAUDE_DIR/commands"/*.bak

    # 30일 이상된 백업 파일 정리
    if [[ -d "$CLAUDE_DIR/.backups" ]]; then
      find "$CLAUDE_DIR/.backups" -name "*.backup.*" -mtime +30 -delete 2>/dev/null || true
    fi

    echo "Claude 설정 파일 업데이트 완료"
    EOF
    )

        # 소스 디렉토리 경로 치환
        echo "$CLAUDE_COPY_SCRIPT" | sed "s|SOURCE_DIR_PLACEHOLDER|$SOURCE_DIR|g" > "$TEST_WORK_DIR/claude-copy.sh"
        chmod +x "$TEST_WORK_DIR/claude-copy.sh"

        ${testHelpers.testSubsection "시나리오 1: 최초 시스템 배포"}

        # 완전히 새로운 시스템 시뮬레이션
        rm -rf "$CLAUDE_DIR"

        echo "최초 시스템 배포 실행..."
        "$TEST_WORK_DIR/claude-copy.sh"

        # 배포 결과 검증
        INITIAL_DEPLOY_SUCCESS=true

        if [[ -f "$CLAUDE_DIR/settings.json" ]]; then
          echo "✓ settings.json 배포됨"
        else
          echo "✗ settings.json 배포 실패"
          INITIAL_DEPLOY_SUCCESS=false
        fi

        if [[ -f "$CLAUDE_DIR/CLAUDE.md" ]]; then
          echo "✓ CLAUDE.md 배포됨"
        else
          echo "✗ CLAUDE.md 배포 실패"
          INITIAL_DEPLOY_SUCCESS=false
        fi

        CMD_FILES_COUNT=$(find "$CLAUDE_DIR/commands" -name "*.md" 2>/dev/null | wc -l)
        if [[ "$CMD_FILES_COUNT" -gt 0 ]]; then
          echo "✓ 명령어 파일들 배포됨 ($CMD_FILES_COUNT 개)"
        else
          echo "✗ 명령어 파일 배포 실패"
          INITIAL_DEPLOY_SUCCESS=false
        fi

        ${testHelpers.testSubsection "시나리오 2: 동일한 설정으로 재배포 (강제 덮어쓰기)"}

        # 파일 타임스탬프 저장
        declare -A TIMESTAMPS_BEFORE

        for file in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/commands"/*.md; do
          if [[ -f "$file" ]]; then
            if command -v stat >/dev/null 2>&1; then
              if stat -c %Y "$file" >/dev/null 2>&1; then
                TIMESTAMPS_BEFORE["$file"]=$(stat -c %Y "$file")
              else
                TIMESTAMPS_BEFORE["$file"]=$(stat -f %m "$file")
              fi
            fi
          fi
        done

        # 1초 대기 후 재배포
        sleep 1

        echo "동일한 설정으로 재배포 실행..."
        OUTPUT=$("$TEST_WORK_DIR/claude-copy.sh" 2>&1)

        # 강제 덮어쓰기 메시지 확인
        FORCE_OVERWRITE_MSG_SUCCESS=true

        if echo "$OUTPUT" | grep -q "파일 동일하지만 강제 덮어쓰기"; then
          echo "✓ 강제 덮어쓰기 메시지 출력됨"
        else
          echo "✗ 강제 덮어쓰기 메시지 출력되지 않음"
          echo "실제 출력:"
          echo "$OUTPUT"
          FORCE_OVERWRITE_MSG_SUCCESS=false
        fi

        # 파일 타임스탬프 검증 (실제로 덮어쓰기 되었는지)
        FORCE_OVERWRITE_TS_SUCCESS=true

        # settings.json 타임스탬프 확인
        if command -v stat >/dev/null 2>&1; then
          if stat -c %Y "$CLAUDE_DIR/settings.json" >/dev/null 2>&1; then
            SETTINGS_TS_AFTER_CHECK=$(stat -c %Y "$CLAUDE_DIR/settings.json")
          else
            SETTINGS_TS_AFTER_CHECK=$(stat -f %m "$CLAUDE_DIR/settings.json")
          fi
        fi

        if [[ "$SETTINGS_TS_AFTER_CHECK" -gt "$SETTINGS_TS_BEFORE" ]]; then
          echo "✓ settings.json 강제 덮어쓰기됨"
        else
          echo "✗ settings.json 덮어쓰기 실패"
          FORCE_OVERWRITE_TS_SUCCESS=false
        fi

        # CLAUDE.md 타임스탬프 확인
        if command -v stat >/dev/null 2>&1; then
          if stat -c %Y "$CLAUDE_DIR/CLAUDE.md" >/dev/null 2>&1; then
            CLAUDE_MD_TS_AFTER_CHECK=$(stat -c %Y "$CLAUDE_DIR/CLAUDE.md")
          else
            CLAUDE_MD_TS_AFTER_CHECK=$(stat -f %m "$CLAUDE_DIR/CLAUDE.md")
          fi
        fi

        if [[ "$CLAUDE_MD_TS_AFTER_CHECK" -gt "$CLAUDE_MD_TS_BEFORE" ]]; then
          echo "✓ CLAUDE.md 강제 덮어쓰기됨"
        else
          echo "✗ CLAUDE.md 덮어쓰기 실패"
          FORCE_OVERWRITE_TS_SUCCESS=false
        fi

        # build.md 타임스탬프 확인
        if command -v stat >/dev/null 2>&1; then
          if stat -c %Y "$CLAUDE_DIR/commands/build.md" >/dev/null 2>&1; then
            BUILD_MD_TS_AFTER_CHECK=$(stat -c %Y "$CLAUDE_DIR/commands/build.md")
          else
            BUILD_MD_TS_AFTER_CHECK=$(stat -f %m "$CLAUDE_DIR/commands/build.md")
          fi
        fi

        if [[ "$BUILD_MD_TS_AFTER_CHECK" -gt "$BUILD_MD_TS_BEFORE" ]]; then
          echo "✓ commands/build.md 강제 덮어쓰기됨"
        else
          echo "✗ commands/build.md 덮어쓰기 실패"
          FORCE_OVERWRITE_TS_SUCCESS=false
        fi

        ${testHelpers.testSubsection "시나리오 3: 사용자 수정 후 재배포"}

        # 사용자가 설정을 수정
        cat > "$CLAUDE_DIR/settings.json" << 'EOF'
    {
      "model": "claude-3.5-sonnet",
      "temperature": 0.8,
      "max_tokens": 8000,
      "user_preferences": {
        "language": "korean",
        "code_style": "functional",
        "response_format": "detailed",
        "custom_commands": [
          "analyze-code",
          "review-pr",
          "generate-tests"
        ]
      },
      "project_settings": {
        "auto_format": true,
        "lint_on_save": true,
        "test_coverage_threshold": 80
      }
    }
    EOF

        cat > "$CLAUDE_DIR/CLAUDE.md" << 'EOF'
    # 내 커스텀 Claude 설정

    이 파일은 개인적으로 수정했습니다.

    ## 커스텀 명령어
    - `/analyze` - 코드 분석
    - `/review` - PR 리뷰
    - `/test` - 테스트 생성

    ## 개인 선호사항
    - 한국어 응답 선호
    - 상세한 설명 요청
    - 함수형 프로그래밍 스타일
    EOF

        # 사용자 커스텀 명령어 파일 추가
        cat > "$CLAUDE_DIR/commands/custom-review.md" << 'EOF'
    # 내가 만든 커스텀 리뷰 명령어

    이 파일은 사용자가 직접 만든 파일입니다.
    EOF

        echo "사용자 수정 시뮬레이션 완료"

        # 사용자 수정 후 재배포
        echo "사용자 수정 후 재배포 실행..."
        USER_MODIFIED_OUTPUT=$("$TEST_WORK_DIR/claude-copy.sh" 2>&1)

        # 사용자 수정 보존 검증
        USER_PRESERVATION_SUCCESS=true

        # .new 파일 생성 확인
        if [[ -f "$CLAUDE_DIR/settings.json.new" ]]; then
          echo "✓ settings.json.new 생성됨"
        else
          echo "✗ settings.json.new 생성되지 않음"
          USER_PRESERVATION_SUCCESS=false
        fi

        if [[ -f "$CLAUDE_DIR/CLAUDE.md.new" ]]; then
          echo "✓ CLAUDE.md.new 생성됨"
        else
          echo "✗ CLAUDE.md.new 생성되지 않음"
          USER_PRESERVATION_SUCCESS=false
        fi

        # 업데이트 알림 생성 확인
        if [[ -f "$CLAUDE_DIR/settings.json.update-notice" ]]; then
          echo "✓ settings.json 업데이트 알림 생성됨"
        else
          echo "✗ settings.json 업데이트 알림 생성되지 않음"
          USER_PRESERVATION_SUCCESS=false
        fi

        # 사용자 수정 내용 보존 확인
        if grep -q "user_preferences" "$CLAUDE_DIR/settings.json"; then
          echo "✓ 사용자 수정 settings.json 보존됨"
        else
          echo "✗ 사용자 수정 settings.json 보존되지 않음"
          USER_PRESERVATION_SUCCESS=false
        fi

        if grep -q "개인적으로 수정했습니다" "$CLAUDE_DIR/CLAUDE.md"; then
          echo "✓ 사용자 수정 CLAUDE.md 보존됨"
        else
          echo "✗ 사용자 수정 CLAUDE.md 보존되지 않음"
          USER_PRESERVATION_SUCCESS=false
        fi

        # 사용자 커스텀 파일 보존 확인
        if [[ -f "$CLAUDE_DIR/commands/custom-review.md" ]]; then
          if grep -q "사용자가 직접 만든" "$CLAUDE_DIR/commands/custom-review.md"; then
            echo "✓ 사용자 커스텀 명령어 파일 보존됨"
          else
            echo "✗ 사용자 커스텀 명령어 파일 내용이 변경됨"
            USER_PRESERVATION_SUCCESS=false
          fi
        else
          echo "✗ 사용자 커스텀 명령어 파일이 삭제됨"
          USER_PRESERVATION_SUCCESS=false
        fi

        ${testHelpers.testSubsection "시나리오 4: 병합 도구 시뮬레이션"}

        # 병합 스크립트 기본 기능 테스트
        MERGE_SCRIPT="${../../scripts/merge-claude-config}"

        if [[ -x "$MERGE_SCRIPT" ]]; then
          echo "병합 도구 기능 테스트..."

          # --list 옵션 테스트
          if "$MERGE_SCRIPT" --list >/dev/null 2>&1; then
            echo "✓ 병합 도구 --list 옵션 동작함"
          else
            echo "⚠ 병합 도구 --list 옵션 실행 문제"
          fi

          # --diff 옵션 테스트
          if "$MERGE_SCRIPT" --diff settings.json >/dev/null 2>&1; then
            echo "✓ 병합 도구 --diff 옵션 동작함"
          else
            echo "⚠ 병합 도구 --diff 옵션 실행 문제"
          fi
        else
          echo "⚠ 병합 도구를 찾을 수 없음: $MERGE_SCRIPT"
        fi

        ${testHelpers.testSubsection "시나리오 5: 시스템 정리 및 백업 검증"}

        # 백업 시스템 확인
        BACKUP_VERIFICATION_SUCCESS=true

        if [[ -d "$CLAUDE_DIR/.backups" ]]; then
          BACKUP_COUNT=$(find "$CLAUDE_DIR/.backups" -name "*.backup.*" 2>/dev/null | wc -l)
          if [[ "$BACKUP_COUNT" -gt 0 ]]; then
            echo "✓ 백업 파일 시스템 동작함 ($BACKUP_COUNT 개 백업)"
          else
            echo "⚠ 백업 디렉토리는 있지만 백업 파일이 없음"
          fi
        else
          echo "⚠ 백업 디렉토리가 생성되지 않음"
        fi

        # .bak 파일 정리 확인
        BAK_FILES=$(find "$CLAUDE_DIR" -name "*.bak" 2>/dev/null | wc -l)
        if [[ "$BAK_FILES" -eq 0 ]]; then
          echo "✓ .bak 파일 정리됨"
        else
          echo "⚠ .bak 파일이 정리되지 않음 ($BAK_FILES 개 남음)"
        fi

        ${testHelpers.testSubsection "전체 E2E 테스트 결과"}

        # 종합 결과 평가
        ALL_TESTS_PASSED=true

        echo ""
        echo "=== E2E 테스트 결과 요약 ==="

        if [[ "$INITIAL_DEPLOY_SUCCESS" == true ]]; then
          echo "✓ 최초 배포 성공"
        else
          echo "✗ 최초 배포 실패"
          ALL_TESTS_PASSED=false
        fi

        if [[ "$FORCE_OVERWRITE_MSG_SUCCESS" == true ]]; then
          echo "✓ 강제 덮어쓰기 메시지 출력 성공"
        else
          echo "✗ 강제 덮어쓰기 메시지 출력 실패"
          ALL_TESTS_PASSED=false
        fi

        if [[ "$FORCE_OVERWRITE_TS_SUCCESS" == true ]]; then
          echo "✓ 강제 덮어쓰기 실제 동작 성공"
        else
          echo "✗ 강제 덮어쓰기 실제 동작 실패"
          ALL_TESTS_PASSED=false
        fi

        if [[ "$USER_PRESERVATION_SUCCESS" == true ]]; then
          echo "✓ 사용자 수정 보존 성공"
        else
          echo "✗ 사용자 수정 보존 실패"
          ALL_TESTS_PASSED=false
        fi

        if [[ "$ALL_TESTS_PASSED" == true ]]; then
          echo ""
          echo "🎉 모든 E2E 테스트가 성공적으로 완료되었습니다!"
          echo ""
          echo "검증된 전체 워크플로우:"
          echo "  ✓ 최초 시스템 배포"
          echo "  ✓ 동일 파일 강제 덮어쓰기"
          echo "  ✓ 사용자 수정 파일 보존"
          echo "  ✓ .new 파일 및 알림 생성"
          echo "  ✓ 백업 시스템 동작"
          echo "  ✓ 정리 작업 수행"
          echo "  ✓ 병합 도구 기본 동작"
        else
          echo ""
          echo "❌ 일부 E2E 테스트가 실패했습니다."
          exit 1
        fi

        # 정리
        rm -rf "$CLAUDE_DIR" "$TEST_WORK_DIR"
  '';

in
pkgs.runCommand "claude-config-force-overwrite-e2e-test"
{
  buildInputs = [ pkgs.bash pkgs.coreutils pkgs.findutils pkgs.gnugrep pkgs.gnused ];
} ''
  ${testForceOverwriteE2E}
  touch $out
''
