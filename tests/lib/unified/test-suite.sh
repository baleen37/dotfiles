#!/usr/bin/env bash
# ABOUTME: TestSuite 엔티티 구현
# ABOUTME: 테스트 그룹의 논리적 단위를 관리하는 데이터 모델

set -euo pipefail

# TestSuite 엔티티 구현
readonly TEST_SUITE_VERSION="1.0.0"

# === TestSuite 데이터 구조 ===

# TestSuite 생성
create_test_suite() {
    local id="$1"
    local name="$2"
    local description="$3"
    local category="$4"

    # 입력 검증
    validate_test_suite_id "$id" || return 1
    validate_test_suite_name "$name" || return 1
    validate_test_category "$category" || return 1

    # JSON 형태로 TestSuite 객체 생성
    jq -n \
        --arg id "$id" \
        --arg name "$name" \
        --arg description "$description" \
        --arg category "$category" \
        --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg version "$TEST_SUITE_VERSION" \
        '{
            id: $id,
            name: $name,
            description: $description,
            category: $category,
            tests: [],
            config: {
                timeout: 60,
                parallel: true,
                retry_count: 0
            },
            metadata: {
                created_at: $created_at,
                version: $version,
                status: "pending",
                last_run: null,
                total_runs: 0
            }
        }'
}

# TestSuite에 Test 추가
add_test_to_suite() {
    local suite_json="$1"
    local test_json="$2"

    echo "$suite_json" | jq \
        --argjson test "$test_json" \
        '.tests += [$test]'
}

# TestSuite 상태 업데이트
update_suite_status() {
    local suite_json="$1"
    local new_status="$2"

    validate_test_suite_status "$new_status" || return 1

    echo "$suite_json" | jq \
        --arg status "$new_status" \
        --arg updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '.metadata.status = $status |
         .metadata.last_updated = $updated_at'
}

# TestSuite 설정 업데이트
update_suite_config() {
    local suite_json="$1"
    local timeout="${2:-60}"
    local parallel="${3:-true}"
    local retry_count="${4:-0}"

    echo "$suite_json" | jq \
        --arg timeout "$timeout" \
        --argjson parallel "$parallel" \
        --arg retry_count "$retry_count" \
        '.config.timeout = ($timeout | tonumber) |
         .config.parallel = $parallel |
         .config.retry_count = ($retry_count | tonumber)'
}

# === 검증 함수들 ===

