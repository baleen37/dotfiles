#!/usr/bin/env bash
# ABOUTME: Test 엔티티 구현
# ABOUTME: 개별 테스트 케이스를 관리하는 데이터 모델

set -euo pipefail

readonly TEST_ENTITY_VERSION="1.0.0"

# === Test 엔티티 구조 ===

create_test() {
    local id="$1"
    local name="$2"
    local file_path="$3"
    local category="$4"
    local timeout="${5:-60}"
    local parallel_safe="${6:-true}"

    # 입력 검증
    validate_test_id "$id" || return 1
    validate_test_name "$name" || return 1
    validate_test_file_path "$file_path" || return 1
    validate_test_category "$category" || return 1

    # JSON 형태로 Test 객체 생성
    jq -n \
        --arg id "$id" \
        --arg name "$name" \
        --arg file_path "$file_path" \
        --arg category "$category" \
        --arg timeout "$timeout" \
        --argjson parallel_safe "$parallel_safe" \
        --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg version "$TEST_ENTITY_VERSION" \
        '{
            id: $id,
            name: $name,
            file_path: $file_path,
            category: $category,
            dependencies: [],
            tags: [],
            timeout: ($timeout | tonumber),
            parallel_safe: $parallel_safe,
            platform_specific: [],
            metadata: {
                created_at: $created_at,
                version: $version,
                status: "pending",
                last_run: null,
                run_count: 0,
                success_rate: 0
            }
        }'
}

# Test에 의존성 추가
add_test_dependency() {
    local test_json="$1"
    local dependency_id="$2"

    # 순환 의존성 검사
    if has_circular_dependency "$test_json" "$dependency_id"; then
        echo "ERROR: Circular dependency detected: $dependency_id" >&2
        return 1
    fi

    echo "$test_json" | jq \
        --arg dep_id "$dependency_id" \
        '.dependencies += [$dep_id] | .dependencies |= unique'
}

# Test에 태그 추가
add_test_tag() {
    local test_json="$1"
    shift
    local tags=("$@")

    local jq_args=""
    for tag in "${tags[@]}"; do
        jq_args="$jq_args --arg tag_$(echo "$tag" | tr -cd '[:alnum:]') \"$tag\""
    done

    echo "$test_json" | jq '.tags += $ARGS.positional | .tags |= unique' --args "${tags[@]}"
}

# Test 플랫폼 제한 설정
set_test_platforms() {
    local test_json="$1"
    shift
    local platforms=("$@")

    # 플랫폼 유효성 검사
    for platform in "${platforms[@]}"; do
        if [[ ! "$platform" =~ ^(darwin|nixos|linux)$ ]]; then
            echo "ERROR: Invalid platform: $platform (valid: darwin, nixos, linux)" >&2
            return 1
        fi
    done

    echo "$test_json" | jq --args '.platform_specific = $ARGS.positional' "${platforms[@]}"
}

# === 검증 함수들 ===

