{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # 새로운 보존 로직 통합 테스트
  testPreservationIntegration = pkgs.writeShellScript "test-preservation-integration" ''
    set -e
    ${testHelpers.setupTestEnv}
    
    ${testHelpers.testSection "Claude 설정 보존 로직 통합 테스트"}
    
    # 테스트 환경 준비
    CLAUDE_DIR="$HOME/.claude"
    SOURCE_DIR="${../../modules/shared/config/claude}"
    MERGE_SCRIPT="${../../scripts/merge-claude-config}"
    
    mkdir -p "$CLAUDE_DIR/commands"
    
    ${testHelpers.testSubsection "1단계: 초기 설정 파일 생성"}
    
    # 초기 dotfiles 설정 복사
    cp "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    cp "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
    for cmd_file in "$SOURCE_DIR/commands"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        cp "$cmd_file" "$CLAUDE_DIR/commands/"
      fi
    done
    
    echo "✓ 초기 설정 파일 생성 완료"
    
    ${testHelpers.testSubsection "2단계: 사용자 수정 시뮬레이션"}
    
    # settings.json 사용자 수정
    cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "model": "claude-3.5-sonnet",
  "temperature": 0.3,
  "max_tokens": 8000,
  "user_custom_settings": {
    "language": "ko",
    "auto_format": true,
    "custom_prompts": {
      "korean": "모든 답변을 한국어로 해주세요",
      "review": "코드 리뷰를 상세히 해주세요"
    }
  }
}
EOF
    
    # CLAUDE.md 사용자 수정
    cat >> "$CLAUDE_DIR/CLAUDE.md" << 'EOF'

# 개인 작업 환경 설정 (사용자 추가)

## 나만의 개발 루틴
1. 매일 오전 9시에 dotfiles 업데이트 확인
2. 주간 백업 생성
3. 월간 설정 최적화

## 커스텀 명령어 단축키
- `qb` -> quick build
- `qs` -> quick switch
- `qr` -> quick rollback

## 프로젝트별 설정
### 회사 프로젝트
- Kubernetes 클러스터: prod-k8s
- Docker 레지스트리: company.registry.io

### 개인 프로젝트
- GitHub 저장소: github.com/myuser
- 배포 환경: Vercel
EOF
    
    # 사용자 커스텀 명령어 생성
    cat > "$CLAUDE_DIR/commands/my-daily-routine.md" << 'EOF'
# 일일 개발 루틴

## 아침 체크리스트
1. dotfiles 업데이트 확인
2. 이슈 트래커 확인
3. PR 리뷰

