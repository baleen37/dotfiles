#!/usr/bin/env bash
# test-claude-platform-compatibility.sh - Claude Code 심볼릭 링크 플랫폼별 호환성 테스트
# ABOUTME: macOS vs Linux 차이점과 Nix store 경로 호환성을 종합적으로 테스트

set -euo pipefail

# 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 전역 변수
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="/tmp/claude-platform-test-$$"
VERBOSE=${VERBOSE:-false}
DRY_RUN=${DRY_RUN:-false}

# 테스트 결과 추적
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 플랫폼 정보
PLATFORM=$(uname)
ARCH=$(uname -m)
KERNEL_VERSION=$(uname -r)

# 로그 함수들
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
  if [[ $VERBOSE == "true" ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $1"
  fi
}

log_test() {
  echo -e "${CYAN}[TEST]${NC} $1"
}

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
  ((PASSED_TESTS++))
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((FAILED_TESTS++))
}

log_skip() {
  echo -e "${YELLOW}[SKIP]${NC} $1"
  ((SKIPPED_TESTS++))
}

# 테스트 환경 초기화
setup_test_environment() {
  log_info "=== Claude Code 플랫폼 호환성 테스트 시작 ==="
  log_info "플랫폼: $PLATFORM ($ARCH)"
  log_info "커널: $KERNEL_VERSION"
  log_info "테스트 디렉토리: $TEST_DIR"

  # 임시 디렉토리 생성
  mkdir -p "$TEST_DIR"/{source,target,nix-store-mock}

  # 테스트용 파일들 생성
  echo "# Test Configuration" >"$TEST_DIR/source/CLAUDE.md"
  echo '{"test": "config"}' >"$TEST_DIR/source/settings.json"
  mkdir -p "$TEST_DIR/source"/{commands,agents}
  echo "# Test Command" >"$TEST_DIR/source/commands/test.md"
  echo "# Test Agent" >"$TEST_DIR/source/agents/test.md"

  # Nix store 형태의 경로 생성 (실제 Nix store는 아니지만 경로 패턴 테스트용)
  local nix_store_path="$TEST_DIR/nix-store-mock/store/hash-claude-config"
  mkdir -p "$nix_store_path"/{commands,agents}
  cp -r "$TEST_DIR/source"/* "$nix_store_path/"

  log_info "테스트 환경 준비 완료"
}

# 테스트 환경 정리
cleanup_test_environment() {
  if [[ $DRY_RUN != "true" ]]; then
    rm -rf "$TEST_DIR"
    log_debug "테스트 환경 정리 완료"
  fi
}

# readlink 명령어 플랫폼별 동작 차이 테스트
test_readlink_platform_differences() {
  log_test "readlink 명령어 플랫폼별 동작 차이 테스트"
  ((TOTAL_TESTS++))

  local test_target="$TEST_DIR/source/CLAUDE.md"
  local test_link="$TEST_DIR/target/readlink_test"

  # 심볼릭 링크 생성
  ln -sf "$test_target" "$test_link"

  local has_readlink=false
  local is_gnu_readlink=false
  local readlink_output=""
  local realpath_output=""

  # readlink 존재 여부 확인
  if command -v readlink >/dev/null 2>&1; then
    has_readlink=true
    readlink_output=$(readlink "$test_link" 2>/dev/null || echo "")

    # GNU readlink 확인 (Linux)
    if readlink --version 2>/dev/null | grep -q "GNU"; then
      is_gnu_readlink=true
    fi
  fi

  # realpath 동작 확인
  if command -v realpath >/dev/null 2>&1; then
    realpath_output=$(realpath "$test_link" 2>/dev/null || echo "")
  fi

  log_debug "readlink 존재: $has_readlink"
  log_debug "GNU readlink: $is_gnu_readlink"
  log_debug "readlink 출력: $readlink_output"
  log_debug "realpath 출력: $realpath_output"

  case "$PLATFORM" in
  "Darwin")
    if [[ $has_readlink == "true" && -n $readlink_output && $is_gnu_readlink == "false" ]]; then
      log_pass "macOS BSD readlink 동작 정상"
    else
      log_fail "macOS에서 BSD readlink 예상됐으나 다른 결과: GNU=$is_gnu_readlink"
      return 1
    fi
    ;;
  "Linux")
    if [[ $has_readlink == "true" && -n $readlink_output ]]; then
      if [[ $is_gnu_readlink == "true" ]]; then
        log_pass "Linux GNU readlink 동작 정상"
      else
        log_warning "Linux에서 GNU가 아닌 readlink 감지됨 (동작 가능)"
        log_pass "Linux readlink 동작 확인됨"
      fi
    else
      log_fail "Linux에서 readlink 동작 실패"
      return 1
    fi
    ;;
  *)
    log_skip "알 수 없는 플랫폼에서 readlink 테스트 스킵: $PLATFORM"
    ;;
  esac

  return 0
}

# 파일 시스템 권한 처리 차이 테스트
test_filesystem_permission_differences() {
  log_test "파일 시스템 권한 처리 차이 테스트"
  ((TOTAL_TESTS++))

  local test_file="$TEST_DIR/permission_test.txt"
  echo "test content" >"$test_file"
  chmod 644 "$test_file"

  local stat_format=""
  local permission=""

  case "$PLATFORM" in
  "Darwin")
    # macOS의 BSD stat
    if permission=$(stat -f "%A" "$test_file" 2>/dev/null); then
      log_debug "macOS stat 형식: $permission"
      if [[ $permission == "644" ]]; then
        log_pass "macOS BSD stat 권한 읽기 정상"
      else
        log_fail "macOS에서 예상 권한(644)과 다름: $permission"
        return 1
      fi
    else
      log_fail "macOS에서 stat 명령어 실행 실패"
      return 1
    fi
    ;;
  "Linux")
    # Linux의 GNU stat
    if permission=$(stat -c "%a" "$test_file" 2>/dev/null); then
      log_debug "Linux stat 형식: $permission"
      if [[ $permission == "644" ]]; then
        log_pass "Linux GNU stat 권한 읽기 정상"
      else
        log_fail "Linux에서 예상 권한(644)과 다름: $permission"
        return 1
      fi
    else
      log_fail "Linux에서 stat 명령어 실행 실패"
      return 1
    fi
    ;;
  *)
    log_skip "알 수 없는 플랫폼에서 권한 테스트 스킵: $PLATFORM"
    ;;
  esac

  return 0
}

# 심볼릭 링크 생성/해석 동작 차이 테스트
test_symlink_behavior_differences() {
  log_test "심볼릭 링크 생성/해석 동작 차이 테스트"
  ((TOTAL_TESTS++))

  local source_file="$TEST_DIR/source/test_behavior.md"
  local link_file="$TEST_DIR/target/behavior_link"
  local relative_source="../source/test_behavior.md"

  echo "# Test Content" >"$source_file"

  # 절대 경로 심볼릭 링크 테스트
  ln -sf "$source_file" "$link_file"
  if [[ -L $link_file && -e $link_file ]]; then
    log_debug "절대 경로 심볼릭 링크 생성 성공"
  else
    log_fail "절대 경로 심볼릭 링크 생성 실패"
    return 1
  fi

  # 상대 경로 심볼릭 링크 테스트
  rm -f "$link_file"
  cd "$TEST_DIR/target"
  ln -sf "$relative_source" "behavior_link"
  cd - >/dev/null

  if [[ -L $link_file && -e $link_file ]]; then
    log_debug "상대 경로 심볼릭 링크 생성 성공"
  else
    log_fail "상대 경로 심볼릭 링크 생성 실패"
    return 1
  fi

  # 깨진 링크 테스트
  local broken_link="$TEST_DIR/target/broken_link"
  ln -sf "/nonexistent/path" "$broken_link"
  if [[ -L $broken_link && ! -e $broken_link ]]; then
    log_debug "깨진 심볼릭 링크 감지 성공"
    log_pass "심볼릭 링크 생성/해석 동작 정상"
  else
    log_fail "깨진 심볼릭 링크 감지 실패"
    return 1
  fi

  return 0
}

# PATH 환경변수 구조 차이 테스트
test_path_structure_differences() {
  log_test "PATH 환경변수 구조 차이 테스트"
  ((TOTAL_TESTS++))

  local path_separator=":"
  local path_entries=()

  # PATH를 배열로 분할
  IFS="$path_separator" read -ra path_entries <<<"$PATH"

  log_debug "PATH 엔트리 수: ${#path_entries[@]}"

  local has_usr_bin=false
  local has_usr_local_bin=false
  local has_nix_profile=false
  local has_homebrew=false

  for entry in "${path_entries[@]}"; do
    case "$entry" in
    "/usr/bin") has_usr_bin=true ;;
    "/usr/local/bin") has_usr_local_bin=true ;;
    *"/nix/profile"*) has_nix_profile=true ;;
    *"/homebrew"* | *"/opt/homebrew"*) has_homebrew=true ;;
    esac
  done

  log_debug "PATH 분석 결과:"
  log_debug "  /usr/bin 존재: $has_usr_bin"
  log_debug "  /usr/local/bin 존재: $has_usr_local_bin"
  log_debug "  Nix profile 존재: $has_nix_profile"
  log_debug "  Homebrew 존재: $has_homebrew"

  case "$PLATFORM" in
  "Darwin")
    if [[ $has_usr_bin == "true" && $has_usr_local_bin == "true" ]]; then
      log_pass "macOS 표준 PATH 구조 확인"
      if [[ $has_homebrew == "true" ]]; then
        log_debug "Homebrew PATH도 감지됨"
      fi
    else
      log_fail "macOS에서 예상되는 PATH 구조가 아님"
      return 1
    fi
    ;;
  "Linux")
    if [[ $has_usr_bin == "true" ]]; then
      log_pass "Linux 표준 PATH 구조 확인"
      if [[ $has_nix_profile == "true" ]]; then
        log_debug "Nix profile PATH도 감지됨"
      fi
    else
      log_fail "Linux에서 예상되는 PATH 구조가 아님"
      return 1
    fi
    ;;
  *)
    log_skip "알 수 없는 플랫폼에서 PATH 테스트 스킵: $PLATFORM"
    ;;
  esac

  return 0
}

# Nix store vs 로컬 경로 테스트 (self 매개변수 유무)
test_nix_store_vs_local_paths() {
  log_test "Nix store vs 로컬 경로 테스트 (self 매개변수 시뮬레이션)"
  ((TOTAL_TESTS++))

  local nix_store_path="$TEST_DIR/nix-store-mock/store/hash-claude-config"
  local local_path="$TEST_DIR/source"
  local target_dir="$TEST_DIR/target-nix"

  mkdir -p "$target_dir"

  # 시나리오 1: Nix store 경로에서 링크 생성 (self 매개변수 있음을 시뮬레이션)
  local nix_link="$target_dir/nix_commands"
  ln -sf "$nix_store_path/commands" "$nix_link"

  if [[ -L $nix_link && -d $nix_link ]]; then
    local nix_target=$(readlink "$nix_link")
    local nix_resolved=$(realpath "$nix_link" 2>/dev/null || echo "")
    log_debug "Nix store 링크 타겟: $nix_target"
    log_debug "Nix store 링크 해석: $nix_resolved"

    # realpath로 해석된 경로와 원본 경로 비교 (macOS의 /private/tmp 처리)
    local expected_resolved=$(realpath "$nix_store_path/commands" 2>/dev/null || echo "$nix_store_path/commands")
    if [[ $nix_resolved == "$expected_resolved" ]]; then
      log_debug "Nix store 경로 링크 정상"
    else
      log_fail "Nix store 경로 링크 해석 실패: expected=$expected_resolved, actual=$nix_resolved"
      return 1
    fi
  else
    log_fail "Nix store 경로 링크 생성 실패"
    return 1
  fi

  # 시나리오 2: 로컬 경로에서 링크 생성 (self 매개변수 없음을 시뮬레이션)
  local local_link="$target_dir/local_commands"
  ln -sf "$local_path/commands" "$local_link"

  if [[ -L $local_link && -d $local_link ]]; then
    local local_target=$(readlink "$local_link")
    local local_resolved=$(realpath "$local_link" 2>/dev/null || echo "")
    log_debug "로컬 경로 링크 타겟: $local_target"
    log_debug "로컬 경로 링크 해석: $local_resolved"

    # realpath로 해석된 경로와 원본 경로 비교 (macOS의 /private/tmp 처리)
    local expected_local_resolved=$(realpath "$local_path/commands" 2>/dev/null || echo "$local_path/commands")
    if [[ $local_resolved == "$expected_local_resolved" ]]; then
      log_debug "로컬 경로 링크 정상"
    else
      log_fail "로컬 경로 링크 해석 실패: expected=$expected_local_resolved, actual=$local_resolved"
      return 1
    fi
  else
    log_fail "로컬 경로 링크 생성 실패"
    return 1
  fi

  # 경로 패턴 분석
  local is_nix_store_pattern=false
  if [[ $nix_target =~ /nix/store/ || $nix_target =~ /store/ ]]; then
    is_nix_store_pattern=true
  fi

  log_debug "Nix store 패턴 감지: $is_nix_store_pattern"

  if [[ $is_nix_store_pattern == "true" ]]; then
    log_pass "Nix store vs 로컬 경로 구분 성공"
  else
    log_fail "Nix store 패턴 감지 실패"
    return 1
  fi

  return 0
}

# 절대경로/상대경로 해석 차이 테스트
test_absolute_relative_path_resolution() {
  log_test "절대경로/상대경로 해석 차이 테스트"
  ((TOTAL_TESTS++))

  local base_dir="$TEST_DIR/path-resolution"
  local source_dir="$base_dir/source"
  local target_dir="$base_dir/target"

  mkdir -p "$source_dir" "$target_dir"
  echo "test file" >"$source_dir/test.txt"

  # 절대경로 링크
  local abs_link="$target_dir/abs_link.txt"
  ln -sf "$source_dir/test.txt" "$abs_link"

  # 상대경로 링크
  local rel_link="$target_dir/rel_link.txt"
  cd "$target_dir"
  ln -sf "../source/test.txt" "rel_link.txt"
  cd - >/dev/null

  # 해석 테스트
  local abs_target=$(readlink "$abs_link")
  local abs_resolved=$(realpath "$abs_link" 2>/dev/null || echo "")
  local rel_target=$(readlink "$rel_link")
  local rel_resolved=$(realpath "$rel_link" 2>/dev/null || echo "")

  log_debug "절대경로 링크 타겟: $abs_target"
  log_debug "절대경로 링크 해석: $abs_resolved"
  log_debug "상대경로 링크 타겟: $rel_target"
  log_debug "상대경로 링크 해석: $rel_resolved"

  # 두 해석된 경로가 같은 파일을 가리키는지 확인
  if [[ $abs_resolved == "$rel_resolved" && -f $abs_resolved ]]; then
    log_pass "절대경로/상대경로 해석 일치 확인"
  else
    log_fail "절대경로/상대경로 해석 불일치: abs=$abs_resolved, rel=$rel_resolved"
    return 1
  fi

  # 경로 타입 구분 테스트
  local is_abs_path=false
  local is_rel_path=false

  if [[ $abs_target =~ ^/ ]]; then
    is_abs_path=true
  fi

  if [[ $rel_target =~ ^\.\./ ]]; then
    is_rel_path=true
  fi

  log_debug "절대경로 패턴 감지: $is_abs_path"
  log_debug "상대경로 패턴 감지: $is_rel_path"

  if [[ $is_abs_path == "true" && $is_rel_path == "true" ]]; then
    log_pass "경로 타입 구분 성공"
  else
    log_fail "경로 타입 구분 실패"
    return 1
  fi

  return 0
}

# 크로스 플랫폼 호환성 검증 테스트
test_cross_platform_compatibility() {
  log_test "크로스 플랫폼 호환성 검증 테스트"
  ((TOTAL_TESTS++))

  local compat_issues=0

  # 필수 명령어 존재 확인
  local required_commands=("readlink" "realpath" "stat" "ln" "find")
  for cmd in "${required_commands[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      log_error "필수 명령어 없음: $cmd"
      ((compat_issues++))
    fi
  done

  # 플랫폼별 특수 명령어 확인
  case "$PLATFORM" in
  "Darwin")
    # macOS 특별 확인 사항들
    if ! command -v stat >/dev/null 2>&1 || ! stat -f "%A" "$HOME" >/dev/null 2>&1; then
      log_error "macOS BSD stat 동작 불가"
      ((compat_issues++))
    fi
    ;;
  "Linux")
    # Linux 특별 확인 사항들
    if ! command -v stat >/dev/null 2>&1 || ! stat -c "%a" "$HOME" >/dev/null 2>&1; then
      log_error "Linux GNU stat 동작 불가"
      ((compat_issues++))
    fi
    ;;
  esac

  # 파일 시스템 기능 테스트
  local test_link="$TEST_DIR/compat_test_link"
  local test_file="$TEST_DIR/compat_test_file"
  echo "test" >"$test_file"

  if ln -sf "$test_file" "$test_link" 2>/dev/null; then
    if [[ -L $test_link && -e $test_link ]]; then
      log_debug "심볼릭 링크 기본 기능 정상"
    else
      log_error "심볼릭 링크 생성 후 접근 불가"
      ((compat_issues++))
    fi
  else
    log_error "심볼릭 링크 생성 불가"
    ((compat_issues++))
  fi

  # 문자 인코딩 테스트 (한글 파일명)
  local korean_file="$TEST_DIR/한글파일.txt"
  if echo "한글 내용" >"$korean_file" 2>/dev/null; then
    if [[ -f $korean_file ]]; then
      log_debug "한글 파일명 지원 정상"
    else
      log_warning "한글 파일명 생성 후 접근 문제"
      ((compat_issues++))
    fi
  else
    log_warning "한글 파일명 생성 불가 (일부 시스템에서 정상)"
  fi

  if [[ $compat_issues -eq 0 ]]; then
    log_pass "크로스 플랫폼 호환성 검증 통과"
  else
    log_fail "크로스 플랫폼 호환성 문제 발견: $compat_issues개"
    return 1
  fi

  return 0
}

# 실제 환경에서의 플랫폼 감지 테스트
test_real_environment_platform_detection() {
  log_test "실제 환경에서의 플랫폼 감지 테스트"
  ((TOTAL_TESTS++))

  # 플랫폼 감지 로직 재현 (validate-claude-symlinks.sh 참고)
  local detected_platform=$(uname)
  local detected_arch=$(uname -m)
  local detected_kernel=$(uname -r)

  log_debug "감지된 정보:"
  log_debug "  플랫폼: $detected_platform"
  log_debug "  아키텍처: $detected_arch"
  log_debug "  커널: $detected_kernel"

  # 실제 Claude Code 설정 디렉토리 확인 (있다면)
  local claude_dir="${HOME}/.claude"
  local has_real_claude_config=false

  if [[ -d $claude_dir ]]; then
    has_real_claude_config=true
    log_debug "실제 Claude 설정 디렉토리 존재: $claude_dir"

    # 실제 심볼릭 링크 확인
    local real_symlinks=()
    while IFS= read -r -d '' link; do
      real_symlinks+=("$(basename "$link")")
    done < <(find "$claude_dir" -type l -print0 2>/dev/null)

    log_debug "실제 심볼릭 링크들: ${real_symlinks[*]}"
  else
    log_debug "실제 Claude 설정 디렉토리 없음 (정상)"
  fi

  # Nix 환경 확인
  local has_nix=false
  local nix_version=""

  if command -v nix >/dev/null 2>&1; then
    has_nix=true
    nix_version=$(nix --version 2>/dev/null | head -n1 || echo "unknown")
    log_debug "Nix 설치됨: $nix_version"
  fi

  # dotfiles 프로젝트 구조 확인
  local has_dotfiles_structure=false
  local source_claude_dir="$PROJECT_ROOT/modules/shared/config/claude"

  if [[ -d $source_claude_dir ]]; then
    has_dotfiles_structure=true
    log_debug "Dotfiles Claude 설정 소스 존재: $source_claude_dir"
  fi

  # 종합 판단
  local detection_success=true

  # 기본 플랫폼 감지 확인
  case "$detected_platform" in
  "Darwin" | "Linux")
    log_debug "지원되는 플랫폼 감지됨"
    ;;
  *)
    log_warning "알 수 없는 플랫폼이지만 테스트 계속"
    ;;
  esac

  # 환경 적합성 검증
  if [[ $has_dotfiles_structure == "true" ]]; then
    log_debug "Dotfiles 프로젝트 구조 적합"
  else
    log_warning "Dotfiles 프로젝트 구조 불완전"
    detection_success=false
  fi

  if [[ $detection_success == "true" ]]; then
    log_pass "실제 환경 플랫폼 감지 성공"
  else
    log_fail "실제 환경 플랫폼 감지 문제"
    return 1
  fi

  return 0
}

# 메인 테스트 실행
run_all_tests() {
  local failed_tests=0

  # 개별 테스트 함수들
  local test_functions=(
    "test_readlink_platform_differences"
    "test_filesystem_permission_differences"
    "test_symlink_behavior_differences"
    "test_path_structure_differences"
    "test_nix_store_vs_local_paths"
    "test_absolute_relative_path_resolution"
    "test_cross_platform_compatibility"
    "test_real_environment_platform_detection"
  )

  for test_func in "${test_functions[@]}"; do
    echo -e "\n${BLUE}===================================================${NC}"
    if ! "$test_func"; then
      ((failed_tests++))
    fi
    echo -e "${BLUE}===================================================${NC}"
  done

  return $failed_tests
}

# 종합 보고서 생성
generate_test_report() {
  local failed_count=$1

  echo -e "\n${CYAN}============ Claude Code 플랫폼 호환성 테스트 결과 ============${NC}"
  echo -e "플랫폼: ${BLUE}$PLATFORM ($ARCH)${NC}"
  echo -e "커널: ${BLUE}$KERNEL_VERSION${NC}"
  echo -e ""
  echo -e "총 테스트: ${BLUE}$TOTAL_TESTS${NC}"
  echo -e "통과: ${GREEN}$PASSED_TESTS${NC}"
  echo -e "실패: ${RED}$FAILED_TESTS${NC}"
  echo -e "스킵: ${YELLOW}$SKIPPED_TESTS${NC}"

  local success_rate=0
  if [[ $TOTAL_TESTS -gt 0 ]]; then
    success_rate=$(((PASSED_TESTS + SKIPPED_TESTS) * 100 / TOTAL_TESTS))
  fi

  echo -e "성공률: ${GREEN}${success_rate}%${NC}"
  echo -e "${CYAN}==============================================================${NC}\n"

  if [[ $failed_count -eq 0 ]]; then
    log_info "🎉 모든 플랫폼 호환성 테스트가 통과했습니다!"
  else
    log_error "❌ $failed_count개 테스트 그룹에서 실패가 발생했습니다."
    log_info "상세한 로그를 확인하여 플랫폼별 차이점을 파악하세요."
  fi
}

# 사용법 출력
show_usage() {
  cat <<EOF
사용법: $0 [옵션]

Claude Code 심볼릭 링크 플랫폼별 호환성 종합 테스트

옵션:
  -v, --verbose     상세한 로그 출력
  -d, --dry-run     실제 파일 생성/삭제 없이 테스트
  -h, --help        이 도움말 출력

환경 변수:
  VERBOSE=true      상세한 로그 출력 활성화
  DRY_RUN=true      드라이런 모드 활성화

테스트 항목:
  - readlink 명령어 플랫폼별 동작 차이 (GNU vs BSD)
  - 파일 시스템 권한 처리 차이 (stat 명령어)
  - 심볼릭 링크 생성/해석 동작 차이
  - PATH 환경변수 구조 차이
  - Nix store vs 로컬 경로 처리 (self 매개변수 시뮬레이션)
  - 절대경로/상대경로 해석 차이
  - 크로스 플랫폼 호환성 검증
  - 실제 환경에서의 플랫폼 감지

EOF
}

# 명령행 인자 처리
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    -d | --dry-run)
      DRY_RUN=true
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

  # 테스트 환경 설정
  setup_test_environment

  # 종료 시 정리 함수 등록
  trap cleanup_test_environment EXIT

  # 모든 테스트 실행
  local failed_count=0
  if ! run_all_tests; then
    failed_count=$?
  fi

  # 보고서 생성
  generate_test_report $failed_count

  # 종료 코드 결정
  if [[ $failed_count -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  main "$@"
fi
