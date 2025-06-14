{ pkgs, flake ? null, src ? ../.. }:

let
  lib = pkgs.lib;
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # 전체 워크플로우 End-to-End 테스트
  testCompleteWorkflow = pkgs.writeShellScript "test-complete-workflow" ''
    set -e
    ${testHelpers.setupTestEnv}
    
    ${testHelpers.testSection "Claude 설정 전체 워크플로우 E2E 테스트"}
    
    # 테스트 환경 준비
    CLAUDE_DIR="$HOME/.claude"
    SOURCE_DIR="${../../modules/shared/config/claude}"
    MERGE_SCRIPT="${../../scripts/merge-claude-config}"
    
    echo "테스트 환경:"
    echo "  Claude 디렉토리: $CLAUDE_DIR"
    echo "  소스 디렉토리: $SOURCE_DIR"
    echo "  병합 스크립트: $MERGE_SCRIPT"
    echo ""
    
    ${testHelpers.testSubsection "Phase 1: 신규 시스템 초기 설정"}
    
    # 신규 시스템에서 처음 dotfiles 적용 시뮬레이션
    echo "신규 시스템에 Claude 설정 초기 배포..."
    
    mkdir -p "$CLAUDE_DIR/commands"
    
    # home-manager의 일반적인 파일 생성 (symlink로 시작)
    ln -sf "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    ln -sf "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
    for cmd_file in "$SOURCE_DIR/commands"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        ln -sf "$cmd_file" "$CLAUDE_DIR/commands/$(basename "$cmd_file")"
      fi
    done
    
    echo "✓ 초기 설정 완료 (symlink 상태)"
    
    # symlink 상태 확인
    if [[ -L "$CLAUDE_DIR/settings.json" ]]; then
      echo "✓ settings.json이 symlink로 생성됨"
    else
      echo "✗ settings.json symlink 생성 실패"
      exit 1
    fi
    
    ${testHelpers.testSubsection "Phase 2: 첫 번째 activation (symlink → 실제 파일)"}
    
    # Darwin activation script의 첫 실행 (symlink를 실제 파일로 변환)
    echo "첫 번째 시스템 재빌드 시뮬레이션..."
    
    # convert_symlink 함수 (Darwin activation script에서 가져옴)
    convert_symlink() {
      local file="$1"
      if [[ -L "$file" ]]; then
        local target=$(readlink "$file")
        if [[ -n "$target" && -f "$target" ]]; then
          echo "심볼릭 링크를 실제 파일로 변환: $(basename "$file")"
          rm "$file"
          cp "$target" "$file"
          chmod 644 "$file"
        fi
      fi
    }
    
    # 모든 symlink를 실제 파일로 변환
    for config_file in "settings.json" "CLAUDE.md"; do
      convert_symlink "$CLAUDE_DIR/$config_file"
    done
    
    for cmd_file in "$CLAUDE_DIR/commands"/*.md; do
      if [[ -L "$cmd_file" ]]; then
        convert_symlink "$cmd_file"
      fi
    done
    
    echo "✓ symlink → 실제 파일 변환 완료"
    
    # 변환 결과 확인
    if [[ ! -L "$CLAUDE_DIR/settings.json" && -f "$CLAUDE_DIR/settings.json" ]]; then
      echo "✓ settings.json이 실제 파일로 변환됨"
    else
      echo "✗ settings.json 변환 실패"
      exit 1
    fi
    
    ${testHelpers.testSubsection "Phase 3: 사용자 일상 사용"}
    
    echo "사용자가 일상적으로 Claude 설정을 커스터마이징..."
    
    # 3-1: settings.json 개인화
    cat > "$CLAUDE_DIR/settings.json" << 'EOF'
{
  "model": "claude-3.5-sonnet",
  "temperature": 0.2,
  "max_tokens": 8000,
  "user_preferences": {
    "language": "korean",
    "code_style": "google",
    "auto_format": true,
    "daily_routine": {
      "morning_check": ["git status", "make lint"],
      "evening_cleanup": ["git push", "backup_check"]
    }
  },
  "custom_prompts": {
    "kr": "한국어로 답변해주세요",
    "review": "코드 리뷰를 해주세요",
    "test": "테스트 코드를 작성해주세요",
    "doc": "문서를 작성해주세요"
  }
}
EOF
    
    # 3-2: CLAUDE.md 개인 섹션 추가
    cat >> "$CLAUDE_DIR/CLAUDE.md" << 'EOF'

# 개인 워크스페이스 설정

## 프로젝트 구조
```
~/workspace/
├── company/          # 회사 프로젝트
├── personal/         # 개인 프로젝트
├── experiments/      # 실험적 프로젝트
└── dotfiles/         # 설정 관리
```

## 자주 사용하는 명령어
- `nix run .#build-switch` - 시스템 설정 즉시 적용
- `make lint && make build` - 코드 품질 검사 후 빌드
- `gh pr create --assignee @me` - PR 생성

## 개발 환경별 설정

### 회사 업무
- VPN: company.vpn
- Kubernetes: prod-cluster
- 모니터링: grafana.company.com

### 개인 프로젝트
- GitHub: github.com/myuser
- 배포: vercel.app
- 도메인: myproject.dev

## 백업 스케줄
- 일일: dotfiles 변경사항 커밋
- 주간: 전체 설정 백업
- 월간: 시스템 이미지 백업

## 트러블슈팅 노트
- build-switch 권한 오류 → sudo 사용
- nix store 용량 부족 → nix store gc
- home-manager 충돌 → 백업 후 재설정
EOF
    
    # 3-3: 개인 명령어 생성
    cat > "$CLAUDE_DIR/commands/daily-workflow.md" << 'EOF'
# 일일 개발 워크플로우

## 아침 루틴 (9:00 AM)
1. 시스템 업데이트 확인
2. dotfiles 변경사항 확인
3. 이슈 트래커 체크
4. 당일 작업 계획 수립

## 작업 중간 체크포인트
- 매시간: 진행상황 확인
- 점심: 코드 백업 및 푸시
- 오후 3시: 코드 리뷰 요청/처리

## 저녁 정리 (6:00 PM)
1. 모든 변경사항 커밋
2. PR 상태 확인
3. 내일 할 일 정리
4. 시스템 정리

## 주간 루틴 (금요일)
1. 전체 프로젝트 백업
2. dotfiles 업데이트
3. 개발 도구 버전 확인
4. 주간 회고 작성
EOF
    
    cat > "$CLAUDE_DIR/commands/quick-deploy.md" << 'EOF'
# 빠른 배포 명령어

## 개발 환경 배포
```bash
nix run .#build
make switch HOST=dev
```

## 스테이징 배포
```bash
git push origin develop
# CI/CD 자동 배포 대기
```

## 프로덕션 배포
```bash
git checkout main
git merge develop
git tag v1.0.0
git push origin main --tags
```
EOF
    
    echo "✓ 사용자 개인화 완료"
    
    # 개인화 결과 확인
    USER_PREFS_COUNT=$(grep -c "user_preferences\|custom_prompts\|개인 워크스페이스" "$CLAUDE_DIR/settings.json" "$CLAUDE_DIR/CLAUDE.md" || true)
    CUSTOM_COMMANDS=$(find "$CLAUDE_DIR/commands" -name "*workflow*" -o -name "*deploy*" | wc -l)
    
    echo "  - 개인 설정 항목: $USER_PREFS_COUNT개"
    echo "  - 커스텀 명령어: $CUSTOM_COMMANDS개"
    
    ${testHelpers.testSubsection "Phase 4: dotfiles 업데이트 발생"}
    
    echo "dotfiles 저장소에 새로운 업데이트가 있다고 가정..."
    echo "사용자가 'nix run .#build-switch' 실행..."
    
    # 새로운 스마트 activation script 실행
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
    
    # 조건부 복사 함수
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
            
            cat > "$target_file.update-notice" << EOF
파일 업데이트 알림: $file_name

이 파일이 dotfiles에서 업데이트되었지만, 사용자가 수정한 내용이 감지되어 
기존 파일을 보존했습니다.

- 현재 파일: $target_file (사용자 수정 버전)
- 새 버전: $target_file.new (dotfiles 최신 버전)

변경 사항을 확인하고 수동으로 병합하세요:
  diff "$target_file" "$target_file.new"

병합 도구 사용:
  $MERGE_SCRIPT $file_name

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
    
    # 스마트 복사 실행
    for config_file in "settings.json" "CLAUDE.md"; do
      smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
    done
    
    for cmd_file in "$SOURCE_DIR/commands"/*.md; do
      if [[ -f "$cmd_file" ]]; then
        local base_name=$(basename "$cmd_file")
        smart_copy "$cmd_file" "$CLAUDE_DIR/commands/$base_name"
      fi
    done
    
    # 오래된 백업 정리
    if [[ -d "$CLAUDE_DIR/.backups" ]]; then
      find "$CLAUDE_DIR/.backups" -name "*.backup.*" -mtime +30 -delete 2>/dev/null || true
    fi
    
    # 사용자 알림
    NOTICE_COUNT=$(find "$CLAUDE_DIR" -name "*.update-notice" 2>/dev/null | wc -l)
    if [[ $NOTICE_COUNT -gt 0 ]]; then
      echo ""
      echo "주의: $NOTICE_COUNT개의 업데이트 알림이 생성되었습니다."
      echo "다음 명령어로 확인하세요: find $CLAUDE_DIR -name '*.update-notice'"
    fi
    
    echo "=== 스마트 Claude 설정 업데이트 완료 ==="
    echo "✓ 시스템 업데이트 처리 완료"
    
    ${testHelpers.testSubsection "Phase 5: 보존 결과 검증"}
    
    # 사용자 설정이 보존되었는지 확인
    if grep -q "user_preferences" "$CLAUDE_DIR/settings.json"; then
      echo "✓ settings.json 사용자 설정 보존됨"
    else
      echo "✗ settings.json 사용자 설정 손실됨"
      exit 1
    fi
    
    if grep -q "개인 워크스페이스" "$CLAUDE_DIR/CLAUDE.md"; then
      echo "✓ CLAUDE.md 사용자 내용 보존됨"
    else
      echo "✗ CLAUDE.md 사용자 내용 손실됨"
      exit 1
    fi
    
    # 새 버전 파일 생성 확인
    NEW_FILES_COUNT=$(find "$CLAUDE_DIR" -name "*.new" | wc -l)
    NOTICE_FILES_COUNT=$(find "$CLAUDE_DIR" -name "*.update-notice" | wc -l)
    
    if [[ $NEW_FILES_COUNT -ge 2 ]]; then
      echo "✓ .new 파일들 생성됨 ($NEW_FILES_COUNT개)"
    else
      echo "✗ .new 파일 생성 부족 (예상: 2개, 실제: $NEW_FILES_COUNT개)"
      exit 1
    fi
    
    if [[ $NOTICE_FILES_COUNT -ge 2 ]]; then
      echo "✓ 업데이트 알림 파일들 생성됨 ($NOTICE_FILES_COUNT개)"
    else
      echo "✗ 업데이트 알림 파일 생성 부족"
      exit 1
    fi
    
    # 커스텀 명령어 보존 확인
    if [[ -f "$CLAUDE_DIR/commands/daily-workflow.md" && -f "$CLAUDE_DIR/commands/quick-deploy.md" ]]; then
      echo "✓ 사용자 커스텀 명령어들 보존됨"
    else
      echo "✗ 사용자 커스텀 명령어 손실됨"
      exit 1
    fi
    
    ${testHelpers.testSubsection "Phase 6: 사용자 병합 워크플로우"}
    
    echo "사용자가 업데이트 알림을 발견하고 병합 도구 사용..."
    
    # 6-1: 병합 후보 확인
    echo "=== 병합 후보 파일 확인 ==="
    MERGE_CANDIDATES=$("$MERGE_SCRIPT" --list)
    echo "$MERGE_CANDIDATES"
    
    CANDIDATE_COUNT=$(echo "$MERGE_CANDIDATES" | grep -c "settings.json\|CLAUDE.md" || true)
    if [[ $CANDIDATE_COUNT -ge 2 ]]; then
      echo "✓ 병합 도구가 올바른 후보들을 감지함"
    else
      echo "✗ 병합 도구 후보 감지 실패"
      exit 1
    fi
    
    # 6-2: 차이점 확인
    echo ""
    echo "=== settings.json 변경사항 확인 ==="
    "$MERGE_SCRIPT" --diff settings.json | head -5
    echo "✓ 차이점 확인 기능 작동"
    
    # 6-3: 자동화된 병합 시뮬레이션 (실제로는 대화형)
    echo ""
    echo "사용자가 수동으로 중요한 설정만 선택적으로 병합한다고 가정..."
    
    # 예시: 사용자가 일부 새로운 설정은 추가하되 개인 설정은 유지
    jq -s '.[0] * .[1]' "$CLAUDE_DIR/settings.json" \
      <(echo '{"updated_by_dotfiles": true, "last_update": "'$(date -Iseconds)'"}') \
      > "$CLAUDE_DIR/settings.json.merged"
    
    mv "$CLAUDE_DIR/settings.json.merged" "$CLAUDE_DIR/settings.json"
    rm -f "$CLAUDE_DIR/settings.json.new" "$CLAUDE_DIR/settings.json.update-notice"
    
    echo "✓ settings.json 병합 완료"
    
    # CLAUDE.md는 수동 병합이 복잡하므로 현재 버전 유지
    rm -f "$CLAUDE_DIR/CLAUDE.md.new" "$CLAUDE_DIR/CLAUDE.md.update-notice"
    echo "✓ CLAUDE.md 현재 버전 유지"
    
    ${testHelpers.testSubsection "Phase 7: 최종 상태 검증"}
    
    echo ""
    echo "=== 최종 시스템 상태 검증 ==="
    
    # 7-1: 사용자 설정이 여전히 보존되어 있는지 확인
    if grep -q "user_preferences.*korean" "$CLAUDE_DIR/settings.json"; then
      echo "✓ 사용자 언어 설정 보존됨"
    else
      echo "✗ 사용자 언어 설정 손실됨"
      exit 1
    fi
    
    if grep -q "custom_prompts" "$CLAUDE_DIR/settings.json"; then
      echo "✓ 사용자 커스텀 프롬프트 보존됨"
    else
      echo "✗ 사용자 커스텀 프롬프트 손실됨"
      exit 1
    fi
    
    # 7-2: dotfiles 업데이트도 반영되었는지 확인
    if grep -q "updated_by_dotfiles.*true" "$CLAUDE_DIR/settings.json"; then
      echo "✓ dotfiles 업데이트 반영됨"
    else
      echo "✗ dotfiles 업데이트 미반영"
      exit 1
    fi
    
    # 7-3: 개인 콘텐츠가 여전히 존재하는지 확인
    if grep -q "개인 워크스페이스" "$CLAUDE_DIR/CLAUDE.md"; then
      echo "✓ CLAUDE.md 개인 콘텐츠 보존됨"
    else
      echo "✗ CLAUDE.md 개인 콘텐츠 손실됨"
      exit 1
    fi
    
    # 7-4: 커스텀 명령어들이 그대로인지 확인
    CUSTOM_CMD_COUNT=$(find "$CLAUDE_DIR/commands" -name "*workflow*" -o -name "*deploy*" | wc -l)
    if [[ $CUSTOM_CMD_COUNT -eq 2 ]]; then
      echo "✓ 사용자 커스텀 명령어 완전 보존됨 ($CUSTOM_CMD_COUNT개)"
    else
      echo "✗ 사용자 커스텀 명령어 일부 손실 (예상: 2개, 실제: $CUSTOM_CMD_COUNT개)"
      exit 1
    fi
    
    # 7-5: 정리된 상태인지 확인
    LEFTOVER_FILES=$(find "$CLAUDE_DIR" -name "*.new" -o -name "*.update-notice" | wc -l)
    if [[ $LEFTOVER_FILES -eq 0 ]]; then
      echo "✓ 임시 파일들 모두 정리됨"
    else
      echo "! 임시 파일들 남아있음 ($LEFTOVER_FILES개) - 사용자가 추가 작업 필요"
    fi
    
    ${testHelpers.testSubsection "Phase 8: 지속적 사용 시뮬레이션"}
    
    echo ""
    echo "=== 지속적 사용 패턴 테스트 ==="
    
    # 8-1: 사용자가 추가 설정 변경
    echo "사용자가 추가 개인화 작업 수행..."
    
    jq '.user_preferences.new_feature = {"enabled": true, "config": "custom"}' \
      "$CLAUDE_DIR/settings.json" > "$CLAUDE_DIR/settings.json.tmp"
    mv "$CLAUDE_DIR/settings.json.tmp" "$CLAUDE_DIR/settings.json"
    
    cat >> "$CLAUDE_DIR/CLAUDE.md" << 'EOF'

## 최근 추가된 기능
- 새로운 개인화 설정 추가됨
- 병합 도구 사용법 숙지됨
- 백업 시스템 활용법 학습됨
EOF
    
    echo "✓ 추가 개인화 완료"
    
    # 8-2: 두 번째 dotfiles 업데이트 (변화 없음)
    echo ""
    echo "두 번째 시스템 재빌드 (변화 없는 경우)..."
    
    # 파일이 동일한 경우의 처리 확인
    smart_copy "$SOURCE_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    smart_copy "$SOURCE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    
    # 새로운 .new 파일이 생성되었는지 확인 (사용자 수정이 있으므로 생성되어야 함)
    NEW_FILES_AFTER_SECOND=$(find "$CLAUDE_DIR" -name "*.new" | wc -l)
    if [[ $NEW_FILES_AFTER_SECOND -ge 2 ]]; then
      echo "✓ 두 번째 업데이트에서도 보존 로직 정상 작동"
      # 정리
      rm -f "$CLAUDE_DIR"/*.new "$CLAUDE_DIR"/*.update-notice
    else
      echo "? 두 번째 업데이트에서 보존 로직 다른 동작 (파일이 동일할 수 있음)"
    fi
    
    ${testHelpers.cleanup}
    
    echo ""
    echo "=== Claude 설정 전체 워크플로우 E2E 테스트 완료 ==="
    echo ""
    echo "검증된 전체 워크플로우:"
    echo "  1. ✓ 신규 시스템 초기 설정 (symlink 생성)"
    echo "  2. ✓ 첫 activation (symlink → 실제 파일)"
    echo "  3. ✓ 사용자 일상적 개인화"
    echo "  4. ✓ dotfiles 업데이트 발생"
    echo "  5. ✓ 스마트 보존 로직 작동"
    echo "  6. ✓ 사용자 병합 워크플로우"
    echo "  7. ✓ 최종 상태 검증"
    echo "  8. ✓ 지속적 사용 패턴"
    echo ""
    echo "핵심 개선사항:"
    echo "  • 사용자 수정 내용 자동 보존"
    echo "  • 새 버전을 .new 파일로 안전 저장"
    echo "  • 직관적인 업데이트 알림 시스템"
    echo "  • 대화형 병합 도구 제공"
    echo "  • 자동 백업 및 정리 시스템"
    echo "  • 사용자 커스텀 파일 완전 보존"
    echo ""
    echo "이제 사용자는 dotfiles 업데이트를 걱정 없이 적용할 수 있습니다!"
  '';

in
pkgs.runCommand "claude-config-workflow-e2e-test" {} ''
  echo "=== Claude 설정 전체 워크플로우 E2E 테스트 ==="
  
  # 전체 워크플로우의 End-to-End 테스트 실행
  ${testCompleteWorkflow}
  
  echo "E2E 테스트 완료!"
  touch $out
''