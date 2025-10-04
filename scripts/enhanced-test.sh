#!/usr/bin/env bash
# ABOUTME: 향상된 테스트 러너 - 상세한 리포팅과 성능 메트릭 제공
# ABOUTME: 테스트 결과를 더 명확하게 보여주고 개발자 경험을 개선

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 색상 정의
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# 테스트 결과 저장
declare -A test_results
declare -A test_times

# 사용법 출력
usage() {
  echo "사용법: $0 [옵션] [테스트_카테고리]"
  echo ""
  echo "옵션:"
  echo "  -v, --verbose    상세 출력 모드"
  echo "  -q, --quiet      경고 메시지 숨기기"
  echo "  -p, --parallel   병렬 실행 (가능한 경우)"
  echo "  -h, --help       도움말 표시"
  echo ""
  echo "테스트 카테고리:"
  echo "  all       모든 테스트 (기본값)"
  echo "  quick     빠른 테스트 (smoke + core)"
  echo "  core      핵심 기능 테스트"
  echo "  workflow  E2E 워크플로우 테스트"
  echo "  perf      성능 테스트"
  echo "  smoke     빠른 검증 테스트"
}

# 옵션 파싱
VERBOSE=false
QUIET=false
PARALLEL=false
CATEGORY="quick"

while [[ $# -gt 0 ]]; do
  case $1 in
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
  -q | --quiet)
    QUIET=true
    shift
    ;;
  -p | --parallel)
    PARALLEL=true
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  all | quick | core | workflow | perf | smoke)
    CATEGORY="$1"
    shift
    ;;
  *)
    echo "알 수 없는 옵션: $1"
    usage
    exit 1
    ;;
  esac
done

# 로그 함수들
log_header() {
  echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC} $(printf "%-40s" "$1") ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
}

log_info() {
  echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
  echo -e "${GREEN}✅${NC} $1"
}

log_error() {
  echo -e "${RED}❌${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}⚠${NC} $1"
}

# 테스트 실행 함수
run_test() {
  local test_name="$1"
  local test_cmd="$2"
  local start_time end_time duration

  if [[ $VERBOSE == "true" ]]; then
    echo -e "${PURPLE}▶${NC} $test_name 테스트 시작..."
  fi

  start_time=$(date +%s.%N)

  local output
  if [[ $QUIET == "true" ]]; then
    if output=$(eval "$test_cmd" 2>&1 | grep -v "warning:"); then
      test_results["$test_name"]="PASS"
    else
      test_results["$test_name"]="FAIL"
    fi
  else
    if output=$(eval "$test_cmd" 2>&1); then
      test_results["$test_name"]="PASS"
    else
      test_results["$test_name"]="FAIL"
    fi
  fi

  end_time=$(date +%s.%N)
  duration=$(echo "$end_time - $start_time" | bc)
  test_times["$test_name"]="$duration"

  if [[ $VERBOSE == "true" && ${test_results[$test_name]} == "FAIL" ]]; then
    echo -e "${RED}테스트 실패 출력:${NC}"
    echo "$output" | tail -20
  fi
}

# 병렬 테스트 실행
run_parallel_tests() {
  local -a pids=()
  local temp_dir=$(mktemp -d)

  log_info "병렬 테스트 실행 중..."

  for test in "$@"; do
    {
      case $test in
      "smoke")
        run_test "smoke" "nix run --impure $PROJECT_ROOT#test-smoke"
        ;;
      "core")
        run_test "core" "nix run --impure $PROJECT_ROOT#test-core"
        ;;
      "workflow")
        run_test "workflow" "nix run --impure $PROJECT_ROOT#test-workflow"
        ;;
      "perf")
        run_test "perf" "nix run --impure $PROJECT_ROOT#test-perf"
        ;;
      esac

      # 결과를 임시 파일에 저장
      echo "${test_results[$test]}" >"$temp_dir/${test}_result"
      echo "${test_times[$test]}" >"$temp_dir/${test}_time"
    } &
    pids+=($!)
  done

  # 모든 테스트 완료 대기
  for pid in "${pids[@]}"; do
    wait "$pid"
  done

  # 결과 복원
  for test in "$@"; do
    if [[ -f "$temp_dir/${test}_result" ]]; then
      test_results["$test"]=$(cat "$temp_dir/${test}_result")
      test_times["$test"]=$(cat "$temp_dir/${test}_time")
    fi
  done

  rm -rf "$temp_dir"
}

# 순차 테스트 실행
run_sequential_tests() {
  for test in "$@"; do
    case $test in
    "smoke")
      run_test "smoke" "nix run --impure $PROJECT_ROOT#test-smoke"
      ;;
    "core")
      run_test "core" "nix run --impure $PROJECT_ROOT#test-core"
      ;;
    "workflow")
      run_test "workflow" "nix run --impure $PROJECT_ROOT#test-workflow"
      ;;
    "perf")
      run_test "perf" "nix run --impure $PROJECT_ROOT#test-perf"
      ;;
    esac
  done
}

# 테스트 결과 리포트
generate_report() {
  local total_tests=0
  local passed_tests=0
  local failed_tests=0
  local total_time=0

  echo ""
  log_header "테스트 결과 리포트"
  echo ""

  # 개별 테스트 결과
  for test in "${!test_results[@]}"; do
    local result="${test_results[$test]}"
    local time="${test_times[$test]}"
    total_time=$(echo "$total_time + $time" | bc)
    total_tests=$((total_tests + 1))

    if [[ $result == "PASS" ]]; then
      log_success "$(printf "%-12s" "$test"): 통과 (${time}초)"
      passed_tests=$((passed_tests + 1))
    else
      log_error "$(printf "%-12s" "$test"): 실패 (${time}초)"
      failed_tests=$((failed_tests + 1))
    fi
  done

  echo ""
  echo -e "${CYAN}════════════════════════════════════════════${NC}"
  echo -e "${BLUE}총 테스트:${NC} $total_tests"
  echo -e "${GREEN}통과:${NC} $passed_tests"
  echo -e "${RED}실패:${NC} $failed_tests"
  echo -e "${PURPLE}총 소요시간:${NC} ${total_time}초"
  echo -e "${CYAN}════════════════════════════════════════════${NC}"

  # 성공률 계산
  if [[ $total_tests -gt 0 ]]; then
    local success_rate=$(echo "scale=1; $passed_tests * 100 / $total_tests" | bc)
    echo -e "${YELLOW}성공률:${NC} ${success_rate}%"
  fi

  # 추천 사항
  if [[ $failed_tests -gt 0 ]]; then
    echo ""
    log_warning "실패한 테스트가 있습니다. 다음을 시도해보세요:"
    echo "  - make test-core  # 핵심 테스트만 실행"
    echo "  - $0 --verbose    # 상세 출력으로 재실행"
    return 1
  else
    echo ""
    log_success "모든 테스트가 성공적으로 통과했습니다! 🎉"
    return 0
  fi
}

# 메인 실행 로직
main() {
  log_header "Enhanced Test Runner v2.0"

  # USER 변수 확인
  if [[ -z ${USER:-} ]]; then
    export USER=$(whoami)
    log_warning "USER 변수가 설정되지 않아 자동으로 설정했습니다: $USER"
  fi

  log_info "테스트 카테고리: $CATEGORY"
  log_info "병렬 실행: $([ "$PARALLEL" == "true" ] && echo "활성화" || echo "비활성화")"
  log_info "조용한 모드: $([ "$QUIET" == "true" ] && echo "활성화" || echo "비활성화")"

  echo ""

  # 테스트 목록 결정
  local tests=()
  case $CATEGORY in
  "quick")
    tests=("smoke" "core")
    ;;
  "all")
    tests=("smoke" "core" "workflow" "perf")
    ;;
  "core")
    tests=("core")
    ;;
  "workflow")
    tests=("workflow")
    ;;
  "perf")
    tests=("perf")
    ;;
  "smoke")
    tests=("smoke")
    ;;
  esac

  # 시작 시간 기록
  local start_time=$(date +%s.%N)

  # 테스트 실행
  if [[ $PARALLEL == "true" && ${#tests[@]} -gt 1 ]]; then
    run_parallel_tests "${tests[@]}"
  else
    run_sequential_tests "${tests[@]}"
  fi

  # 총 실행 시간 계산
  local end_time=$(date +%s.%N)
  local execution_time=$(echo "$end_time - $start_time" | bc)

  echo ""
  log_info "전체 실행 시간: ${execution_time}초"

  # 결과 리포트 생성
  generate_report
}

# bc 명령어 확인
if ! command -v bc &>/dev/null; then
  log_warning "bc 명령어가 없어 시간 계산을 건너뜁니다"
  # fallback to integer seconds
  alias bc='echo "scale=1; 0" | cat'
fi

# 스크립트 실행
main "$@"
