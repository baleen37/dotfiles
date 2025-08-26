#!/usr/bin/env bash
# ABOUTME: 통합 테스트 러너 - 일관된 CLI와 병렬 처리 지원
# ABOUTME: 모든 테스트를 체계적으로 실행하고 결과를 종합하는 중앙 집중식 러너

set -euo pipefail

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 테스트 라이브러리들 로드
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/test-framework.sh" 

# 러너 설정
TEST_RUNNER_VERSION="2.0.0"
RUNNER_NAME="Dotfiles Test Runner"

# 기본 설정
DEFAULT_PARALLEL_JOBS=4
DEFAULT_TIMEOUT=60
DEFAULT_VERBOSITY="info"

# 런타임 설정
PARALLEL_MODE=${PARALLEL_MODE:-false}
PARALLEL_JOBS=${PARALLEL_JOBS:-$DEFAULT_PARALLEL_JOBS}
TEST_TIMEOUT=${TEST_TIMEOUT:-$DEFAULT_TIMEOUT}
VERBOSE_MODE=${VERBOSE_MODE:-false}
DRY_RUN=${DRY_RUN:-false}
FAIL_FAST=${FAIL_FAST:-false}
OUTPUT_FORMAT=${OUTPUT_FORMAT:-"standard"}

# 테스트 카테고리 정의
declare -A TEST_CATEGORIES=(
    ["core"]="unit/test-platform-system.sh unit/test-user-resolution.sh unit/test-error-system.sh"
    ["claude"]="unit/test-claude-activation.sh integration/test-claude-activation-integration.sh unit/test-claude-symlink-priority.sh"
    ["workflow"]="e2e/test-claude-activation-e2e.sh e2e/test-claude-commands-end-to-end.sh"
    ["integration"]="integration/test-build-switch-claude-integration.sh integration/test-claude-platform-compatibility.sh integration/test-claude-error-recovery.sh integration/test-home-manager-app-links.sh"
    ["performance"]="performance/test-performance-monitor.sh"
    ["nix-apps"]="unit/test-nix-app-links.sh"
    ["logging"]="unit/test-logging-availability.sh"
)

# 테스트 실행 통계
declare -g TOTAL_TESTS=0
declare -g PASSED_TESTS=0
declare -g FAILED_TESTS=0
declare -g SKIPPED_TESTS=0
declare -g START_TIME=""
declare -g FAILED_TEST_FILES=()

# 사용법 출력
usage() {
    cat << EOF
$RUNNER_NAME v$TEST_RUNNER_VERSION

사용법: $0 [옵션] [카테고리|파일...]

테스트 카테고리:
  core        - 핵심 시스템 테스트 (platform-system, user-resolution 등)
  claude      - Claude 관련 테스트들
  workflow    - 엔드투엔드 워크플로 테스트
  integration - 통합 테스트
  performance - 성능 테스트
  nix-apps    - Nix 앱 링크 테스트
  logging     - 로깅 시스템 테스트
  all         - 모든 테스트 (기본값)

옵션:
  -p, --parallel          병렬 실행 활성화 (기본: $DEFAULT_PARALLEL_JOBS개 작업)
  -j, --jobs N           병렬 작업 수 설정 (기본: $DEFAULT_PARALLEL_JOBS)
  -t, --timeout N        테스트 타임아웃 초 (기본: $DEFAULT_TIMEOUT)
  -v, --verbose          자세한 출력
  -q, --quiet           간단한 출력 (CI용)
  -n, --dry-run         실제 실행하지 않고 계획만 표시
  -f, --fail-fast       첫 번째 실패에서 중단
  --format FORMAT       출력 형식 (standard|json|junit) (기본: standard)
  --list                사용 가능한 테스트 목록 표시
  --list-categories     테스트 카테고리 목록 표시
  -h, --help           이 도움말 표시

예제:
  $0                          # 모든 테스트 실행
  $0 core                     # 핵심 테스트만 실행
  $0 --parallel core claude   # 핵심 및 Claude 테스트를 병렬로 실행
  $0 -v -f workflow          # 워크플로 테스트를 자세한 출력으로 실행, 실패시 중단
  $0 --dry-run all           # 모든 테스트 계획만 표시
  $0 unit/test-platform-system.sh  # 특정 테스트 파일 실행

환경 변수:
  PARALLEL_MODE=true    - 병렬 모드 활성화
  PARALLEL_JOBS=8       - 병렬 작업 수
  TEST_TIMEOUT=120      - 테스트 타임아웃 (초)
  VERBOSE_MODE=true     - 자세한 출력
  DEBUG=true            - 디버그 출력
  OUTPUT_FORMAT=json    - 출력 형식
EOF
}

