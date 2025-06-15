{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # 현재 무조건 덮어쓰기 동작을 검증하는 테스트
  testCurrentOverwriteBehavior = pkgs.writeShellScript "test-current-overwrite-behavior" ''
        set -e
        ${testHelpers.setupTestEnv}

        ${testHelpers.testSection "현재 덮어쓰기 동작 검증 테스트"}

        # 테스트 환경 준비
        CLAUDE_DIR="$HOME/.claude"
        mkdir -p "$CLAUDE_DIR/commands"

        ${testHelpers.testSubsection "사용자 수정 파일 생성"}

        # 사용자가 수정한 설정 파일들 생성
        cat > "$CLAUDE_DIR/settings.json" << 'EOF'
    {
      "model": "user-modified-model",
      "temperature": 0.9,
      "custom_setting": "user_value"
    }
    EOF

        cat > "$CLAUDE_DIR/CLAUDE.md" << 'EOF'
    # 사용자 커스텀 CLAUDE.md

    ## 사용자 추가 섹션
    이것은 사용자가 추가한 커스텀 콘텐츠입니다.

    # 기존 설정
    - 사용자가 수정한 설정들
    EOF

        cat > "$CLAUDE_DIR/commands/custom-command.md" << 'EOF'
    # 사용자 커스텀 명령어

    사용자가 직접 작성한 명령어입니다.
    EOF

        echo "✓ 사용자 수정 파일들 생성 완료"

        ${testHelpers.testSubsection "수정 전 상태 확인"}

        # 사용자 수정 내용 존재 확인
        ${testHelpers.assertContains "$CLAUDE_DIR/settings.json" "user-modified-model" "사용자 수정 settings.json 내용 확인"}
        ${testHelpers.assertContains "$CLAUDE_DIR/CLAUDE.md" "사용자 추가 섹션" "사용자 수정 CLAUDE.md 내용 확인"}
        ${testHelpers.assertExists "$CLAUDE_DIR/commands/custom-command.md" "사용자 커스텀 명령어 파일 존재 확인"}

        ${testHelpers.testSubsection "Darwin activation script 시뮬레이션"}

        # 현재 Darwin home-manager.nix의 copy_if_symlink 함수를 재현
        copy_if_symlink() {
          local file="$1"
          if [[ -L "$file" ]]; then
            # 심볼릭 링크인 경우
            local target=$(readlink "$file")
            if [[ -n "$target" && -f "$target" ]]; then
              rm "$file"
              cp "$target" "$file"
              chmod 644 "$file"
              echo "Copied $file from symlink"
            fi
          elif [[ -f "$file" ]]; then
            # 기존 파일이 있는 경우 - 무조건 덮어쓰기 (현재 동작)
            local source_file="''${file##*/}"
            local nix_store_file=""

            # 실제 dotfiles의 원본 파일 경로 설정
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

            if [[ -n "$nix_store_file" && -f "$nix_store_file" ]]; then
              cp "$nix_store_file" "$file"
              chmod 644 "$file"
              echo "Overwritten existing $file with latest version"
            fi
          fi
        }

        # 백업 파일 제거 (현재 동작)
        rm -f "$CLAUDE_DIR"/*.bak
        rm -f "$CLAUDE_DIR/commands"/*.bak

        # 무조건 덮어쓰기 실행
        copy_if_symlink "$CLAUDE_DIR/settings.json"
        copy_if_symlink "$CLAUDE_DIR/CLAUDE.md"

        for file in "$CLAUDE_DIR/commands"/*.md; do
          [[ -e "$file" ]] && copy_if_symlink "$file"
        done

        ${testHelpers.testSubsection "덮어쓰기 후 상태 검증"}

        # 현재 동작: 사용자 수정 내용이 사라져야 함
        if ! grep -q "user-modified-model" "$CLAUDE_DIR/settings.json" 2>/dev/null; then
          echo "✓ settings.json 사용자 수정 내용이 덮어쓰기로 제거됨 (현재 예상 동작)"
        else
          echo "✗ settings.json 사용자 수정 내용이 남아있음 (현재 동작과 다름)"
          exit 1
        fi

        if ! grep -q "사용자 추가 섹션" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
          echo "✓ CLAUDE.md 사용자 수정 내용이 덮어쓰기로 제거됨 (현재 예상 동작)"
        else
          echo "✗ CLAUDE.md 사용자 수정 내용이 남아있음 (현재 동작과 다름)"
          exit 1
        fi

        # 원본 dotfiles 내용으로 복원되었는지 확인
        if grep -q "sonnet" "$CLAUDE_DIR/settings.json" 2>/dev/null; then
          echo "✓ settings.json이 원본 dotfiles 내용으로 복원됨"
        else
          echo "✗ settings.json이 원본 dotfiles 내용으로 복원되지 않음"
          echo "현재 내용:"
          cat "$CLAUDE_DIR/settings.json"
          exit 1
        fi

        if grep -q "jito" "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null; then
          echo "✓ CLAUDE.md가 원본 dotfiles 내용으로 복원됨"
        else
          echo "✗ CLAUDE.md가 원본 dotfiles 내용으로 복원되지 않음"
          echo "현재 내용 (처음 10줄):"
          head -10 "$CLAUDE_DIR/CLAUDE.md"
          exit 1
        fi

        # 사용자 커스텀 명령어 파일은 보존되어야 함 (dotfiles에 없는 파일)
        if [[ -f "$CLAUDE_DIR/commands/custom-command.md" ]]; then
          echo "✓ 사용자 커스텀 명령어 파일 보존됨 (dotfiles에 없는 파일은 유지)"
        else
          echo "✗ 사용자 커스텀 명령어 파일이 삭제됨"
          exit 1
        fi

        ${testHelpers.testSubsection "파일 권한 확인"}

        # 파일 권한 644 확인
        for file in "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md"; do
          if [[ "$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file")" == "644" ]]; then
            echo "✓ $file 권한이 644로 올바르게 설정됨"
          else
            echo "✗ $file 권한이 올바르지 않음"
            exit 1
          fi
        done

        ${testHelpers.testSubsection "백업 파일 확인"}

        # 백업 파일이 제거되었는지 확인
        if [[ -z "$(find "$CLAUDE_DIR" -name "*.bak" 2>/dev/null)" ]]; then
          echo "✓ 백업 파일이 모두 제거됨 (현재 동작)"
        else
          echo "✗ 백업 파일이 남아있음"
          find "$CLAUDE_DIR" -name "*.bak"
          exit 1
        fi

        ${testHelpers.cleanup}

        echo ""
        echo "=== 현재 덮어쓰기 동작 검증 완료 ==="
        echo "요약:"
        echo "  ✓ 사용자 수정 내용이 무조건 덮어쓰기됨"
        echo "  ✓ 원본 dotfiles 내용으로 복원됨"
        echo "  ✓ dotfiles에 없는 파일은 보존됨"
        echo "  ✓ 백업 파일은 즉시 제거됨"
        echo "  ✓ 파일 권한이 올바르게 설정됨"
        echo ""
        echo "이 테스트는 현재의 '문제가 되는' 동작을 검증합니다."
        echo "다음 단계에서는 사용자 수정 내용을 보존하는 새로운 동작을 정의하고 구현할 예정입니다."
  '';

in
pkgs.runCommand "claude-config-overwrite-prevention-test" { } ''
  echo "=== Claude 설정 덮어쓰기 방지 테스트 (현재 동작 검증) ==="

  # 현재의 덮어쓰기 동작을 검증하는 테스트 실행
  ${testCurrentOverwriteBehavior}

  echo "현재 동작 검증 테스트 완료!"
  touch $out
''
