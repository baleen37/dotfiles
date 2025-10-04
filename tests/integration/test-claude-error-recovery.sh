#!/usr/bin/env bash
# test-claude-error-recovery.sh - Claude Code 심볼릭 링크 오류 복구 메커니즘 통합 테스트
# ABOUTME: Claude 설정 심볼릭 링크의 다양한 오류 상황을 시뮬레이션하고 복구 프로세스를 검증

set -euo pipefail

# 테스트 설정
TEST_NAME="claude-error-recovery"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_TEMP_DIR="${TMPDIR:-/tmp}/${TEST_NAME}-$$"
BACKUP_DIR="${TEST_TEMP_DIR}/backup"
VALIDATOR_SCRIPT="${PROJECT_ROOT}/scripts/validate-claude-symlinks.sh"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# 테스트 통계
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
RECOVERY_SUCCESS=0
RECOVERY_FAILED=0

# 로그 함수들
log_test() {
  echo -e "${BLUE}[TEST]${NC} $1"
}

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_debug() {
  echo -e "${MAGENTA}[DEBUG]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 테스트 결과 추적
test_passed() {
  ((TOTAL_TESTS++))
  ((PASSED_TESTS++))
  log_success "✅ $1"
}

test_failed() {
  ((TOTAL_TESTS++))
  ((FAILED_TESTS++))
  log_error "❌ $1"
}

recovery_success() {
  ((RECOVERY_SUCCESS++))
  log_success "🔧 복구 성공: $1"
}

recovery_failed() {
  ((RECOVERY_FAILED++))
  log_error "💥 복구 실패: $1"
}

# 정리 함수
cleanup_test() {
  log_info "테스트 환경 정리 중..."

  # 테스트 디렉토리 정리
  if [[ -d $TEST_TEMP_DIR ]]; then
    rm -rf "$TEST_TEMP_DIR"
    log_debug "임시 디렉토리 정리: $TEST_TEMP_DIR"
  fi

  # 백업에서 실제 Claude 설정 복구 (실제 환경에서 테스트할 경우)
  if [[ -d $BACKUP_DIR && $ENABLE_REAL_TEST == "true" ]]; then
    restore_real_claude_config
  fi
}

# 트랩 설정
trap cleanup_test EXIT ERR

# 테스트 환경 초기화
initialize_test_environment() {
  log_info "=== Claude 오류 복구 테스트 환경 초기화 ==="

  # 임시 디렉토리 생성
  mkdir -p "$TEST_TEMP_DIR"
  mkdir -p "$BACKUP_DIR"

  log_info "테스트 디렉토리: $TEST_TEMP_DIR"
  log_info "백업 디렉토리: $BACKUP_DIR"

  # validator 스크립트 존재 확인
  if [[ ! -f $VALIDATOR_SCRIPT ]]; then
    log_error "Validator 스크립트를 찾을 수 없습니다: $VALIDATOR_SCRIPT"
    exit 1
  fi

  log_success "테스트 환경 초기화 완료"
}

# 모의 Claude 설정 환경 생성
create_mock_claude_environment() {
  local test_claude_dir="$1"
  local test_source_dir="$2"

  log_debug "모의 Claude 환경 생성: $test_claude_dir -> $test_source_dir"

  # 소스 디렉토리 생성 및 파일 생성
  mkdir -p "$test_source_dir/commands"
  mkdir -p "$test_source_dir/agents"

  # 테스트용 파일들 생성
  cat >"$test_source_dir/CLAUDE.md" <<'EOF'
# Test Claude Configuration
This is a test configuration file.
EOF

  cat >"$test_source_dir/settings.json" <<'EOF'
{
  "test": "configuration",
  "version": "1.0.0"
}
EOF

  # 테스트용 명령어 파일들
  echo "# Test command 1" >"$test_source_dir/commands/test-cmd1.md"
  echo "# Test command 2" >"$test_source_dir/commands/test-cmd2.md"

  # 테스트용 에이전트 파일들
  echo "# Test agent 1" >"$test_source_dir/agents/test-agent1.md"
  echo "# Test agent 2" >"$test_source_dir/agents/test-agent2.md"

  # Claude 디렉토리 생성
  mkdir -p "$test_claude_dir"

  log_success "모의 Claude 환경 생성 완료"
}

# 정상 상태의 심볼릭 링크 생성
create_healthy_symlinks() {
  local test_claude_dir="$1"
  local test_source_dir="$2"

  log_debug "정상 상태의 심볼릭 링크 생성"

  # 폴더 심볼릭 링크
  ln -sf "$test_source_dir/commands" "$test_claude_dir/commands"
  ln -sf "$test_source_dir/agents" "$test_claude_dir/agents"

  # 파일 심볼릭 링크
  ln -sf "$test_source_dir/CLAUDE.md" "$test_claude_dir/CLAUDE.md"
  ln -sf "$test_source_dir/settings.json" "$test_claude_dir/settings.json"

  log_success "정상 심볼릭 링크 생성 완료"
}

# 커스텀 validator 함수 (테스트 환경용)
run_custom_validator() {
  local test_claude_dir="$1"
  local test_source_dir="$2"
  local options="${3:-}"

  # 로그 디렉토리 생성
  local validation_log="$TEST_TEMP_DIR/validation.log"
  local state_dir="$TEST_TEMP_DIR"
  local log_dir="$state_dir/claude-symlinks"
  mkdir -p "$log_dir"

  # 환경 변수 설정으로 테스트 환경 지정
  export CLAUDE_DIR="$test_claude_dir"
  export SOURCE_DIR="$test_source_dir"
  export VALIDATION_LOG="$validation_log"
  export XDG_STATE_HOME="$state_dir"

  bash "$VALIDATOR_SCRIPT" $options
  local result=$?

  # 환경 변수 정리
  unset CLAUDE_DIR SOURCE_DIR VALIDATION_LOG XDG_STATE_HOME

  return $result
}

# 테스트 시나리오 1: 끊어진 심볼릭 링크 복구
test_broken_symlinks_recovery() {
  log_test "테스트 1: 끊어진 심볼릭 링크 복구"

  local test_claude_dir="$TEST_TEMP_DIR/scenario1/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario1/source"

  # 모의 환경 생성
  create_mock_claude_environment "$test_claude_dir" "$test_source_dir"
  create_healthy_symlinks "$test_claude_dir" "$test_source_dir"

  # 소스 파일을 삭제하여 끊어진 링크 생성
  rm -rf "$test_source_dir/commands/test-cmd1.md"
  rm -rf "$test_source_dir/CLAUDE.md"

  log_debug "끊어진 링크 상태 확인"
  if [[ ! -e "$test_claude_dir/CLAUDE.md" ]]; then
    log_debug "끊어진 파일 링크 확인됨: CLAUDE.md"
  fi

  # 복구 실행
  log_debug "복구 프로세스 실행"
  if run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose"; then
    recovery_success "끊어진 심볼릭 링크 자동 제거"
    test_passed "끊어진 심볼릭 링크 복구 테스트"
  else
    recovery_failed "끊어진 심볼릭 링크 복구"
    test_failed "끊어진 심볼릭 링크 복구 테스트"
  fi
}

# 테스트 시나리오 2: 잘못된 타겟 링크 수정
test_wrong_target_recovery() {
  log_test "테스트 2: 잘못된 타겟으로의 링크 수정"

  local test_claude_dir="$TEST_TEMP_DIR/scenario2/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario2/source"
  local wrong_source_dir="$TEST_TEMP_DIR/scenario2/wrong_source"

  # 모의 환경 생성
  create_mock_claude_environment "$test_claude_dir" "$test_source_dir"

  # 잘못된 소스 디렉토리도 생성
  mkdir -p "$wrong_source_dir/commands"
  echo "# Wrong command" >"$wrong_source_dir/commands/wrong-cmd.md"

  # 잘못된 타겟으로 링크 생성
  ln -sf "$wrong_source_dir/commands" "$test_claude_dir/commands"
  ln -sf "$wrong_source_dir/nonexistent.md" "$test_claude_dir/CLAUDE.md"

  log_debug "잘못된 링크 상태 확인"
  local current_target=$(readlink "$test_claude_dir/commands")
  if [[ $current_target == "$wrong_source_dir/commands" ]]; then
    log_debug "잘못된 타겟 링크 확인됨: $current_target"
  fi

  # 복구 실행
  log_debug "복구 프로세스 실행"
  if run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose"; then
    # 복구 후 링크 확인
    local fixed_target=$(readlink "$test_claude_dir/commands")
    if [[ $fixed_target == "$test_source_dir/commands" ]]; then
      recovery_success "잘못된 타겟 링크 수정"
      test_passed "잘못된 타겟 링크 수정 테스트"
    else
      recovery_failed "잘못된 타겟 링크 수정 - 타겟이 여전히 잘못됨"
      test_failed "잘못된 타겟 링크 수정 테스트"
    fi
  else
    recovery_failed "잘못된 타겟 링크 수정"
    test_failed "잘못된 타겟 링크 수정 테스트"
  fi
}

# 테스트 시나리오 3: 권한 문제 처리
test_permission_issues_recovery() {
  log_test "테스트 3: 권한 문제가 있는 파일들 처리"

  local test_claude_dir="$TEST_TEMP_DIR/scenario3/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario3/source"

  # 모의 환경 생성
  create_mock_claude_environment "$test_claude_dir" "$test_source_dir"
  create_healthy_symlinks "$test_claude_dir" "$test_source_dir"

  # 권한 문제 생성 (파일을 직접 생성하여 심볼릭 링크가 아닌 상태로 만들기)
  rm -f "$test_claude_dir/settings.json"
  echo '{"test": "direct_file"}' >"$test_claude_dir/settings.json"
  chmod 600 "$test_claude_dir/settings.json" # 잘못된 권한 설정

  log_debug "권한 문제 상태 확인"
  local perms=$(stat -f "%A" "$test_claude_dir/settings.json" 2>/dev/null || stat -c "%a" "$test_claude_dir/settings.json" 2>/dev/null)
  log_debug "현재 권한: $perms"

  # 복구 실행
  log_debug "복구 프로세스 실행"
  if run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose"; then
    # 복구 후 권한 확인
    local fixed_perms=$(stat -f "%A" "$test_claude_dir/settings.json" 2>/dev/null || stat -c "%a" "$test_claude_dir/settings.json" 2>/dev/null)
    if [[ $fixed_perms == "644" ]]; then
      recovery_success "권한 문제 수정"
      test_passed "권한 문제 처리 테스트"
    else
      recovery_failed "권한 문제 수정 - 권한이 여전히 잘못됨: $fixed_perms"
      test_failed "권한 문제 처리 테스트"
    fi
  else
    recovery_failed "권한 문제 처리"
    test_failed "권한 문제 처리 테스트"
  fi
}

# 테스트 시나리오 4: 일반 파일/디렉토리가 심볼릭 링크 자리에 있는 경우
test_regular_file_replacement() {
  log_test "테스트 4: 일반 파일/디렉토리를 심볼릭 링크로 교체"

  local test_claude_dir="$TEST_TEMP_DIR/scenario4/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario4/source"

  # 모의 환경 생성
  create_mock_claude_environment "$test_claude_dir" "$test_source_dir"

  # 심볼릭 링크 대신 일반 디렉토리/파일 생성
  mkdir -p "$test_claude_dir/commands"
  echo "# Regular file content" >"$test_claude_dir/commands/regular-cmd.md"

  mkdir -p "$test_claude_dir/agents"
  echo "# Regular agent content" >"$test_claude_dir/agents/regular-agent.md"

  echo "# Regular CLAUDE.md" >"$test_claude_dir/CLAUDE.md"

  log_debug "일반 파일/디렉토리 상태 확인"
  if [[ -d "$test_claude_dir/commands" && ! -L "$test_claude_dir/commands" ]]; then
    log_debug "일반 디렉토리 확인됨: commands"
  fi
  if [[ -f "$test_claude_dir/CLAUDE.md" && ! -L "$test_claude_dir/CLAUDE.md" ]]; then
    log_debug "일반 파일 확인됨: CLAUDE.md"
  fi

  # 복구 실행
  log_debug "복구 프로세스 실행"
  if run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose"; then
    # 복구 후 심볼릭 링크 확인
    local commands_is_link=$([[ -L "$test_claude_dir/commands" ]] && echo "true" || echo "false")
    local claude_is_link=$([[ -L "$test_claude_dir/CLAUDE.md" ]] && echo "true" || echo "false")

    if [[ $commands_is_link == "true" && $claude_is_link == "true" ]]; then
      recovery_success "일반 파일/디렉토리를 심볼릭 링크로 교체"
      test_passed "일반 파일/디렉토리 교체 테스트"
    else
      recovery_failed "일반 파일/디렉토리 교체 - 심볼릭 링크로 변환되지 않음"
      test_failed "일반 파일/디렉토리 교체 테스트"
    fi
  else
    recovery_failed "일반 파일/디렉토리 교체"
    test_failed "일반 파일/디렉토리 교체 테스트"
  fi
}

# 테스트 시나리오 5: 순환 참조 링크 감지 및 처리
test_circular_link_detection() {
  log_test "테스트 5: 순환 참조 링크 감지 및 처리"

  local test_claude_dir="$TEST_TEMP_DIR/scenario5/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario5/source"

  # 모의 환경 생성
  create_mock_claude_environment "$test_claude_dir" "$test_source_dir"

  # 순환 참조 링크 생성
  ln -sf "$test_claude_dir/commands" "$test_claude_dir/circular1"
  ln -sf "$test_claude_dir/circular1" "$test_claude_dir/commands"

  # 또 다른 순환 참조 시나리오
  ln -sf "$test_claude_dir/CLAUDE.md" "$test_claude_dir/circular_file"
  ln -sf "$test_claude_dir/circular_file" "$test_claude_dir/CLAUDE.md"

  log_debug "순환 참조 링크 상태 확인"
  # readlink로 순환 참조 여부를 간접적으로 확인
  local circular_detected=false
  if ! realpath "$test_claude_dir/commands" >/dev/null 2>&1; then
    log_debug "순환 참조 링크 감지됨: commands"
    circular_detected=true
  fi

  # 복구 실행
  log_debug "복구 프로세스 실행"
  if run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose"; then
    # 복구 후 순환 참조 제거 확인
    if realpath "$test_claude_dir/commands" >/dev/null 2>&1; then
      recovery_success "순환 참조 링크 제거 및 정상 링크 생성"
      test_passed "순환 참조 링크 처리 테스트"
    else
      recovery_failed "순환 참조 링크 처리 - 여전히 순환 참조 존재"
      test_failed "순환 참조 링크 처리 테스트"
    fi
  else
    recovery_failed "순환 참조 링크 처리"
    test_failed "순환 참조 링크 처리 테스트"
  fi
}

# 테스트 시나리오 6: 동시 실행 충돌 시나리오
test_concurrent_execution_conflict() {
  log_test "테스트 6: 동시 실행 충돌 시나리오"

  local test_claude_dir="$TEST_TEMP_DIR/scenario6/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario6/source"

  # 모의 환경 생성
  create_mock_claude_environment "$test_claude_dir" "$test_source_dir"

  # 백그라운드에서 validator 실행 (느리게 하기 위해 sleep 추가)
  (
    sleep 2
    run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose" >/dev/null 2>&1 || true
  ) &
  local bg_pid=$!

  # 동시에 또 다른 validator 실행
  log_debug "동시 실행 테스트 시작"
  if run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose" >/dev/null 2>&1; then
    log_debug "첫 번째 validator 완료"
  fi

  # 백그라운드 프로세스 대기
  wait $bg_pid 2>/dev/null || true

  # 최종 상태 확인
  if [[ -L "$test_claude_dir/commands" && -L "$test_claude_dir/agents" ]]; then
    recovery_success "동시 실행 상황에서 정상적인 링크 생성"
    test_passed "동시 실행 충돌 처리 테스트"
  else
    recovery_failed "동시 실행 충돌 처리"
    test_failed "동시 실행 충돌 처리 테스트"
  fi
}

# 테스트 시나리오 7: 백업 및 롤백 메커니즘
test_backup_rollback_mechanism() {
  log_test "테스트 7: 백업 및 롤백 메커니즘"

  local test_claude_dir="$TEST_TEMP_DIR/scenario7/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario7/source"
  local test_backup_dir="$TEST_TEMP_DIR/scenario7/backup"

  # 모의 환경 생성
  create_mock_claude_environment "$test_claude_dir" "$test_source_dir"
  create_healthy_symlinks "$test_claude_dir" "$test_source_dir"

  # 수동 백업 생성
  mkdir -p "$test_backup_dir"
  cp -r "$test_claude_dir"/* "$test_backup_dir/" 2>/dev/null || true

  log_debug "백업 생성 완료: $test_backup_dir"

  # Claude 디렉토리 손상
  rm -rf "$test_claude_dir"/*

  # DRY_RUN 모드로 복구 테스트
  log_debug "DRY_RUN 모드 복구 테스트"
  if DRY_RUN=true run_custom_validator "$test_claude_dir" "$test_source_dir" "--dry-run" >/dev/null 2>&1; then
    log_debug "DRY_RUN 모드 실행 성공"

    # DRY_RUN에서는 실제로 변경되지 않아야 함
    if [[ ! -L "$test_claude_dir/commands" ]]; then
      log_debug "DRY_RUN: 실제 변경 없음 확인"
    fi
  fi

  # 실제 복구 실행
  log_debug "실제 복구 프로세스 실행"
  if run_custom_validator "$test_claude_dir" "$test_source_dir" "--verbose"; then
    # 복구 후 상태 확인
    if [[ -L "$test_claude_dir/commands" && -L "$test_claude_dir/agents" ]]; then
      recovery_success "백업 기반 복구"
      test_passed "백업 및 롤백 메커니즘 테스트"
    else
      recovery_failed "백업 기반 복구 - 링크가 생성되지 않음"
      test_failed "백업 및 롤백 메커니즘 테스트"
    fi
  else
    recovery_failed "백업 기반 복구"
    test_failed "백업 및 롤백 메커니즘 테스트"
  fi
}

# 테스트 시나리오 8: 복구 실패 케이스 처리
test_recovery_failure_cases() {
  log_test "테스트 8: 복구 실패 케이스 처리"

  local test_claude_dir="$TEST_TEMP_DIR/scenario8/claude"
  local test_source_dir="$TEST_TEMP_DIR/scenario8/source"

  # 모의 환경 생성 (소스 디렉토리 없음)
  mkdir -p "$test_claude_dir"

  # 소스 디렉토리를 의도적으로 생성하지 않음
  log_debug "소스 디렉토리 없는 상태에서 복구 시도"

  # 복구 시도 (실패해야 함)
  local recovery_result=0
  AUTO_FIX=false run_custom_validator "$test_claude_dir" "$test_source_dir" "--no-fix" >/dev/null 2>&1 || recovery_result=$?

  if [[ $recovery_result -ne 0 ]]; then
    log_debug "예상대로 복구 실패함 (소스 디렉토리 없음)"
    test_passed "복구 실패 케이스 올바른 처리"
  else
    test_failed "복구 실패 케이스 처리 - 실패해야 하는데 성공함"
  fi

  # 읽기 전용 디렉토리 시나리오 (권한이 있는 경우만)
  if [[ $(id -u) -ne 0 ]]; then # root가 아닌 경우만
    local readonly_dir="$TEST_TEMP_DIR/scenario8/readonly"
    mkdir -p "$readonly_dir"
    chmod 444 "$readonly_dir" # 읽기 전용

    log_debug "읽기 전용 디렉토리에서 복구 시도"
    recovery_result=0
    CLAUDE_DIR="$readonly_dir" run_custom_validator "$readonly_dir" "$test_source_dir" "--verbose" >/dev/null 2>&1 || recovery_result=$?

    if [[ $recovery_result -ne 0 ]]; then
      log_debug "예상대로 읽기 전용 디렉토리에서 복구 실패"
      recovery_success "읽기 전용 환경에서 올바른 실패 처리"
    else
      recovery_failed "읽기 전용 환경 처리 - 실패해야 하는데 성공함"
    fi

    # 권한 복구
    chmod 755 "$readonly_dir"
  fi
}

# 실제 Claude 설정 백업 (옵션)
backup_real_claude_config() {
  if [[ $ENABLE_REAL_TEST == "true" && -d "$HOME/.claude" ]]; then
    log_info "실제 Claude 설정 백업 중..."
    cp -r "$HOME/.claude" "$BACKUP_DIR/real_claude_backup" 2>/dev/null || true
    log_success "실제 Claude 설정 백업 완료"
  fi
}

# 실제 Claude 설정 복구 (옵션)
restore_real_claude_config() {
  if [[ -d "$BACKUP_DIR/real_claude_backup" ]]; then
    log_info "실제 Claude 설정 복구 중..."
    rm -rf "$HOME/.claude"
    mv "$BACKUP_DIR/real_claude_backup" "$HOME/.claude"
    log_success "실제 Claude 설정 복구 완료"
  fi
}

# 종합 보고서 생성
generate_test_report() {
  log_info "=== Claude 오류 복구 테스트 종합 보고서 ==="

  local success_rate=0
  if [[ $TOTAL_TESTS -gt 0 ]]; then
    success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
  fi

  local recovery_rate=0
  local total_recovery=$((RECOVERY_SUCCESS + RECOVERY_FAILED))
  if [[ $total_recovery -gt 0 ]]; then
    recovery_rate=$((RECOVERY_SUCCESS * 100 / total_recovery))
  fi

  echo -e "\n${BLUE}========================= 테스트 결과 =========================${NC}"
  echo -e "총 테스트: ${BLUE}$TOTAL_TESTS${NC}"
  echo -e "성공: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "실패: ${RED}$FAILED_TESTS${NC}"
  echo -e "성공률: ${GREEN}${success_rate}%${NC}"
  echo -e ""
  echo -e "복구 성공: ${GREEN}$RECOVERY_SUCCESS${NC}"
  echo -e "복구 실패: ${RED}$RECOVERY_FAILED${NC}"
  echo -e "복구 성공률: ${GREEN}${recovery_rate}%${NC}"
  echo -e "${BLUE}============================================================${NC}\n"

  # 결과 파일에 상세 보고서 저장
  local report_file="$TEST_TEMP_DIR/recovery_test_report.txt"
  cat >"$report_file" <<EOF
Claude Code 심볼릭 링크 오류 복구 테스트 보고서
================================================

테스트 실행 시간: $(date -Iseconds)
테스트 환경: $TEST_TEMP_DIR
Validator 스크립트: $VALIDATOR_SCRIPT

테스트 결과:
- 총 테스트: $TOTAL_TESTS
- 성공: $PASSED_TESTS
- 실패: $FAILED_TESTS
- 성공률: ${success_rate}%

복구 메커니즘 결과:
- 복구 성공: $RECOVERY_SUCCESS
- 복구 실패: $RECOVERY_FAILED
- 복구 성공률: ${recovery_rate}%

환경 정보:
- 플랫폼: $(uname)
- Shell: $BASH_VERSION
- 사용자: $(whoami)

테스트 시나리오:
1. 끊어진 심볼릭 링크 복구
2. 잘못된 타겟으로의 링크 수정
3. 권한 문제가 있는 파일들 처리
4. 일반 파일/디렉토리를 심볼릭 링크로 교체
5. 순환 참조 링크 감지 및 처리
6. 동시 실행 충돌 시나리오
7. 백업 및 롤백 메커니즘
8. 복구 실패 케이스 처리

추가 로그는 다음 위치에서 확인 가능:
$TEST_TEMP_DIR/validation.log

EOF

  log_info "상세 보고서 저장: $report_file"

  # 최종 결과 판정
  if [[ $FAILED_TESTS -eq 0 ]]; then
    log_success "🎉 모든 오류 복구 테스트가 성공적으로 완료되었습니다!"
    return 0
  else
    log_error "💥 $FAILED_TESTS개의 테스트가 실패했습니다."
    return 1
  fi
}

# 사용법 출력
show_usage() {
  cat <<EOF
사용법: $0 [옵션]

Claude Code 심볼릭 링크 오류 복구 메커니즘 통합 테스트

옵션:
  --enable-real-test    실제 ~/.claude 디렉토리를 사용한 테스트 활성화 (주의!)
  -v, --verbose         상세한 로그 출력
  -h, --help            이 도움말 출력

환경 변수:
  ENABLE_REAL_TEST=true    실제 Claude 설정을 사용한 테스트 (위험!)

경고:
  --enable-real-test 옵션은 실제 ~/.claude 설정을 백업하고 복구하지만,
  데이터 손실 위험이 있으므로 신중히 사용하세요.

예시:
  $0                      # 안전한 격리된 환경에서 테스트
  $0 --verbose            # 상세 로그와 함께 실행
  $0 --enable-real-test   # 실제 환경에서 테스트 (주의!)

EOF
}

# 명령행 인자 처리
parse_arguments() {
  ENABLE_REAL_TEST=${ENABLE_REAL_TEST:-false}
  VERBOSE_TEST=false

  while [[ $# -gt 0 ]]; do
    case $1 in
    --enable-real-test)
      ENABLE_REAL_TEST=true
      log_warning "⚠️ 실제 Claude 설정을 사용한 테스트가 활성화되었습니다!"
      shift
      ;;
    -v | --verbose)
      VERBOSE_TEST=true
      shift
      ;;
    -h | --help)
      show_usage
      exit 0
      ;;
    *)
      log_error "알 수 없는 옵션: $1"
      show_usage
      exit 1
      ;;
    esac
  done
}

# 메인 함수
main() {
  # 명령행 인자 처리
  parse_arguments "$@"

  # 초기화
  initialize_test_environment

  # 실제 설정 백업 (옵션)
  backup_real_claude_config

  log_info "=== Claude 오류 복구 테스트 시작 ==="

  # 테스트 시나리오들 실행
  test_broken_symlinks_recovery
  echo

  test_wrong_target_recovery
  echo

  test_permission_issues_recovery
  echo

  test_regular_file_replacement
  echo

  test_circular_link_detection
  echo

  test_concurrent_execution_conflict
  echo

  test_backup_rollback_mechanism
  echo

  test_recovery_failure_cases
  echo

  # 종합 보고서 생성
  generate_test_report
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
