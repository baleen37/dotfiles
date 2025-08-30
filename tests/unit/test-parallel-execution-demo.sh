#!/usr/bin/env bash
# ABOUTME: 병렬 테스트 실행 데모
# ABOUTME: 병렬 실행 메커니즘과 테스트 격리 검증

set -euo pipefail

# 공통 라이브러리 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

# 병렬 테스트용 커스텀 setup
setup_custom() {
    log_debug "병렬 테스트 커스텀 setup 실행"

    # 각 테스트별로 격리된 작업 공간 생성
    PARALLEL_WORKSPACE="$TEST_CASE_TEMP_DIR/parallel_workspace"
    mkdir -p "$PARALLEL_WORKSPACE"
    export PARALLEL_WORKSPACE

    log_debug "병렬 테스트 작업공간 생성: $PARALLEL_WORKSPACE"
}

teardown_custom() {
    log_debug "병렬 테스트 커스텀 teardown 실행"
    # 기본 teardown에서 TEST_CASE_TEMP_DIR이 정리됨
}

# 다양한 실행 시간을 가진 테스트 함수들
test_fast_operation() {
    local test_file="$PARALLEL_WORKSPACE/fast_test.txt"
    echo "Fast test data" > "$test_file"
    assert_file_exists "$test_file" "빠른 테스트 파일 생성"
    assert_contains "$(cat "$test_file")" "Fast test" "빠른 테스트 내용 확인"
}

test_medium_operation() {
    local test_file="$PARALLEL_WORKSPACE/medium_test.txt"
    echo "Medium test data" > "$test_file"
    sleep 0.5  # 0.5초 대기로 중간 속도 시뮬레이션
    assert_file_exists "$test_file" "중간 테스트 파일 생성"
    assert_contains "$(cat "$test_file")" "Medium test" "중간 테스트 내용 확인"
}

test_slow_operation() {
    local test_file="$PARALLEL_WORKSPACE/slow_test.txt"
    echo "Slow test data" > "$test_file"
    sleep 1.0  # 1초 대기로 느린 속도 시뮬레이션
    assert_file_exists "$test_file" "느린 테스트 파일 생성"
    assert_contains "$(cat "$test_file")" "Slow test" "느린 테스트 내용 확인"
}

test_isolation_check() {
    # 각 테스트가 독립적인 환경에서 실행되는지 확인
    local isolation_file="$PARALLEL_WORKSPACE/isolation_test.txt"
    local test_id="${TEST_CASE_ID:-unknown}"

    echo "Test ID: $test_id" > "$isolation_file"
    assert_file_exists "$isolation_file" "격리 테스트 파일 생성"
    assert_contains "$(cat "$isolation_file")" "$test_id" "테스트 ID 격리 확인"

    # 각 테스트가 고유한 임시 디렉토리를 가지는지 확인
    assert_not_empty "$TEST_CASE_TEMP_DIR" "테스트별 임시 디렉토리 존재"
    assert_directory_exists "$TEST_CASE_TEMP_DIR" "테스트 임시 디렉토리 유효성"
}

test_concurrent_file_operations() {
    # 동시 파일 작업 테스트
    local concurrent_file="$PARALLEL_WORKSPACE/concurrent_test.txt"
    local test_pid=$$

    echo "Process $test_pid" > "$concurrent_file"
    assert_file_exists "$concurrent_file" "동시 실행 파일 생성"
    assert_contains "$(cat "$concurrent_file")" "$test_pid" "프로세스별 데이터 격리"
}

# 메인 실행 함수
main() {
    begin_test_suite "병렬 테스트 실행 및 격리 검증"

    # 환경 검증
    validate_test_environment || {
        log_error "테스트 환경 검증 실패"
        exit 1
    }

    log_info "=== 순차 실행 테스트 ==="
    # 먼저 순차 실행으로 테스트
    run_test "빠른 작업" test_fast_operation
    run_test "중간 작업" test_medium_operation
    run_test "격리 확인" test_isolation_check

    log_info "=== 병렬 실행 테스트 ==="
    # 병렬 실행 지원이 있는 경우 테스트
    if declare -f "run_tests_parallel" > /dev/null; then
        log_info "병렬 실행 메커니즘 테스트 중..."

        # 병렬 테스트를 위한 설정
        export MAX_PARALLEL_TESTS=3

        # 병렬로 실행할 테스트들 정의 (테스트명:함수명 형식)
        local parallel_tests=(
            "병렬 빠른 작업:test_fast_operation"
            "병렬 중간 작업:test_medium_operation"
            "병렬 느린 작업:test_slow_operation"
            "병렬 격리 확인:test_isolation_check"
            "병렬 동시 작업:test_concurrent_file_operations"
        )

        # 병렬 실행
        run_tests_parallel "${parallel_tests[@]}"

        log_success "병렬 테스트 실행 완료"
    else
        log_warning "병렬 실행 함수를 찾을 수 없어 건너뜀"
    fi

    end_test_suite "병렬 테스트 실행 및 격리 검증"
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