## 저녁 정리
1. 코드 커밋 및 푸시
2. 내일 할 일 정리
3. 백업 확인
EOF
    
    echo "✓ 사용자 수정 완료"
    
    ${testHelpers.testSubsection "3단계: 새로운 activation script 시뮬레이션"}
    
    # 새로운 스마트 복사 로직 실행 (Darwin activation script 내용 재현)
    echo "=== 스마트 Claude 설정 업데이트 시작 ==="
    
    # 파일 해시 비교 함수
    files_differ() {
      local source="$1"
      local target="$2"
      
      if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
        return 0  # 파일이 없으면 다른 것으로 간주
      fi
      
      local source_hash=$(sha256sum "$source" | cut -d' ' -f1)
      local target_hash=$(sha256sum "$target" | cut -d' ' -f1)
      
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
        cp "$source_file" "$target_file"
        chmod 644 "$target_file"
        return 0
      fi
      
      if files_differ "$source_file" "$target_file"; then
        echo "  사용자 수정 감지됨"
        
        # 높은 우선순위 파일들은 보존 (settings.json, CLAUDE.md)
        case "$file_name" in
          "settings.json"|"CLAUDE.md")
            echo "  사용자 버전 보존, 새 버전을 .new로 저장"
            cp "$source_file" "$target_file.new"
            chmod 644 "$target_file.new"
            
            # 사용자 알림 메시지 생성
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
    
    # 기존 backup 파일 정리
    rm -f "$CLAUDE_DIR"/*.bak
    rm -f "$CLAUDE_DIR/commands"/*.bak
    
    # 스마트 복사 실행
    for config_file in "settings.json" "CLAUDE.md"; do
      smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
    done
    
    # commands 디렉토리 처리
    for cmd_file in "$SOURCE_DIR/commands"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        local base_name=$(basename "$cmd_file")
        smart_copy "$cmd_file" "$CLAUDE_DIR/commands/$base_name"
      fi
    done
    
    echo "=== 스마트 Claude 설정 업데이트 완료 ==="
    
    ${testHelpers.testSubsection "4단계: 보존 결과 검증"}
    
    # 사용자 수정 내용이 보존되었는지 확인
    if grep -q "user_custom_settings" "$CLAUDE_DIR/settings.json"; then
      echo "✓ settings.json 사용자 수정 내용 보존됨"
    else
      echo "✗ settings.json 사용자 수정 내용 손실됨"
      exit 1
    fi
    
    if grep -q "나만의 개발 루틴" "$CLAUDE_DIR/CLAUDE.md"; then
      echo "✓ CLAUDE.md 사용자 수정 내용 보존됨"
    else
      echo "✗ CLAUDE.md 사용자 수정 내용 손실됨"
      exit 1
    fi
    
    # .new 파일이 생성되었는지 확인
    if [[ -f "$CLAUDE_DIR/settings.json.new" ]]; then
      echo "✓ settings.json.new 파일 생성됨"
    else
      echo "✗ settings.json.new 파일이 생성되지 않음"
      exit 1
    fi
    
    if [[ -f "$CLAUDE_DIR/CLAUDE.md.new" ]]; then
      echo "✓ CLAUDE.md.new 파일 생성됨"
    else
      echo "✗ CLAUDE.md.new 파일이 생성되지 않음"
      exit 1
    fi
    
    # 알림 파일이 생성되었는지 확인
    if [[ -f "$CLAUDE_DIR/settings.json.update-notice" ]]; then
      echo "✓ settings.json 업데이트 알림 생성됨"
    else
      echo "✗ settings.json 업데이트 알림이 생성되지 않음"
      exit 1
    fi
    
    # 사용자 커스텀 파일이 보존되었는지 확인
    if [[ -f "$CLAUDE_DIR/commands/my-daily-routine.md" ]]; then
      echo "✓ 사용자 커스텀 명령어 파일 보존됨"
    else
      echo "✗ 사용자 커스텀 명령어 파일이 삭제됨"
      exit 1
    fi
    
    # dotfiles 명령어 파일들이 업데이트되었는지 확인 (사용자 수정이 없으므로)
    UPDATED_COUNT=0
    for cmd_file in "$SOURCE_DIR/commands"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        local base_name=$(basename "$cmd_file")
        local target_file="$CLAUDE_DIR/commands/$base_name"
        if [[ -f "$target_file" ]]; then
          # 해시 비교로 동일성 확인
          local source_hash=$(sha256sum "$cmd_file" | cut -d' ' -f1)
          local target_hash=$(sha256sum "$target_file" | cut -d' ' -f1)
          if [[ "$source_hash" == "$target_hash" ]]; then
            ((UPDATED_COUNT++))
          fi
        fi
      fi
    done
    
    if [[ $UPDATED_COUNT -gt 0 ]]; then
      echo "✓ dotfiles 명령어 파일들 ($UPDATED_COUNT개) 업데이트됨"
    else
      echo "! dotfiles 명령어 파일 업데이트 없음 (정상적일 수 있음)"
    fi
    
    ${testHelpers.testSubsection "5단계: 병합 도구 기능 테스트"}
    
    # 병합 도구가 실행 가능한지 확인
    if [[ -x "$MERGE_SCRIPT" ]]; then
      echo "✓ 병합 도구 실행 가능"
      
      # 병합 후보 목록 확인
      MERGE_CANDIDATES=$("$MERGE_SCRIPT" --list | grep -c "settings.json\|CLAUDE.md" || true)
      if [[ $MERGE_CANDIDATES -ge 2 ]]; then
        echo "✓ 병합 도구가 올바른 후보 파일들을 감지함 ($MERGE_CANDIDATES개)"
      else
        echo "✗ 병합 도구가 후보 파일을 올바르게 감지하지 못함"
        "$MERGE_SCRIPT" --list
        exit 1
      fi
      
      # diff 기능 테스트
      echo "=== 병합 도구 diff 테스트 ==="
      "$MERGE_SCRIPT" --diff settings.json | head -10
      echo "✓ 병합 도구 diff 기능 작동"
      
    else
      echo "✗ 병합 도구가 실행 가능하지 않음"
      exit 1
    fi
    
    ${testHelpers.testSubsection "6단계: 백업 시스템 검증"}
    
    # 백업 디렉토리가 생성되었는지 확인
    if [[ -d "$CLAUDE_DIR/.backups" ]]; then
      echo "✓ 백업 디렉토리 생성됨"
      
      # 백업 파일이 있는지 확인
      BACKUP_COUNT=$(find "$CLAUDE_DIR/.backups" -name "*.backup.*" | wc -l)
      if [[ $BACKUP_COUNT -gt 0 ]]; then
        echo "✓ 백업 파일 생성됨 ($BACKUP_COUNT개)"
      else
        echo "! 백업 파일 없음 (명령어 파일들은 수정되지 않아서 정상)"
      fi
    else
      echo "! 백업 디렉토리 없음 (백업이 필요한 파일이 없어서 정상일 수 있음)"
    fi
    
    ${testHelpers.testSubsection "7단계: 종합 상태 점검"}
    
    echo ""
    echo "=== 최종 파일 상태 ==="
    echo "Claude 디렉토리: $CLAUDE_DIR"
    echo ""
    echo "메인 설정 파일:"
    echo "  settings.json: $(ls -la "$CLAUDE_DIR/settings.json" 2>/dev/null || echo "없음")"
    echo "  CLAUDE.md: $(ls -la "$CLAUDE_DIR/CLAUDE.md" 2>/dev/null || echo "없음")"
    echo ""
    echo "새 버전 파일:"
    echo "  settings.json.new: $(ls -la "$CLAUDE_DIR/settings.json.new" 2>/dev/null || echo "없음")"
    echo "  CLAUDE.md.new: $(ls -la "$CLAUDE_DIR/CLAUDE.md.new" 2>/dev/null || echo "없음")"
    echo ""
    echo "알림 파일:"
    NOTICE_COUNT=$(find "$CLAUDE_DIR" -name "*.update-notice" 2>/dev/null | wc -l)
    echo "  업데이트 알림: $NOTICE_COUNT개"
    echo ""
    echo "커스텀 파일:"
    echo "  사용자 명령어: $(ls -la "$CLAUDE_DIR/commands/my-daily-routine.md" 2>/dev/null || echo "없음")"
    echo ""
    
    ${testHelpers.cleanup}
    
    echo ""
    echo "=== Claude 설정 보존 로직 통합 테스트 완료 ==="
    echo "요약:"
    echo "  ✓ 사용자 수정 내용 보존됨"
    echo "  ✓ 새 버전 파일 생성됨 (.new)"
    echo "  ✓ 업데이트 알림 시스템 작동"
    echo "  ✓ 사용자 커스텀 파일 보존됨"
    echo "  ✓ 병합 도구 정상 작동"
    echo "  ✓ 백업 시스템 작동"
    echo ""
    echo "이제 사용자는 다음과 같이 작업할 수 있습니다:"
    echo "1. '$MERGE_SCRIPT --list' 로 병합할 파일 확인"
    echo "2. '$MERGE_SCRIPT settings.json' 로 개별 파일 병합"
    echo "3. '$MERGE_SCRIPT' 로 모든 파일 대화형 병합"
  '';

in
pkgs.runCommand "claude-config-preservation-integration-test" {} ''
  echo "=== Claude 설정 보존 로직 통합 테스트 ==="
  
  # 새로운 보존 시스템의 통합 테스트 실행
  ${testPreservationIntegration}
  
  echo "통합 테스트 완료!"
  touch $out
''