# 테스트 파일 목록 표시
list_tests() {
    log_header "사용 가능한 테스트 파일들"
    
    find "$SCRIPT_DIR" -name "test-*.sh" -type f | sort | while read -r test_file; do
        local rel_path=${test_file#$SCRIPT_DIR/}
        local size=$(wc -l < "$test_file")
        printf "  %-40s (%d lines)\n" "$rel_path" "$size"
    done
}

# 테스트 카테고리 목록 표시
list_categories() {
    log_header "테스트 카테고리"
    
    for category in "${!TEST_CATEGORIES[@]}"; do
        local test_files=(${TEST_CATEGORIES[$category]})
        log_info "$category (${#test_files[@]}개 테스트)"
        for test_file in "${test_files[@]}"; do
            log_tree 1 "$test_file"
        done
    done
}

# 테스트 계획 표시
show_test_plan() {
    local test_files=("$@")
    
    log_header "테스트 실행 계획"
    log_info "총 ${#test_files[@]}개 테스트 파일"
    log_info "병렬 모드: $([ "$PARALLEL_MODE" = "true" ] && echo "활성화 (${PARALLEL_JOBS}개 작업)" || echo "비활성화")"
    log_info "타임아웃: ${TEST_TIMEOUT}초"
    log_info "출력 형식: $OUTPUT_FORMAT"
    
    if [[ "${#test_files[@]}" -gt 0 ]]; then
        log_separator
        for ((i=0; i<${#test_files[@]}; i++)); do
            log_step $((i+1)) ${#test_files[@]} "${test_files[i]}"
        done
    fi
}

# 단일 테스트 파일 실행
run_single_test() {
    local test_file="$1"
    local test_path="$SCRIPT_DIR/$test_file"
    
    if [[ ! -f "$test_path" ]]; then
        log_error "테스트 파일 없음: $test_file"
        return 2
    fi
    
    if [[ ! -x "$test_path" ]]; then
        chmod +x "$test_path"
    fi
    
    local start_time=$(date +%s%N)
    local exit_code=0
    local output=""
    
    if [[ "$VERBOSE_MODE" = "true" ]]; then
        log_info "실행 중: $test_file"
        if timeout "${TEST_TIMEOUT}s" bash "$test_path"; then
            exit_code=0
        else
            exit_code=$?
        fi
    else
        output=$(timeout "${TEST_TIMEOUT}s" bash "$test_path" 2>&1) || exit_code=$?
    fi
    
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 ))
    
    case $exit_code in
        0)
            if [[ "$OUTPUT_FORMAT" = "standard" ]]; then
                log_success "$test_file (${duration}ms)"
            fi
            ((PASSED_TESTS++))
            ;;
        124)
            log_error "$test_file - 타임아웃 (${TEST_TIMEOUT}초)"
            ((FAILED_TESTS++))
            FAILED_TEST_FILES+=("$test_file (timeout)")
            ;;
        *)
            if [[ "$OUTPUT_FORMAT" = "standard" ]]; then
                log_fail "$test_file - 종료 코드: $exit_code (${duration}ms)"
                if [[ -n "$output" && "$VERBOSE_MODE" != "true" ]]; then
                    echo "$output" | head -n 10
                fi
            fi
            ((FAILED_TESTS++))
            FAILED_TEST_FILES+=("$test_file (exit:$exit_code)")
            ;;
    esac
    
    return $exit_code
}

