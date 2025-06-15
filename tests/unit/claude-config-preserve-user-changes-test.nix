{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # 사용자 수정 내용을 보존하는 이상적인 동작을 정의하는 테스트
  testPreserveUserChanges = pkgs.writeShellScript "test-preserve-user-changes" ''
        set -e
        ${testHelpers.setupTestEnv}

        ${testHelpers.testSection "사용자 수정 내용 보존 테스트 (이상적인 동작)"}

        # 테스트 환경 준비
        CLAUDE_DIR="$HOME/.claude"
        mkdir -p "$CLAUDE_DIR/commands"

        ${testHelpers.testSubsection "초기 설정 파일 생성 (dotfiles 원본)"}

        # 초기 dotfiles에서 생성된 설정 파일들
        cp ${../../modules/shared/config/claude/settings.json} "$CLAUDE_DIR/settings.json"
        cp ${../../modules/shared/config/claude/CLAUDE.md} "$CLAUDE_DIR/CLAUDE.md"

        # 파일 해시 저장 (원본 상태 추적용)
        ORIGINAL_SETTINGS_HASH=$(sha256sum "$CLAUDE_DIR/settings.json" | cut -d' ' -f1)
        ORIGINAL_CLAUDE_HASH=$(sha256sum "$CLAUDE_DIR/CLAUDE.md" | cut -d' ' -f1)

        echo "✓ 초기 설정 파일 생성 완료"
        echo "  - settings.json 원본 해시: $ORIGINAL_SETTINGS_HASH"
        echo "  - CLAUDE.md 원본 해시: $ORIGINAL_CLAUDE_HASH"

        ${testHelpers.testSubsection "사용자 수정 시뮬레이션"}

        # 사용자가 settings.json 수정
        cat > "$CLAUDE_DIR/settings.json" << 'EOF'
    {
      "model": "user-preferred-model",
      "temperature": 0.8,
      "max_tokens": 4000,
      "custom_prompts": {
        "korean": "한국어로 대답해주세요",
        "debug": "디버깅 모드로 실행해주세요"
      },
      "user_preferences": {
        "theme": "dark",
        "auto_save": true
      }
    }
    EOF

        # 사용자가 CLAUDE.md에 커스텀 섹션 추가
        cat >> "$CLAUDE_DIR/CLAUDE.md" << 'EOF'

    # 개인 설정 (사용자 추가)

    ## 나만의 작업 규칙
    - 항상 한국어로 소통
    - 코드 리뷰 시 성능도 고려
    - 테스트 커버리지 90% 이상 유지

    ## 자주 사용하는 명령어
    - `make lint && make test` - 코드 검증
    - `nix run .#build-switch` - 시스템 적용

    ## 커스텀 워크플로우
    1. 기능 구현
    2. 테스트 작성
    3. 리팩토링
    4. 문서 업데이트
    EOF

        # 사용자가 커스텀 명령어 생성
        cat > "$CLAUDE_DIR/commands/my-workflow.md" << 'EOF'
    # 나만의 개발 워크플로우

    ## 목적
    개인적으로 자주 사용하는 개발 패턴을 자동화

    ## 단계
    1. Git branch 생성
    2. TDD로 기능 구현
    3. 코드 리뷰 요청
    4. 병합 후 배포

    ## 사용법
    ```bash
    git checkout -b feature/new-feature
    # 구현...
    git push origin feature/new-feature
    ```
    EOF

        # 수정된 파일 해시 계산
        MODIFIED_SETTINGS_HASH=$(sha256sum "$CLAUDE_DIR/settings.json" | cut -d' ' -f1)
        MODIFIED_CLAUDE_HASH=$(sha256sum "$CLAUDE_DIR/CLAUDE.md" | cut -d' ' -f1)

        echo "✓ 사용자 수정 완료"
        echo "  - settings.json 수정 해시: $MODIFIED_SETTINGS_HASH"
        echo "  - CLAUDE.md 수정 해시: $MODIFIED_CLAUDE_HASH"

        # 해시가 변경되었는지 확인
        if [[ "$ORIGINAL_SETTINGS_HASH" != "$MODIFIED_SETTINGS_HASH" ]]; then
          echo "✓ settings.json이 사용자에 의해 수정됨"
        else
          echo "✗ settings.json 수정이 감지되지 않음"
          exit 1
        fi

        if [[ "$ORIGINAL_CLAUDE_HASH" != "$MODIFIED_CLAUDE_HASH" ]]; then
          echo "✓ CLAUDE.md가 사용자에 의해 수정됨"
        else
          echo "✗ CLAUDE.md 수정이 감지되지 않음"
          exit 1
        fi

        ${testHelpers.testSubsection "이상적인 보존 로직 시뮬레이션"}

        # 이상적인 동작을 정의하는 함수 (아직 구현되지 않음)
        preserve_user_changes() {
          local file="$1"
          local source_file="''${file##*/}"
          local nix_store_file=""

          # 원본 파일 경로 설정
          case "$source_file" in
            "settings.json")
              nix_store_file="${../../modules/shared/config/claude/settings.json}"
              ;;
            "CLAUDE.md")
              nix_store_file="${../../modules/shared/config/claude/CLAUDE.md}"
              ;;
            *.md)
              if [[ -f ${../../modules/shared/config/claude/commands}/$source_file ]]; then
                nix_store_file="${../../modules/shared/config/claude/commands}/$source_file"
              fi
              ;;
          esac

          if [[ -f "$file" && -f "$nix_store_file" ]]; then
            # 현재 파일과 원본 파일의 해시 비교
            current_hash=$(sha256sum "$file" | cut -d' ' -f1)
            original_hash=$(sha256sum "$nix_store_file" | cut -d' ' -f1)

            if [[ "$current_hash" == "$original_hash" ]]; then
              # 수정되지 않은 파일: 그대로 유지 (또는 새 버전으로 업데이트)
              echo "File $file unchanged, keeping current version"
            else
              # 수정된 파일: 사용자 버전 보존, 새 버전을 .new로 저장
              if [[ "$current_hash" != "$original_hash" ]]; then
                cp "$nix_store_file" "$file.new"
                chmod 644 "$file.new"
                echo "User modified $file preserved, new version saved as $file.new"

                # 사용자에게 알림 메시지 생성
                cat > "$file.update-notice" << EOF
    파일 업데이트 알림: $source_file

    이 파일이 dotfiles에서 업데이트되었지만, 사용자가 수정한 내용이 감지되어
    기존 파일을 보존했습니다.

    - 현재 파일: $file (사용자 수정 버전)
    - 새 버전: $file.new (dotfiles 최신 버전)

    변경 사항을 확인하고 수동으로 병합하세요:
      diff "$file" "$file.new"

    병합 완료 후 알림 파일을 삭제하세요:
      rm "$file.update-notice"
    EOF
                echo "Update notice created: $file.update-notice"
              fi
            fi
          fi
        }

        # dotfiles에 새로운 내용이 추가된 상황 시뮬레이션
        # (실제로는 새로운 dotfiles 버전을 가정)
        echo "=== 시스템 재빌드 시뮬레이션 (dotfiles 업데이트) ==="

        # 이상적인 보존 로직 실행
        preserve_user_changes "$CLAUDE_DIR/settings.json"
        preserve_user_changes "$CLAUDE_DIR/CLAUDE.md"
        preserve_user_changes "$CLAUDE_DIR/commands/my-workflow.md"

        ${testHelpers.testSubsection "보존 동작 검증"}

        # 1. 사용자 수정 내용이 보존되었는지 확인
        if grep -q "user-preferred-model" "$CLAUDE_DIR/settings.json"; then
          echo "✓ settings.json 사용자 수정 내용 보존됨"
        else
          echo "✗ settings.json 사용자 수정 내용이 손실됨"
          exit 1
        fi

        if grep -q "나만의 작업 규칙" "$CLAUDE_DIR/CLAUDE.md"; then
          echo "✓ CLAUDE.md 사용자 수정 내용 보존됨"
        else
          echo "✗ CLAUDE.md 사용자 수정 내용이 손실됨"
          exit 1
        fi

        # 2. 새 버전 파일이 생성되었는지 확인
        if [[ -f "$CLAUDE_DIR/settings.json.new" ]]; then
          echo "✓ settings.json.new 파일 생성됨 (새 버전)"

          # 새 버전이 원본 dotfiles 내용인지 확인
          if grep -q "sonnet" "$CLAUDE_DIR/settings.json.new"; then
            echo "✓ settings.json.new가 원본 dotfiles 내용임"
          else
            echo "✗ settings.json.new가 올바른 내용이 아님"
            exit 1
          fi
        else
          echo "✗ settings.json.new 파일이 생성되지 않음"
          exit 1
        fi

        if [[ -f "$CLAUDE_DIR/CLAUDE.md.new" ]]; then
          echo "✓ CLAUDE.md.new 파일 생성됨 (새 버전)"

          # 새 버전이 원본 dotfiles 내용인지 확인
          if grep -q "jito" "$CLAUDE_DIR/CLAUDE.md.new"; then
            echo "✓ CLAUDE.md.new가 원본 dotfiles 내용임"
          else
            echo "✗ CLAUDE.md.new가 올바른 내용이 아님"
            exit 1
          fi
        else
          echo "✗ CLAUDE.md.new 파일이 생성되지 않음"
          exit 1
        fi

        # 3. 업데이트 알림 파일이 생성되었는지 확인
        if [[ -f "$CLAUDE_DIR/settings.json.update-notice" ]]; then
          echo "✓ settings.json 업데이트 알림 파일 생성됨"

          # 알림 내용 확인
          if grep -q "사용자가 수정한 내용이 감지되어" "$CLAUDE_DIR/settings.json.update-notice"; then
            echo "✓ 알림 파일에 적절한 메시지 포함됨"
          else
            echo "✗ 알림 파일 내용이 부적절함"
            exit 1
          fi
        else
          echo "✗ settings.json 업데이트 알림 파일이 생성되지 않음"
          exit 1
        fi

        # 4. 사용자 커스텀 파일 보존 확인
        if [[ -f "$CLAUDE_DIR/commands/my-workflow.md" ]]; then
          echo "✓ 사용자 커스텀 명령어 파일 보존됨"

          # dotfiles에 없는 파일이므로 .new 파일은 생성되지 않아야 함
          if [[ ! -f "$CLAUDE_DIR/commands/my-workflow.md.new" ]]; then
            echo "✓ 커스텀 파일에 대한 불필요한 .new 파일 생성되지 않음"
          else
            echo "✗ 커스텀 파일에 대해 불필요한 .new 파일이 생성됨"
            exit 1
          fi
        else
          echo "✗ 사용자 커스텀 명령어 파일이 삭제됨"
          exit 1
        fi

        ${testHelpers.testSubsection "수동 병합 시나리오 테스트"}

        # 사용자가 수동으로 변경 사항을 확인하고 병합하는 시나리오
        echo "=== 수동 병합 테스트 ==="

        # diff 명령어로 차이점 확인 (실제 출력은 무시)
        if diff "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/settings.json.new" >/dev/null 2>&1; then
          echo "✗ 파일들이 동일함 (차이가 있어야 함)"
          exit 1
        else
          echo "✓ 현재 버전과 새 버전 간 차이점 존재 확인됨"
        fi

        # 사용자가 선택적으로 병합한다고 가정
        # (실제로는 대화형 도구나 수동 편집을 통해 수행)

        # 예시: 사용자가 일부 설정만 업데이트하기로 결정
        cat > "$CLAUDE_DIR/settings.json.merged" << 'EOF'
    {
      "model": "user-preferred-model",
      "temperature": 0.8,
      "max_tokens": 4000,
      "custom_prompts": {
        "korean": "한국어로 대답해주세요",
        "debug": "디버깅 모드로 실행해주세요"
      },
      "user_preferences": {
        "theme": "dark",
        "auto_save": true
      }
    }
    EOF

        # 병합된 파일로 교체
        mv "$CLAUDE_DIR/settings.json.merged" "$CLAUDE_DIR/settings.json"

        # 병합 후 정리
        rm -f "$CLAUDE_DIR/settings.json.new"
        rm -f "$CLAUDE_DIR/settings.json.update-notice"

        echo "✓ 수동 병합 및 정리 완료"

        ${testHelpers.testSubsection "최종 상태 검증"}

        # 최종 상태 확인
        if grep -q "user-preferred-model" "$CLAUDE_DIR/settings.json"; then
          echo "✓ 최종 파일에 사용자 선호 설정 보존됨"
        else
          echo "✗ 최종 파일에서 사용자 설정 손실됨"
          exit 1
        fi

        # 임시 파일들이 정리되었는지 확인
        if [[ ! -f "$CLAUDE_DIR/settings.json.new" && ! -f "$CLAUDE_DIR/settings.json.update-notice" ]]; then
          echo "✓ 병합 후 임시 파일들 정리됨"
        else
          echo "✗ 병합 후 임시 파일들이 남아있음"
          exit 1
        fi

        ${testHelpers.cleanup}

        echo ""
        echo "=== 사용자 수정 내용 보존 테스트 완료 ==="
        echo "이상적인 동작 요약:"
        echo "  ✓ 사용자 수정 파일 감지 및 보존"
        echo "  ✓ 새 버전을 .new 파일로 저장"
        echo "  ✓ 업데이트 알림 메시지 생성"
        echo "  ✓ 사용자 커스텀 파일 보존"
        echo "  ✓ 수동 병합 지원"
        echo "  ✓ 병합 후 임시 파일 정리"
        echo ""
        echo "이 테스트는 아직 구현되지 않은 이상적인 동작을 정의합니다."
        echo "다음 단계에서 이 동작을 실제로 구현할 예정입니다."
  '';

in
pkgs.runCommand "claude-config-preserve-user-changes-test" { } ''
  echo "=== Claude 설정 사용자 수정 내용 보존 테스트 (이상적인 동작) ==="

  # 사용자 수정 내용을 보존하는 이상적인 동작을 정의하는 테스트 실행
  ${testPreserveUserChanges}

  echo "이상적인 동작 정의 테스트 완료!"
  touch $out
''
