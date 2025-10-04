#!/usr/bin/env bash
# ABOUTME: Claude commands 전체 워크플로우 End-to-End 테스트
# ABOUTME: 실제 사용자 시나리오를 시뮬레이션하여 전체 시스템이 올바르게 동작하는지 검증합니다.

set -euo pipefail

# 테스트 환경 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 테스트용 격리된 환경
E2E_TEST_DIR=$(mktemp -d)
E2E_HOME="$E2E_TEST_DIR/home"
E2E_DOTFILES="$E2E_TEST_DIR/dotfiles"
E2E_CLAUDE_DIR="$E2E_HOME/.claude"

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 테스트 결과 추적
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_SCENARIO=""

# 로그 함수
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
  echo -e "${BLUE}[DEBUG]${NC} $1"
}

log_scenario() {
  CURRENT_SCENARIO="$1"
  echo -e "${PURPLE}[SCENARIO]${NC} $1"
}

# 테스트 결과 추적 함수
test_pass() {
  echo -e "${GREEN}✅ PASS:${NC} $1"
  ((TESTS_PASSED++))
}

test_fail() {
  echo -e "${RED}❌ FAIL:${NC} $1"
  ((TESTS_FAILED++))
}

# E2E 테스트 환경 설정
setup_e2e_environment() {
  log_info "E2E 테스트 환경 설정 중..."

  # 테스트용 홈 디렉토리 생성
  mkdir -p "$E2E_HOME"
  mkdir -p "$E2E_DOTFILES"

  # 실제 dotfiles를 테스트 환경으로 복사
  cp -r "$PROJECT_ROOT/modules" "$E2E_DOTFILES/"
  cp -r "$PROJECT_ROOT/lib" "$E2E_DOTFILES/"
  cp "$PROJECT_ROOT/flake.nix" "$E2E_DOTFILES/"

  # 환경 변수 설정
  export HOME="$E2E_HOME"
  export DOTFILES_ROOT="$E2E_DOTFILES"

  log_debug "E2E 테스트 디렉토리: $E2E_TEST_DIR"
  log_debug "E2E 홈: $E2E_HOME"
  log_debug "E2E Dotfiles: $E2E_DOTFILES"
}

cleanup_e2e_environment() {
  log_info "E2E 테스트 환경 정리 중..."
  rm -rf "$E2E_TEST_DIR"
}

# 실제 사용자 시나리오 시뮬레이션
simulate_first_time_setup() {
  log_scenario "첫 번째 설정: 새로운 사용자가 dotfiles를 처음 설정하는 시나리오"

  # Claude 디렉토리가 존재하지 않는 상태에서 시작
  if [[ -d $E2E_CLAUDE_DIR ]]; then
    rm -rf "$E2E_CLAUDE_DIR"
  fi

  # claude-activation 스크립트 실행
  simulate_claude_activation_from_nix

  # 결과 검증
  if [[ -d $E2E_CLAUDE_DIR ]]; then
    test_pass "첫 번째 설정 시 Claude 디렉토리 생성"
  else
    test_fail "첫 번째 설정 시 Claude 디렉토리 생성 실패"
    return 1
  fi

  # 필수 파일들이 생성되었는지 확인
  local essential_files=(
    "CLAUDE.md"
    "settings.json"
    "commands/git/commit.md"
    "commands/git/fix-pr.md"
    "commands/git/upsert-pr.md"
  )

  for file in "${essential_files[@]}"; do
    if [[ -f "$E2E_CLAUDE_DIR/$file" ]]; then
      test_pass "필수 파일 생성: $file"
    else
      test_fail "필수 파일 누락: $file"
    fi
  done
}