# 병렬 테스트 실행
run_tests_parallel() {
    local test_files=("$@")
    local pids=()
    local temp_dir=$(mktemp -d)
    
    log_info "병렬 테스트 시작 (${PARALLEL_JOBS}개 작업)"
    
    # 작업 큐 생성
    printf '%s\n' "${test_files[@]}" > "$temp_dir/test_queue"
    
    # 워커 프로세스들 시작
    for ((i=0; i<PARALLEL_JOBS; i++)); do
        (
            while IFS= read -r test_file; do
                run_single_test "$test_file"
                echo "$?" > "$temp_dir/result_${test_file//\//_}"
            done < "$temp_dir/test_queue"
        ) &
        pids+=($!)
    done
    
    # 진행률 표시
    if [[ "$OUTPUT_FORMAT" = "standard" ]]; then
        local completed=0
        while [[ $completed -lt ${#test_files[@]} ]]; do
            completed=$(ls "$temp_dir"/result_* 2>/dev/null | wc -l)
            show_progress "$completed" "${#test_files[@]}" "테스트 진행 중"
            sleep 0.5
        done
        echo  # 새 줄
    fi
    
    # 모든 워커 대기
    for pid in "${pids[@]}"; do
        wait "$pid"
    done
    
    # 결과 수집
    for test_file in "${test_files[@]}"; do
        local result_file="$temp_dir/result_${test_file//\//_}"
        if [[ -f "$result_file" ]]; then
            local result=$(cat "$result_file")
            ((TOTAL_TESTS++))
        else
            log_warning "결과 파일 없음: $test_file"
            ((SKIPPED_TESTS++))
        fi
    done
    
    rm -rf "$temp_dir"
}

# 순차 테스트 실행
run_tests_sequential() {
    local test_files=("$@")
    
    for test_file in "${test_files[@]}"; do
        ((TOTAL_TESTS++))
        
        if ! run_single_test "$test_file"; then
            if [[ "$FAIL_FAST" = "true" ]]; then
                log_error "첫 번째 실패로 인해 테스트 중단됨"
                break
            fi
        fi
    done
}

# 테스트 파일 해상도
resolve_test_files() {
    local inputs=("$@")
    local resolved_files=()
    
    if [[ ${#inputs[@]} -eq 0 ]] || [[ "${inputs[0]}" = "all" ]]; then
        # 모든 테스트 파일 추가
        for category in "${!TEST_CATEGORIES[@]}"; do
            local category_files=(${TEST_CATEGORIES[$category]})
            resolved_files+=("${category_files[@]}")
        done
    else
        for input in "${inputs[@]}"; do
            if [[ -n "${TEST_CATEGORIES[$input]:-}" ]]; then
                # 카테고리로 인식
                local category_files=(${TEST_CATEGORIES[$input]})
                resolved_files+=("${category_files[@]}")
            elif [[ -f "$SCRIPT_DIR/$input" ]]; then
                # 파일 경로로 인식
                resolved_files+=("$input")
            elif [[ -f "$input" ]]; then
                # 절대 경로
                local rel_path=${input#$SCRIPT_DIR/}
                resolved_files+=("$rel_path")
            else
                log_warning "알 수 없는 테스트 입력: $input"
            fi
        done
    fi
    
    # 중복 제거 및 정렬
    printf '%s\n' "${resolved_files[@]}" | sort -u
}

# JSON 형식 출력
output_json_results() {
    local duration=$(( ($(date +%s%N) - START_TIME) / 1000000 ))
    
    cat << EOF
{
  "runner": "$RUNNER_NAME",
  "version": "$TEST_RUNNER_VERSION",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "duration_ms": $duration,
  "summary": {
    "total": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "skipped": $SKIPPED_TESTS,
    "success_rate": $(( TOTAL_TESTS > 0 ? (PASSED_TESTS * 100) / TOTAL_TESTS : 0 ))
  },
  "config": {
    "parallel_mode": $PARALLEL_MODE,
    "parallel_jobs": $PARALLEL_JOBS,
    "timeout": $TEST_TIMEOUT,
    "fail_fast": $FAIL_FAST
  },
  "failed_tests": [
    $(printf '"%s",' "${FAILED_TEST_FILES[@]}" | sed 's/,$//')
  ]
}
EOF
}

# 표준 형식 결과 출력
output_standard_results() {
    local duration=$(( ($(date +%s%N) - START_TIME) / 1000000 ))
    local duration_str="${duration}ms"
    if [[ $duration -gt 1000 ]]; then
        duration_str="$((duration / 1000))s"
    fi
    
    log_separator
    log_header "테스트 결과 요약"
    log_info "실행 시간: $duration_str"
    log_info "전체 테스트: $TOTAL_TESTS"
    log_info "통과: $PASSED_TESTS"
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        log_error "실패: $FAILED_TESTS"
        log_thin_separator
        log_error "실패한 테스트들:"
        for failed_test in "${FAILED_TEST_FILES[@]}"; do
            log_tree 1 "$failed_test"
        done
        log_thin_separator
        local success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
        log_error "성공률: ${success_rate}%"
        return 1
    else
        if [[ $SKIPPED_TESTS -gt 0 ]]; then
            log_warning "건너뜀: $SKIPPED_TESTS"
        fi
        log_success "모든 테스트가 통과했습니다!"
        return 0
    fi
}

# 메인 실행 함수
main() {
    local args=()
    
    # 인자 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--parallel)
                PARALLEL_MODE=true
                shift
                ;;
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            -t|--timeout)
                TEST_TIMEOUT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE_MODE=true
                shift
                ;;
            -q|--quiet)
                LOG_LEVEL=$LOG_LEVEL_WARNING
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--fail-fast)
                FAIL_FAST=true
                shift
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --list)
                list_tests
                exit 0
                ;;
            --list-categories)
                list_categories
                exit 0
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                log_error "알 수 없는 옵션: $1"
                exit 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # 시작 시간 기록
    START_TIME=$(date +%s%N)
    
    # 테스트 파일 해상도
    local test_files_array
    readarray -t test_files_array < <(resolve_test_files "${args[@]}")
    
    if [[ ${#test_files_array[@]} -eq 0 ]]; then
        log_error "실행할 테스트가 없습니다"
        exit 1
    fi
    
    # 계획 표시
    if [[ "$DRY_RUN" = "true" ]]; then
        show_test_plan "${test_files_array[@]}"
        exit 0
    fi
    
    # 실행 모드에 따른 테스트 실행
    log_header "$RUNNER_NAME 시작"
    show_test_plan "${test_files_array[@]}"
    
    if [[ "$PARALLEL_MODE" = "true" ]] && [[ ${#test_files_array[@]} -gt 1 ]]; then
        run_tests_parallel "${test_files_array[@]}"
    else
        run_tests_sequential "${test_files_array[@]}"
    fi
    
    # 결과 출력
    case "$OUTPUT_FORMAT" in
        "json")
            output_json_results
            ;;
        "junit")
            # JUnit XML 형식은 추후 구현
            log_warning "JUnit 형식은 아직 구현되지 않았습니다"
            output_standard_results
            ;;
        *)
            output_standard_results
            ;;
    esac
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi