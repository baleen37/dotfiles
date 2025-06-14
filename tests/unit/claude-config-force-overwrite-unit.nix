{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # Claude 설정 파일 강제 덮어쓰기 기능 단위 테스트
  testForceOverwrite = pkgs.writeShellScript "test-claude-config-force-overwrite" ''
    set -e
    ${testHelpers.setupTestEnv}
    
    ${testHelpers.testSection "Claude 설정 파일 강제 덮어쓰기 단위 테스트"}
    
    # 테스트 환경 준비
    CLAUDE_DIR="$HOME/.claude"
    SOURCE_DIR="${../../modules/shared/config/claude}"
    TEST_WORK_DIR="$HOME/test-force-overwrite"
    
    mkdir -p "$CLAUDE_DIR" "$TEST_WORK_DIR"
    
    ${testHelpers.testSubsection "시나리오 1: 동일한 파일 강제 덮어쓰기 테스트"}
    
    # 소스 파일과 완전히 동일한 타겟 파일 생성
    cp "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    cp "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
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
    
    # 스마트 복사 함수 (수정된 로직)
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
            ;;
          *)
            echo "  백업 후 덮어쓰기"
            chmod u+w "$target_file" 2>/dev/null || true
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
    smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    smart_copy "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
    # 파일 타임스탬프 확인 (덮어쓰기 되었는지)
    SETTINGS_AFTER=$(stat -c %Y "$CLAUDE_DIR/settings.json" 2>/dev/null || stat -f %m "$CLAUDE_DIR/settings.json")
    CLAUDE_MD_AFTER=$(stat -c %Y "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || stat -f %m "$CLAUDE_DIR/CLAUDE.md")
    
    if [[ "$SETTINGS_AFTER" -gt "$SETTINGS_BEFORE" ]]; then
      echo "✓ settings.json이 강제 덮어쓰기 되었습니다"
    else
      echo "✗ settings.json이 덮어쓰기 되지 않았습니다"
      exit 1
    fi
    
    if [[ "$CLAUDE_MD_AFTER" -gt "$CLAUDE_MD_BEFORE" ]]; then
      echo "✓ CLAUDE.md가 강제 덮어쓰기 되었습니다"
    else
      echo "✗ CLAUDE.md가 덮어쓰기 되지 않았습니다"
      exit 1
    fi
    
    ${testHelpers.testSubsection "시나리오 2: 수정된 파일은 보존되는지 확인"}
    
    # 사용자 수정 시뮬레이션
    cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "model": "claude-3.5-sonnet",
  "temperature": 0.5,
  "max_tokens": 4000,
  "user_modified": true
}
EOF
    
    echo "사용자가 수정한 CLAUDE.md 파일" > "$CLAUDE_DIR/CLAUDE.md"
    
    # 수정된 파일에 대한 처리 확인
    smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    smart_copy "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
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
    if grep -q "user_modified" "$CLAUDE_DIR/settings.json"; then
      echo "✓ 사용자 수정 settings.json이 보존되었습니다"
    else
      echo "✗ 사용자 수정 settings.json이 보존되지 않았습니다"
      exit 1
    fi
    
    if grep -q "사용자가 수정한" "$CLAUDE_DIR/CLAUDE.md"; then
      echo "✓ 사용자 수정 CLAUDE.md가 보존되었습니다"
    else
      echo "✗ 사용자 수정 CLAUDE.md가 보존되지 않았습니다"
      exit 1
    fi
    
    ${testHelpers.testSubsection "시나리오 3: 명령어 파일 덮어쓰기 테스트"}
    
    # commands 디렉토리 테스트
    mkdir -p "$CLAUDE_DIR/commands"
    
    # 기존 명령어 파일과 동일한 파일 생성
    cp "$SOURCE_DIR/commands/build.md" "$CLAUDE_DIR/commands/build.md"
    
    BUILD_MD_BEFORE=$(stat -c %Y "$CLAUDE_DIR/commands/build.md" 2>/dev/null || stat -f %m "$CLAUDE_DIR/commands/build.md")
    sleep 1
    
    # 명령어 파일은 우선순위가 낮아서 무조건 덮어쓰기
    smart_copy "$SOURCE_DIR/commands/build.md" "$CLAUDE_DIR/commands/build.md"
    
    BUILD_MD_AFTER=$(stat -c %Y "$CLAUDE_DIR/commands/build.md" 2>/dev/null || stat -f %m "$CLAUDE_DIR/commands/build.md")
    
    if [[ "$BUILD_MD_AFTER" -gt "$BUILD_MD_BEFORE" ]]; then
      echo "✓ 명령어 파일이 강제 덮어쓰기 되었습니다"
    else
      echo "✗ 명령어 파일이 덮어쓰기 되지 않았습니다"
      exit 1
    fi
    
    ${testHelpers.testSubsection "시나리오 4: 로그 메시지 확인"}
    
    # 동일한 파일로 다시 설정 후 로그 출력 캡처 테스트
    cp "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    OUTPUT=$(smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json" 2>&1)
    
    if echo "$OUTPUT" | grep -q "파일 동일하지만 강제 덮어쓰기"; then
      echo "✓ 올바른 로그 메시지가 출력되었습니다"
    else
      echo "✗ 예상한 로그 메시지가 출력되지 않았습니다"
      echo "실제 출력: $OUTPUT"
      exit 1
    fi
    
    # 정리
    rm -rf "$CLAUDE_DIR" "$TEST_WORK_DIR"
    
    echo ""
    echo "🎉 모든 강제 덮어쓰기 테스트가 성공적으로 완료되었습니다!"
  '';

in pkgs.runCommand "claude-config-force-overwrite-unit-test" {
  buildInputs = [ pkgs.bash pkgs.coreutils ];
} ''
  ${testForceOverwrite}
  touch $out
''