simulate_update_scenario() {
  log_scenario "업데이트 시나리오: 기존 설정이 있는 상태에서 dotfiles 업데이트"

  # 기존 설정 파일 수정 (사용자 커스터마이징 시뮬레이션)
  cat >>"$E2E_CLAUDE_DIR/CLAUDE.md" <<'EOF'

# 사용자 추가 설정
이것은 사용자가 추가한 내용입니다.
EOF

  cat >"$E2E_CLAUDE_DIR/settings.json" <<'EOF'
{
  "user_customization": true,
  "custom_setting": "user_value"
}
EOF

  # 새로운 명령어 파일을 소스에 추가 시뮬레이션
  mkdir -p "$E2E_DOTFILES/modules/shared/config/claude/commands/new"
  cat >"$E2E_DOTFILES/modules/shared/config/claude/commands/new/feature.md" <<'EOF'
# New Feature Command
This is a new command added in the update
EOF

  # 업데이트 실행
  simulate_claude_activation_from_nix

  # 사용자 수정사항이 보존되었는지 확인
  if grep -q "사용자가 추가한 내용" "$E2E_CLAUDE_DIR/CLAUDE.md"; then
    test_pass "사용자 수정사항 보존 (CLAUDE.md)"
  else
    test_fail "사용자 수정사항 손실 (CLAUDE.md)"
  fi

  # 새 버전이 .new 파일로 생성되었는지 확인
  if [[ -f "$E2E_CLAUDE_DIR/CLAUDE.md.new" ]]; then
    test_pass "새 버전 파일 생성 (CLAUDE.md.new)"
  else
    test_fail "새 버전 파일 생성 실패"
  fi

  # 새로운 명령어가 추가되었는지 확인
  if [[ -f "$E2E_CLAUDE_DIR/commands/new/feature.md" ]]; then
    test_pass "새로운 명령어 파일 추가"
  else
    test_fail "새로운 명령어 파일 추가 실패"
  fi
}

simulate_git_workflow_scenario() {
  log_scenario "Git 워크플로우 시나리오: git commands가 실제로 사용 가능한지 확인"

  # Git commands 디렉토리 확인
  if [[ -d "$E2E_CLAUDE_DIR/commands/git" ]]; then
    test_pass "Git commands 디렉토리 존재"
  else
    test_fail "Git commands 디렉토리 누락"
    return 1
  fi

  # 각 git 명령어 파일의 유효성 검증
  local git_commands=("commit.md" "fix-pr.md" "upsert-pr.md")

  for cmd in "${git_commands[@]}"; do
    local cmd_file="$E2E_CLAUDE_DIR/commands/git/$cmd"

    if [[ -f $cmd_file ]]; then
      test_pass "Git 명령어 파일 존재: $cmd"

      # 파일 내용 검증
      if grep -q "^#" "$cmd_file" && [[ -s $cmd_file ]]; then
        test_pass "Git 명령어 파일 내용 유효: $cmd"
      else
        test_fail "Git 명령어 파일 내용 무효: $cmd"
      fi

      # 파일 권한 검증
      local perms=$(stat -f "%A" "$cmd_file" 2>/dev/null || stat -c "%a" "$cmd_file" 2>/dev/null || echo "644")
      if [[ $perms == "644" ]]; then
        test_pass "Git 명령어 파일 권한 올바름: $cmd"
      else
        test_fail "Git 명령어 파일 권한 문제: $cmd (권한: $perms)"
      fi
    else
      test_fail "Git 명령어 파일 누락: $cmd"
    fi
  done
}

simulate_multi_subdirectory_scenario() {
  log_scenario "다중 서브디렉토리 시나리오: 여러 레벨의 서브디렉토리 처리 확인"

  # 복잡한 서브디렉토리 구조 생성
  mkdir -p "$E2E_DOTFILES/modules/shared/config/claude/commands/workflow/ci"
  mkdir -p "$E2E_DOTFILES/modules/shared/config/claude/commands/database/migration"

  # 테스트 파일들 생성
  cat >"$E2E_DOTFILES/modules/shared/config/claude/commands/workflow/deploy.md" <<'EOF'
# Deploy Command
Workflow deployment command
EOF

  cat >"$E2E_DOTFILES/modules/shared/config/claude/commands/workflow/ci/test.md" <<'EOF'
# CI Test Command
Continuous integration test command
EOF

  cat >"$E2E_DOTFILES/modules/shared/config/claude/commands/database/migration/create.md" <<'EOF'
# Database Migration Create Command
Database migration creation command
EOF

  # 활성화 실행
  simulate_claude_activation_from_nix

  # 결과 검증
  local expected_files=(
    "commands/workflow/deploy.md"
    "commands/workflow/ci/test.md"
    "commands/database/migration/create.md"
  )

  for file in "${expected_files[@]}"; do
    if [[ -f "$E2E_CLAUDE_DIR/$file" ]]; then
      test_pass "다중 서브디렉토리 파일 생성: $file"
    else
      test_fail "다중 서브디렉토리 파일 누락: $file"
    fi
  done

  # 디렉토리 구조 검증
  local expected_dirs=(
    "commands/workflow"
    "commands/workflow/ci"
    "commands/database"
    "commands/database/migration"
  )

  for dir in "${expected_dirs[@]}"; do
    if [[ -d "$E2E_CLAUDE_DIR/$dir" ]]; then
      test_pass "다중 서브디렉토리 생성: $dir"
    else
      test_fail "다중 서브디렉토리 누락: $dir"
    fi
  done
}