validate_test_suite_id() {
    local id="$1"

    # ID 유효성 검사: 영숫자와 하이픈만 허용 (kebab-case)
    if [[ ! "$id" =~ ^[a-z0-9-]+$ ]]; then
        echo "ERROR: Invalid test suite ID: $id (use lowercase letters, numbers, and hyphens only)" >&2
        return 1
    fi

    # 길이 제한 (1-50자)
    if [[ ${#id} -lt 1 || ${#id} -gt 50 ]]; then
        echo "ERROR: Test suite ID length must be 1-50 characters: $id" >&2
        return 1
    fi

    return 0
}

validate_test_suite_name() {
    local name="$1"

    # 이름 길이 제한 (1-50자)
    if [[ ${#name} -lt 1 || ${#name} -gt 50 ]]; then
        echo "ERROR: Test suite name length must be 1-50 characters: $name" >&2
        return 1
    fi

    return 0
}

validate_test_category() {
    local category="$1"
    local valid_categories=("unit" "integration" "e2e" "performance" "smoke")

    for valid in "${valid_categories[@]}"; do
        if [[ "$category" == "$valid" ]]; then
            return 0
        fi
    done

    echo "ERROR: Invalid test category: $category (valid: ${valid_categories[*]})" >&2
    return 1
}

validate_test_suite_status() {
    local status="$1"
    local valid_statuses=("pending" "running" "completed" "failed" "skipped" "cancelled")

    for valid in "${valid_statuses[@]}"; do
        if [[ "$status" == "$valid" ]]; then
            return 0
        fi
    done

    echo "ERROR: Invalid test suite status: $status (valid: ${valid_statuses[*]})" >&2
    return 1
}

# === 상태 전환 관리 ===

transition_suite_status() {
    local suite_json="$1"
    local target_status="$2"

    local current_status
    current_status=$(echo "$suite_json" | jq -r '.metadata.status')

    # 유효한 상태 전환인지 확인
    if ! is_valid_status_transition "$current_status" "$target_status"; then
        echo "ERROR: Invalid status transition: $current_status → $target_status" >&2
        return 1
    fi

    update_suite_status "$suite_json" "$target_status"
}

is_valid_status_transition() {
    local from="$1"
    local to="$2"

    # 상태 전환 규칙 (data-model.md 기반)
    case "$from→$to" in
        "pending→running"|"pending→skipped"|"running→completed"|"running→failed"|"running→cancelled")
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# === 집계 함수들 ===

calculate_suite_summary() {
    local suite_json="$1"

    # 포함된 테스트들의 상태를 기반으로 스위트 요약 계산
    local tests
    tests=$(echo "$suite_json" | jq '.tests')

    local total_tests
    total_tests=$(echo "$tests" | jq 'length')

    if [[ $total_tests -eq 0 ]]; then
        echo "$suite_json" | jq '.metadata.summary = {
            total: 0,
            passed: 0,
            failed: 0,
            skipped: 0,
            duration: 0
        }'
        return 0
    fi

    # 각 상태별 개수 계산
    local passed failed skipped duration
    passed=$(echo "$tests" | jq '[.[] | select(.status == "passed")] | length')
    failed=$(echo "$tests" | jq '[.[] | select(.status == "failed")] | length')
    skipped=$(echo "$tests" | jq '[.[] | select(.status == "skipped")] | length')
    duration=$(echo "$tests" | jq '[.[] | .duration // 0] | add')

    # 전체 스위트 상태 결정
    local suite_status="completed"
    if [[ $failed -gt 0 ]]; then
        suite_status="failed"
    elif [[ $passed -eq 0 && $skipped -gt 0 ]]; then
        suite_status="skipped"
    fi

    echo "$suite_json" | jq \
        --arg status "$suite_status" \
        --arg total "$total_tests" \
        --arg passed "$passed" \
        --arg failed "$failed" \
        --arg skipped "$skipped" \
        --arg duration "$duration" \
        '.metadata.status = $status |
         .metadata.summary = {
             total: ($total | tonumber),
             passed: ($passed | tonumber),
             failed: ($failed | tonumber),
             skipped: ($skipped | tonumber),
             duration: ($duration | tonumber)
         }'
}

# === 유틸리티 함수들 ===

get_suite_property() {
    local suite_json="$1"
    local property="$2"

    echo "$suite_json" | jq -r ".$property"
}

list_suite_tests() {
    local suite_json="$1"

    echo "$suite_json" | jq -r '.tests[].id'
}

is_suite_empty() {
    local suite_json="$1"

    local test_count
    test_count=$(echo "$suite_json" | jq '.tests | length')

    [[ $test_count -eq 0 ]]
}

# === CLI 인터페이스 (테스트용) ===

# 스크립트가 직접 실행될 때 CLI 제공
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "create")
            create_test_suite "$2" "$3" "$4" "$5"
            ;;
        "validate-id")
            validate_test_suite_id "$2"
            echo "Valid ID: $2"
            ;;
        "validate-category")
            validate_test_category "$2"
            echo "Valid category: $2"
            ;;
        "help"|"--help"|"-h"|"")
            echo "Usage: $0 <command> [args...]"
            echo "Commands:"
            echo "  create <id> <name> <description> <category>  Create new test suite"
            echo "  validate-id <id>                            Validate suite ID"
            echo "  validate-category <category>                Validate category"
            echo "  help                                        Show this help"
            ;;
        *)
            echo "Unknown command: $1" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
fi