validate_test_id() {
    local id="$1"

    # ID 유효성 검사: 영숫자, 하이픈, 언더스코어 허용
    if [[ ! "$id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid test ID: $id (use letters, numbers, hyphens, underscores only)" >&2
        return 1
    fi

    # 길이 제한
    if [[ ${#id} -lt 1 || ${#id} -gt 100 ]]; then
        echo "ERROR: Test ID length must be 1-100 characters: $id" >&2
        return 1
    fi

    return 0
}

validate_test_name() {
    local name="$1"

    if [[ ${#name} -lt 1 || ${#name} -gt 200 ]]; then
        echo "ERROR: Test name length must be 1-200 characters: $name" >&2
        return 1
    fi

    return 0
}

validate_test_file_path() {
    local file_path="$1"

    # 절대 경로 요구사항
    if [[ ! "$file_path" =~ ^/ ]]; then
        echo "ERROR: Test file path must be absolute: $file_path" >&2
        return 1
    fi

    # 파일 존재 여부는 경고만 (구현 중에는 아직 없을 수 있음)
    if [[ ! -f "$file_path" ]]; then
        echo "WARN: Test file does not exist yet: $file_path" >&2
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

# === 의존성 관리 ===

has_circular_dependency() {
    local test_json="$1"
    local new_dependency="$2"

    # 단순화된 순환 검사 (실제로는 전체 그래프 필요)
    local current_id
    current_id=$(echo "$test_json" | jq -r '.id')

    # 직접적인 순환 의존성 검사
    if [[ "$new_dependency" == "$current_id" ]]; then
        return 0  # 순환 발견
    fi

    # 현재 의존성 목록에서 검사
    local existing_deps
    existing_deps=$(echo "$test_json" | jq -r '.dependencies[]?' 2>/dev/null || true)

    while read -r dep; do
        if [[ "$dep" == "$new_dependency" ]]; then
            return 1  # 이미 존재하는 의존성 (순환은 아님)
        fi
    done <<< "$existing_deps"

    return 1  # 순환 없음
}

get_test_dependencies() {
    local test_json="$1"
    echo "$test_json" | jq -r '.dependencies[]?'
}

# === 상태 관리 ===

update_test_status() {
    local test_json="$1"
    local new_status="$2"

    validate_test_status "$new_status" || return 1

    local run_count
    run_count=$(echo "$test_json" | jq -r '.metadata.run_count')
    ((run_count++))

    echo "$test_json" | jq \
        --arg status "$new_status" \
        --arg updated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg run_count "$run_count" \
        '.metadata.status = $status |
         .metadata.last_run = $updated_at |
         .metadata.run_count = ($run_count | tonumber)'
}

validate_test_status() {
    local status="$1"
    local valid_statuses=("pending" "running" "passed" "failed" "skipped" "timeout" "cancelled")

    for valid in "${valid_statuses[@]}"; do
        if [[ "$status" == "$valid" ]]; then
            return 0
        fi
    done

    echo "ERROR: Invalid test status: $status (valid: ${valid_statuses[*]})" >&2
    return 1
}

# === 성공률 계산 ===

calculate_success_rate() {
    local test_json="$1"
    local total_runs passed_runs

    total_runs=$(echo "$test_json" | jq -r '.metadata.run_count')

    if [[ $total_runs -eq 0 ]]; then
        echo "$test_json" | jq '.metadata.success_rate = 0'
        return 0
    fi

    # 실제 구현에서는 실행 히스토리를 추적해야 함
    # 현재는 단순화된 버전
    local current_status
    current_status=$(echo "$test_json" | jq -r '.metadata.status')

    case "$current_status" in
        "passed")
            passed_runs=$total_runs
            ;;
        "failed"|"timeout"|"cancelled")
            passed_runs=$((total_runs - 1))
            ;;
        *)
            passed_runs=$total_runs
            ;;
    esac

    local success_rate
    success_rate=$(echo "scale=2; $passed_runs * 100 / $total_runs" | bc -l 2>/dev/null || echo "0")

    echo "$test_json" | jq \
        --arg success_rate "$success_rate" \
        '.metadata.success_rate = ($success_rate | tonumber)'
}

# === 필터링 함수들 ===

matches_tag() {
    local test_json="$1"
    local target_tag="$2"

    local tags
    tags=$(echo "$test_json" | jq -r '.tags[]?' 2>/dev/null || true)

    while read -r tag; do
        if [[ "$tag" == "$target_tag" ]]; then
            return 0
        fi
    done <<< "$tags"

    return 1
}

matches_platform() {
    local test_json="$1"
    local target_platform="$2"

    local platforms
    platforms=$(echo "$test_json" | jq -r '.platform_specific[]?' 2>/dev/null || true)

    # 플랫폼 제한이 없으면 모든 플랫폼에서 실행 가능
    if [[ -z "$platforms" ]]; then
        return 0
    fi

    while read -r platform; do
        if [[ "$platform" == "$target_platform" ]]; then
            return 0
        fi
    done <<< "$platforms"

    return 1
}

# === 유틸리티 함수들 ===

get_test_property() {
    local test_json="$1"
    local property="$2"

    echo "$test_json" | jq -r ".$property"
}

is_parallel_safe() {
    local test_json="$1"
    echo "$test_json" | jq -r '.parallel_safe'
}

get_test_timeout() {
    local test_json="$1"
    echo "$test_json" | jq -r '.timeout'
}

# === CLI 인터페이스 (테스트용) ===

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "create")
            create_test "$2" "$3" "$4" "$5" "${6:-60}" "${7:-true}"
            ;;
        "add-tag")
            if [[ $# -lt 3 ]]; then
                echo "Usage: $0 add-tag <test_json> <tag1> [tag2...]" >&2
                exit 1
            fi
            test_json="$2"
            shift 2
            add_test_tag "$test_json" "$@"
            ;;
        "validate")
            validate_test_id "$2" &&
            validate_test_name "$3" &&
            validate_test_file_path "$4" &&
            validate_test_category "$5"
            echo "Valid test parameters"
            ;;
        "help"|"--help"|"-h"|"")
            echo "Usage: $0 <command> [args...]"
            echo "Commands:"
            echo "  create <id> <name> <path> <category> [timeout] [parallel]  Create test"
            echo "  add-tag <test_json> <tag1> [tag2...]                      Add tags"
            echo "  validate <id> <name> <path> <category>                    Validate params"
            echo "  help                                                      Show this help"
            ;;
        *)
            echo "Unknown command: $1" >&2
            echo "Use '$0 help' for usage information" >&2
            exit 1
            ;;
    esac
fi