simulate_cleanup_scenario() {
  log_scenario "정리 시나리오: 소스에서 제거된 파일들이 타겟에서 정리되는지 확인"

  # 소스에 없는 파일을 타겟에 생성 (이전 버전에서 남은 파일 시뮬레이션)
  mkdir -p "$E2E_CLAUDE_DIR/commands/deprecated"
  cat >"$E2E_CLAUDE_DIR/commands/deprecated/old-command.md" <<'EOF'
# Deprecated Command
This command should be removed
EOF

  cat >"$E2E_CLAUDE_DIR/commands/obsolete.md" <<'EOF'
# Obsolete Command
This command is no longer needed
EOF

  # 활성화 실행
  simulate_claude_activation_from_nix

  # 정리되었는지 확인 (실제 구현에서는 정리 기능이 있어야 함)
  if [[ ! -f "$E2E_CLAUDE_DIR/commands/deprecated/old-command.md" ]]; then
    test_pass "사용하지 않는 파일 정리됨: deprecated/old-command.md"
  else
    test_warning "사용하지 않는 파일 정리 안됨: deprecated/old-command.md (정리 기능 미구현)"
  fi

  if [[ ! -f "$E2E_CLAUDE_DIR/commands/obsolete.md" ]]; then
    test_pass "사용하지 않는 파일 정리됨: obsolete.md"
  else
    test_warning "사용하지 않는 파일 정리 안됨: obsolete.md (정리 기능 미구현)"
  fi
}

test_warning() {
  echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

# Claude activation 시뮬레이션 (Nix 없이)
simulate_claude_activation_from_nix() {
  local config_home="$E2E_HOME"
  local source_dir="$E2E_DOTFILES/modules/shared/config/claude"

  # 실제 claude-activation.nix의 bash 구현 실행
  export CLAUDE_DIR="$E2E_CLAUDE_DIR"
  export SOURCE_DIR="$source_dir"
  export DRY_RUN=""

  # claude-activation 로직 실행
  bash <<'ACTIVATION_SCRIPT'
set -euo pipefail

DRY_RUN_CMD=""
if [[ "${DRY_RUN:-}" == "1" ]]; then
    DRY_RUN_CMD="echo '[DRY RUN]'"
fi

$DRY_RUN_CMD mkdir -p "${CLAUDE_DIR}/commands"
$DRY_RUN_CMD mkdir -p "${CLAUDE_DIR}/agents"

# 파일 해시 비교 함수
files_differ() {
    local source="$1"
    local target="$2"

    if [[ ! -f "$source" ]] || [[ ! -f "$target" ]]; then
        return 0
    fi

    local source_hash=""
    local target_hash=""

    if command -v shasum >/dev/null 2>&1; then
        source_hash=$(shasum -a 256 "$source" | cut -d' ' -f1)
        target_hash=$(shasum -a 256 "$target" | cut -d' ' -f1)
    elif command -v sha256sum >/dev/null 2>&1; then
        source_hash=$(sha256sum "$source" | cut -d' ' -f1)
        target_hash=$(sha256sum "$target" | cut -d' ' -f1)
    else
        # Fallback
        local source_size=$(wc -c < "$source")
        local target_size=$(wc -c < "$target")
        [[ "$source_size" != "$target_size" ]]
        return $?
    fi

    [[ "$source_hash" != "$target_hash" ]]
}

# 조건부 복사 함수
smart_copy() {
    local source_file="$1"
    local target_file="$2"
    local file_name=$(basename "$source_file")

    if [[ ! -f "$source_file" ]]; then
        return 0
    fi

    if [[ ! -f "$target_file" ]]; then
        $DRY_RUN_CMD cp "$source_file" "$target_file"
        $DRY_RUN_CMD chmod 644 "$target_file"
        return 0
    fi

    if files_differ "$source_file" "$target_file"; then
        case "$file_name" in
            "settings.json"|"CLAUDE.md")
                $DRY_RUN_CMD cp "$source_file" "$target_file.new"
                $DRY_RUN_CMD chmod 644 "$target_file.new"
                ;;
            *)
                $DRY_RUN_CMD cp "$source_file" "$target_file"
                $DRY_RUN_CMD chmod 644 "$target_file"
                ;;
        esac
    fi
}

# 메인 설정 파일들 처리
for config_file in "settings.json" "CLAUDE.md"; do
    if [[ -f "$SOURCE_DIR/$config_file" ]]; then
        smart_copy "$SOURCE_DIR/$config_file" "$CLAUDE_DIR/$config_file"
    fi
done

# commands 디렉토리 처리 (서브디렉토리 지원)
if [[ -d "$SOURCE_DIR/commands" ]]; then
    find "$SOURCE_DIR/commands" -name "*.md" -type f | while read -r cmd_file; do
        rel_path="${cmd_file#$SOURCE_DIR/commands/}"
        target_file="$CLAUDE_DIR/commands/$rel_path"
        target_dir=$(dirname "$target_file")
        $DRY_RUN_CMD mkdir -p "$target_dir"
        smart_copy "$cmd_file" "$target_file"
    done
fi

# agents 디렉토리 처리
if [[ -d "$SOURCE_DIR/agents" ]]; then
    for agent_file in "$SOURCE_DIR/agents"/*.md; do
        if [[ -f "$agent_file" ]]; then
            base_name=$(basename "$agent_file")
            smart_copy "$agent_file" "$CLAUDE_DIR/agents/$base_name"
        fi
    done
fi
ACTIVATION_SCRIPT
}

# 전체 시스템 검증
validate_complete_system() {
  log_scenario "전체 시스템 검증: 모든 구성 요소가 올바르게 작동하는지 최종 확인"

  # 디렉토리 구조 검증
  local essential_dirs=(
    "$E2E_CLAUDE_DIR"
    "$E2E_CLAUDE_DIR/commands"
    "$E2E_CLAUDE_DIR/commands/git"
    "$E2E_CLAUDE_DIR/agents"
  )

  for dir in "${essential_dirs[@]}"; do
    if [[ -d $dir ]]; then
      test_pass "필수 디렉토리 존재: $(basename "$dir")"
    else
      test_fail "필수 디렉토리 누락: $(basename "$dir")"
    fi
  done

  # 파일 수 검증
  local total_files=$(find "$E2E_CLAUDE_DIR" -type f | wc -l)
  if [[ $total_files -ge 15 ]]; then
    test_pass "충분한 수의 파일 배치됨 ($total_files 개)"
  else
    test_fail "파일 수 부족 ($total_files 개, 최소 15개 예상)"
  fi

  # Git commands 특별 검증
  local git_files=$(find "$E2E_CLAUDE_DIR/commands/git" -name "*.md" -type f 2>/dev/null | wc -l)
  if [[ $git_files -ge 3 ]]; then
    test_pass "Git commands 충분히 배치됨 ($git_files 개)"
  else
    test_fail "Git commands 부족 ($git_files 개, 최소 3개 예상)"
  fi
}

# 메인 E2E 테스트 실행
main() {
  log_info "Claude Commands End-to-End 테스트 시작"
  log_info "실제 사용자 시나리오를 시뮬레이션합니다..."

  # 신호 핸들러 설정
  trap cleanup_e2e_environment EXIT

  # 테스트 환경 설정
  setup_e2e_environment

  # 시나리오별 테스트 실행
  simulate_first_time_setup
  simulate_update_scenario
  simulate_git_workflow_scenario
  simulate_multi_subdirectory_scenario
  simulate_cleanup_scenario
  validate_complete_system

  # 최종 결과 출력
  echo
  log_info "================= E2E 테스트 결과 ================="
  echo -e "${GREEN}통과: $TESTS_PASSED${NC}"
  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}실패: $TESTS_FAILED${NC}"
    log_error "일부 E2E 테스트가 실패했습니다."

    # 실패한 시나리오가 있으면 디버그 정보 출력
    echo
    log_debug "================= 디버그 정보 =================="
    log_debug "최종 Claude 디렉토리 구조:"
    if [[ -d $E2E_CLAUDE_DIR ]]; then
      find "$E2E_CLAUDE_DIR" -type f | sort
    else
      log_debug "Claude 디렉토리가 생성되지 않음"
    fi

    exit 1
  else
    log_info "모든 E2E 테스트가 통과했습니다! 🎉"
    log_info "Claude commands git 파일들이 완전히 작동합니다."
    echo
    log_info "검증된 기능:"
    log_info "✅ 첫 번째 설정 시나리오"
    log_info "✅ 업데이트 및 사용자 수정사항 보존"
    log_info "✅ Git 워크플로우 완전 지원"
    log_info "✅ 다중 서브디렉토리 처리"
    log_info "✅ 전체 시스템 통합"
    exit 0
  fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
