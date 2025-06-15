{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Claude 설정 파일 강제 덮어쓰기 기능 단위 테스트
  testForceOverwrite = pkgs.writeShellScript "test-claude-config-force-overwrite" ''
        set -e
        ${testHelpers.setupTestEnv}

        echo ""
        echo "=== Claude 설정 파일 기존 파일 보존 비활성화 단위 테스트 ==="

        # 테스트 환경 준비
        CLAUDE_DIR="$HOME/.claude"
        SOURCE_DIR="${../../modules/shared/config/claude}"
        TEST_WORK_DIR="$HOME/test-force-overwrite"

        mkdir -p "$CLAUDE_DIR" "$TEST_WORK_DIR"

        echo "--- 시나리오 1: 기존 파일 보존 비활성화 테스트 ---"

        # 사용자 수정 파일 생성 (보존되어야 할 파일)
        cat > "$CLAUDE_DIR/settings.json" << 'EOF'
    {
      "model": "claude-3.5-sonnet",
      "temperature": 0.7,
      "user_modified": true
    }
    EOF

        echo "사용자가 수정한 CLAUDE.md 파일" > "$CLAUDE_DIR/CLAUDE.md"

        # 파일 타임스탬프 기록
        SETTINGS_BEFORE=$(stat -c %Y "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -f %m "$CLAUDE_DIR/settings.json")
        CLAUDE_MD_BEFORE=$(stat -c %Y "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || stat -f %m "$CLAUDE_DIR/CLAUDE.md")

        # 1초 대기 (타임스탬프 차이를 위해)
        sleep 1

        # 파일 해시 비교 함수
        files_differ() {
          local source="$1"
          local target="$2"

          if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
            return 0  # 파일이 없으면 다른 것으로 간주
          fi

          local source_hash=$(sha256sum "$source" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$source" | cut -d' ' -f1)
          local target_hash=$(sha256sum "$target" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$target" | cut -d' ' -f1)

          [[ "$source_hash" != "$target_hash" ]]
        }

        # 스마트 복사 함수 (기존 파일 보존 비활성화 옵션 추가)
        smart_copy() {
          local source_file="$1"
          local target_file="$2"
          local force_overwrite="$3"  # 새 매개변수: 기존 파일 보존 비활성화
          local file_name=$(basename "$source_file")

          echo "처리 중: $file_name (force_overwrite: ''${force_overwrite:-false})"

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

          # force_overwrite가 true이면 항상 덮어쓰기
          if [[ "$force_overwrite" == "true" ]]; then
            echo "  강제 덮어쓰기 모드: 기존 파일 보존 비활성화"
            chmod u+w "$target_file" 2>/dev/null || true
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
                ;;
              *)
                echo "  백업 후 덮어쓰기"
                chmod u+w "$target_file" 2>/dev/null || true
                cp "$source_file" "$target_file"
                chmod 644 "$target_file"
                ;;
            esac
          else
            echo "  파일 동일함, 변경 없음"
          fi
        }

        # 기존 파일 보존 비활성화 옵션으로 강제 덮어쓰기 실행
        smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json" "true"
        smart_copy "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "true"

        # 파일 타임스탬프 확인 (덮어쓰기 되었는지)
        SETTINGS_AFTER=$(stat -c %Y "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -f %m "$CLAUDE_DIR/settings.json")
        CLAUDE_MD_AFTER=$(stat -c %Y "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || stat -f %m "$CLAUDE_DIR/CLAUDE.md")

        if [[ "$SETTINGS_AFTER" -gt "$SETTINGS_BEFORE" ]]; then
          echo "✓ settings.json이 기존 파일 보존 비활성화로 덮어쓰기 되었습니다"
        else
          echo "✗ settings.json이 덮어쓰기 되지 않았습니다"
          exit 1
        fi

        if [[ "$CLAUDE_MD_AFTER" -gt "$CLAUDE_MD_BEFORE" ]]; then
          echo "✓ CLAUDE.md가 기존 파일 보존 비활성화로 덮어쓰기 되었습니다"
        else
          echo "✗ CLAUDE.md가 덮어쓰기 되지 않았습니다"
          exit 1
        fi

        # .new 파일이 생성되지 않았는지 확인 (기존 파일 보존 비활성화)
        if [[ ! -f "$CLAUDE_DIR/settings.json.new" ]]; then
          echo "✓ 기존 파일 보존 비활성화로 settings.json.new 파일이 생성되지 않았습니다"
        else
          echo "✗ 기존 파일 보존 비활성화임에도 settings.json.new 파일이 생성되었습니다"
          exit 1
        fi

        if [[ ! -f "$CLAUDE_DIR/CLAUDE.md.new" ]]; then
          echo "✓ 기존 파일 보존 비활성화로 CLAUDE.md.new 파일이 생성되지 않았습니다"
        else
          echo "✗ 기존 파일 보존 비활성화임에도 CLAUDE.md.new 파일이 생성되었습니다"
          exit 1
        fi

        # 사용자 수정 내용이 덮어쓰기 되었는지 확인
        if ! grep -q "user_modified" "$CLAUDE_DIR/settings.json"; then
          echo "✓ 사용자 수정 내용이 올바르게 덮어쓰기 되었습니다"
        else
          echo "✗ 사용자 수정 내용이 여전히 남아있습니다"
          exit 1
        fi

        echo "--- 시나리오 2: 정상 모드에서는 수정된 파일이 보존되는지 확인 ---"

        # 기존 테스트 파일 정리
        rm -f "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"

        # 사용자 수정 시뮬레이션
        cat > "$CLAUDE_DIR/settings.json" << 'EOF'
    {
      "model": "claude-3.5-sonnet",
      "temperature": 0.5,
      "max_tokens": 4000,
      "user_modified_scenario_2": true
    }
    EOF

        echo "사용자가 수정한 CLAUDE.md 파일 - 시나리오 2" > "$CLAUDE_DIR/CLAUDE.md"

        # 정상 모드(force_overwrite=false)로 수정된 파일 처리 확인
        smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json" "false"
        smart_copy "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md" "false"

        # .new 파일이 생성되었는지 확인
        if [[ -f "$CLAUDE_DIR/settings.json.new" ]]; then
          echo "✓ 수정된 settings.json에 대해 .new 파일이 생성되었습니다"
        else
          echo "✗ 수정된 settings.json에 대해 .new 파일이 생성되지 않았습니다"
          exit 1
        fi

        if [[ -f "$CLAUDE_DIR/CLAUDE.md.new" ]]; then
          echo "✓ 수정된 CLAUDE.md에 대해 .new 파일이 생성되었습니다"
        else
          echo "✗ 수정된 CLAUDE.md에 대해 .new 파일이 생성되지 않았습니다"
          exit 1
        fi

        # 원본 파일은 보존되었는지 확인
        if grep -q "user_modified_scenario_2" "$CLAUDE_DIR/settings.json"; then
          echo "✓ 사용자 수정 settings.json이 보존되었습니다"
        else
          echo "✗ 사용자 수정 settings.json이 보존되지 않았습니다"
          exit 1
        fi

        if grep -q "시나리오 2" "$CLAUDE_DIR/CLAUDE.md"; then
          echo "✓ 사용자 수정 CLAUDE.md가 보존되었습니다"
        else
          echo "✗ 사용자 수정 CLAUDE.md가 보존되지 않았습니다"
          exit 1
        fi

        echo "--- 시나리오 3: 명령어 파일 덮어쓰기 테스트 ---"

        # commands 디렉토리 테스트
        mkdir -p "$CLAUDE_DIR/commands"

        # 기존 명령어 파일과 동일한 파일 생성
        cp "$SOURCE_DIR/commands/build.md" "$CLAUDE_DIR/commands/build.md"

        BUILD_MD_BEFORE=$(stat -c %Y "$CLAUDE_DIR/commands/build.md" 2>/dev/null || stat -f %m "$CLAUDE_DIR/commands/build.md")
        sleep 1

        # 명령어 파일은 우선순위가 낮아서 무조건 덮어쓰기, force_overwrite=true로 테스트
        smart_copy "$SOURCE_DIR/commands/build.md" "$CLAUDE_DIR/commands/build.md" "true"

        BUILD_MD_AFTER=$(stat -c %Y "$CLAUDE_DIR/commands/build.md" 2>/dev/null || stat -f %m "$CLAUDE_DIR/commands/build.md")

        if [[ "$BUILD_MD_AFTER" -gt "$BUILD_MD_BEFORE" ]]; then
          echo "✓ 명령어 파일이 강제 덮어쓰기 되었습니다"
        else
          echo "✗ 명령어 파일이 덮어쓰기 되지 않았습니다"
          exit 1
        fi

        echo "--- 시나리오 4: 로그 메시지 확인 ---"

        # 기존 파일 보존 비활성화 모드 로그 메시지 확인
        cp "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
        OUTPUT=$(smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json" "true" 2>&1)

        if echo "$OUTPUT" | grep -q "강제 덮어쓰기 모드: 기존 파일 보존 비활성화"; then
          echo "✓ 기존 파일 보존 비활성화 모드의 로그 메시지가 출력되었습니다"
        else
          echo "✗ 예상한 로그 메시지가 출력되지 않았습니다"
          echo "실제 출력: $OUTPUT"
          exit 1
        fi

        # 정상 모드 로그 메시지 확인
        OUTPUT_NORMAL=$(smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json" "false" 2>&1)

        if echo "$OUTPUT_NORMAL" | grep -q "파일 동일함, 변경 없음"; then
          echo "✓ 정상 모드의 로그 메시지가 출력되었습니다"
        else
          echo "✗ 정상 모드의 예상한 로그 메시지가 출력되지 않았습니다"
          echo "실제 출력: $OUTPUT_NORMAL"
          exit 1
        fi

        # 정리
        rm -rf "$CLAUDE_DIR" "$TEST_WORK_DIR"

        echo ""
        echo "🎉 모든 기존 파일 보존 비활성화 테스트가 성공적으로 완료되었습니다!"
  '';

in
pkgs.runCommand "claude-config-force-overwrite-unit-test"
{
  buildInputs = [ pkgs.bash pkgs.coreutils ];
} ''
  ${testForceOverwrite}
  touch $out
''
