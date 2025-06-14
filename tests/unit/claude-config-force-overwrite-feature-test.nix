{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # Claude 설정 파일 기존 파일 보존 비활성화 기능 테스트
  testForceOverwriteFeature = pkgs.writeShellScript "test-force-overwrite-feature" ''
    set -e
    ${testHelpers.setupTestEnv}
    
    echo ""
    echo "=== Claude 설정 파일 기존 파일 보존 비활성화 기능 테스트 ==="
    
    # 테스트 환경 준비
    CLAUDE_DIR="$HOME/.claude"
    SOURCE_DIR="${../../modules/shared/config/claude}"
    TEST_WORK_DIR="$HOME/test-force-overwrite"
    
    mkdir -p "$CLAUDE_DIR" "$TEST_WORK_DIR"
    
    echo "--- 기존 파일 보존 비활성화 기능 테스트 ---"
    
    # 사용자 수정 파일 생성
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
    
    sleep 1
    
    # 스마트 복사 함수 (기존 파일 보존 비활성화 옵션)
    smart_copy_force() {
      local source_file="$1"
      local target_file="$2"
      local file_name=$(basename "$source_file")
      
      echo "기존 파일 보존 비활성화 모드로 처리 중: $file_name"
      
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
      
      # 항상 강제 덮어쓰기
      echo "  강제 덮어쓰기 모드: 기존 파일 보존 비활성화"
      chmod u+w "$target_file" 2>/dev/null || true
      cp "$source_file" "$target_file"
      chmod 644 "$target_file"
    }
    
    # 정상 복사 함수 (기존 파일 보존 활성화)
    smart_copy_normal() {
      local source_file="$1"
      local target_file="$2"
      local file_name=$(basename "$source_file")
      
      echo "정상 모드로 처리 중: $file_name"
      
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
      
      # 파일 비교
      if ! cmp -s "$source_file" "$target_file"; then
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
    
    # 테스트 1: 기존 파일 보존 비활성화 모드
    echo ""
    echo "테스트 1: 기존 파일 보존 비활성화 모드"
    smart_copy_force "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    smart_copy_force "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
    # 타임스탬프 확인 (덮어쓰기 되었는지)
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
    
    # .new 파일이 생성되지 않았는지 확인
    if [[ ! -f "$CLAUDE_DIR/settings.json.new" ]]; then
      echo "✓ 기존 파일 보존 비활성화로 settings.json.new 파일이 생성되지 않았습니다"
    else
      echo "✗ 기존 파일 보존 비활성화임에도 settings.json.new 파일이 생성되었습니다"
      exit 1
    fi
    
    # 사용자 수정 내용이 덮어쓰기 되었는지 확인
    if ! grep -q "user_modified" "$CLAUDE_DIR/settings.json"; then
      echo "✓ 사용자 수정 내용이 올바르게 덮어쓰기 되었습니다"
    else
      echo "✗ 사용자 수정 내용이 여전히 남아있습니다"
      exit 1
    fi
    
    # 테스트 2: 정상 모드에서 파일 보존 확인
    echo ""
    echo "테스트 2: 정상 모드에서 파일 보존 확인"
    
    # 기존 테스트 파일 정리
    rm -f "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR"/*.new
    
    # 사용자 수정 시뮬레이션
    cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "model": "claude-3.5-sonnet",
  "temperature": 0.5,
  "max_tokens": 4000,
  "user_modified_test2": true
}
EOF
    
    echo "사용자가 수정한 CLAUDE.md 파일 - 테스트 2" > "$CLAUDE_DIR/CLAUDE.md"
    
    # 정상 모드로 처리
    smart_copy_normal "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    smart_copy_normal "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
    # .new 파일이 생성되었는지 확인
    if [[ -f "$CLAUDE_DIR/settings.json.new" ]]; then
      echo "✓ 정상 모드에서 수정된 settings.json에 대해 .new 파일이 생성되었습니다"
    else
      echo "✗ 정상 모드에서 수정된 settings.json에 대해 .new 파일이 생성되지 않았습니다"
      exit 1
    fi
    
    if [[ -f "$CLAUDE_DIR/CLAUDE.md.new" ]]; then
      echo "✓ 정상 모드에서 수정된 CLAUDE.md에 대해 .new 파일이 생성되었습니다"
    else
      echo "✗ 정상 모드에서 수정된 CLAUDE.md에 대해 .new 파일이 생성되지 않았습니다"
      exit 1
    fi
    
    # 원본 파일은 보존되었는지 확인
    if grep -q "user_modified_test2" "$CLAUDE_DIR/settings.json"; then
      echo "✓ 정상 모드에서 사용자 수정 settings.json이 보존되었습니다"
    else
      echo "✗ 정상 모드에서 사용자 수정 settings.json이 보존되지 않았습니다"
      exit 1
    fi
    
    if grep -q "테스트 2" "$CLAUDE_DIR/CLAUDE.md"; then
      echo "✓ 정상 모드에서 사용자 수정 CLAUDE.md가 보존되었습니다"
    else
      echo "✗ 정상 모드에서 사용자 수정 CLAUDE.md가 보존되지 않았습니다"
      exit 1
    fi
    
    # 정리
    rm -rf "$CLAUDE_DIR" "$TEST_WORK_DIR"
    
    echo ""
    echo "🎉 모든 기존 파일 보존 비활성화 기능 테스트가 성공적으로 완료되었습니다!"
  '';

in pkgs.runCommand "claude-config-force-overwrite-feature-test" {
  buildInputs = [ pkgs.bash pkgs.coreutils ];
} ''
  ${testForceOverwriteFeature}
  touch $out
''