#!/usr/bin/env bash
# ABOUTME: 스마트 테스트 선택 계약 테스트
# ABOUTME: smart-test-selection.md 계약서의 모든 요구사항을 검증

# TDD RED 페이즈: 이 테스트들은 구현 전까지 실패해야 함

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TEST_LIB="$PROJECT_ROOT/tests/lib"

# 기존 테스트 프레임워크 로드
source "$TEST_LIB/test-framework.sh"
source "$TEST_LIB/common.sh"

# 테스트 설정
readonly TEST_SUITE_NAME="Smart Test Selection Contract"
readonly SMART_SELECTION_MODULE="$PROJECT_ROOT/tests/lib/unified/smart-selection.sh"
readonly TEST_CLI="$PROJECT_ROOT/tests/lib/unified/test-cli.sh"

# === 변경 기반 선택 테스트 ===

test_git_change_detection() {
    local test_name="Git change detection functionality"

    if [[ ! -f "$SMART_SELECTION_MODULE" ]]; then
        fail_test "$test_name" "Smart selection module not implemented (expected RED phase failure)"
        return 0
    fi

    # Git 변경사항 감지 테스트
    source "$SMART_SELECTION_MODULE"

    # 테스트용 파일 변경 시뮬레이션
    local test_file="$PROJECT_ROOT/test_change_detection.tmp"
    echo "test content" > "$test_file"

    # 변경된 파일 감지
    local changed_files
    changed_files=$(detect_changed_files "HEAD~1") || {
        fail_test "$test_name" "Failed to detect changed files"
        rm -f "$test_file"
        return 1
    }

    if [[ -z "$changed_files" ]]; then
        fail_test "$test_name" "No changed files detected"
        rm -f "$test_file"
        return 1
    fi

    # 정리
    rm -f "$test_file"
    pass_test "$test_name"
}

test_file_mapping_rules() {
    local test_name="File change to test mapping rules"

    if [[ ! -f "$SMART_SELECTION_MODULE" ]]; then
        fail_test "$test_name" "Smart selection module not implemented (expected RED phase failure)"
        return 0
    fi

    source "$SMART_SELECTION_MODULE"

    # 계약서에 명시된 매핑 규칙 테스트
    local test_mappings=(
        "modules/shared/packages.nix:tests/unit/*package*"
        "lib/platform-system.nix:tests/bats/test_platform_detection.bats"
        "Makefile:tests/integration/test-build-*"
    )

    for mapping in "${test_mappings[@]}"; do
        local file_pattern="${mapping%%:*}"
        local expected_tests="${mapping##*:}"

        local mapped_tests
        mapped_tests=$(map_file_to_tests "$file_pattern") || {
            fail_test "$test_name" "Failed to map file: $file_pattern"
            return 1
        }

        if [[ -z "$mapped_tests" ]]; then
            fail_test "$test_name" "No tests mapped for file: $file_pattern"
            return 1
        fi

        # 매핑 결과가 예상 패턴과 일치하는지 확인
        if ! echo "$mapped_tests" | grep -q "${expected_tests//\*/.*}"; then
            fail_test "$test_name" "Incorrect mapping for $file_pattern. Expected pattern: $expected_tests, Got: $mapped_tests"
            return 1
        fi
    done

    pass_test "$test_name"
}

test_dependency_analysis() {
    local test_name="Dependency-based test selection"

    if [[ ! -f "$SMART_SELECTION_MODULE" ]]; then
        fail_test "$test_name" "Smart selection module not implemented (expected RED phase failure)"
        return 0
    fi

    source "$SMART_SELECTION_MODULE"

    # 의존성 그래프 분석 테스트
    local core_file="lib/platform-system.nix"
    local dependent_tests
    dependent_tests=$(analyze_dependencies "$core_file") || {
        fail_test "$test_name" "Failed to analyze dependencies for: $core_file"
        return 1
    }

    # 핵심 파일의 의존성 분석 결과는 여러 테스트를 포함해야 함
    local test_count=$(echo "$dependent_tests" | wc -w)
    if [[ $test_count -lt 2 ]]; then
        fail_test "$test_name" "Insufficient dependent tests found for core file: $core_file (found: $test_count)"
        return 1
    fi

    pass_test "$test_name"
}

# === 선택 전략 테스트 ===

test_fast_feedback_strategy() {
    local test_name="Fast feedback strategy implementation"

    if [[ ! -f "$TEST_CLI" ]]; then
        fail_test "$test_name" "Test CLI not implemented (expected RED phase failure)"
        return 0
    fi

    # Fast feedback 전략 테스트 (최대 30초, 최대 10개 테스트)
    local result
    result=$("$TEST_CLI" --changed --strategy fast --dry-run --format json 2>&1) || {
        fail_test "$test_name" "Fast feedback strategy execution failed"
        return 1
    }

    # JSON 응답 파싱
    local selected_count
    selected_count=$(echo "$result" | jq -r '.selected_count' 2>/dev/null) || {
        fail_test "$test_name" "Invalid JSON response for fast feedback strategy"
        return 1
    }

    # 계약 요구사항: 최대 10개 테스트
    if [[ $selected_count -gt 10 ]]; then
        fail_test "$test_name" "Fast feedback strategy selected too many tests: $selected_count (max: 10)"
        return 1
    fi

    # 추정 실행 시간 확인
    local estimated_duration
    estimated_duration=$(echo "$result" | jq -r '.estimated_duration' 2>/dev/null)
    if [[ $estimated_duration -gt 30 ]]; then
        fail_test "$test_name" "Fast feedback strategy estimated duration too long: ${estimated_duration}s (max: 30s)"
        return 1
    fi

    pass_test "$test_name"
}

test_comprehensive_strategy() {
    local test_name="Comprehensive strategy implementation"

    if [[ ! -f "$TEST_CLI" ]]; then
        fail_test "$test_name" "Test CLI not implemented (expected RED phase failure)"
        return 0
    fi

    # Comprehensive 전략 테스트 (최대 5분, 간접 의존성 포함)
    local result
    result=$("$TEST_CLI" --changed --strategy comprehensive --dry-run --format json 2>&1) || {
        fail_test "$test_name" "Comprehensive strategy execution failed"
        return 1
    }

    # 전략이 fast보다 더 많은 테스트를 선택하는지 확인
    local comprehensive_count
    comprehensive_count=$(echo "$result" | jq -r '.selected_count' 2>/dev/null) || {
        fail_test "$test_name" "Invalid JSON response for comprehensive strategy"
        return 1
    }

    # Fast 전략과 비교 (comprehensive는 일반적으로 더 많은 테스트 선택)
    local fast_result
    fast_result=$("$TEST_CLI" --changed --strategy fast --dry-run --format json 2>&1)
    local fast_count
    fast_count=$(echo "$fast_result" | jq -r '.selected_count' 2>/dev/null)

    if [[ $comprehensive_count -lt $fast_count ]]; then
        fail_test "$test_name" "Comprehensive strategy should select >= fast strategy tests. Comprehensive: $comprehensive_count, Fast: $fast_count"
        return 1
    fi

    pass_test "$test_name"
}

# === 캐시 관리 테스트 ===

test_selection_cache() {
    local test_name="Selection result caching functionality"

    if [[ ! -f "$SMART_SELECTION_MODULE" ]]; then
        fail_test "$test_name" "Smart selection module not implemented (expected RED phase failure)"
        return 0
    fi

    source "$SMART_SELECTION_MODULE"

    # 캐시 디렉토리 생성
    local cache_dir="$PROJECT_ROOT/.test-cache/selection"
    mkdir -p "$cache_dir"

    # 첫 번째 선택 실행 (캐시 미스)
    local start_time=$(date +%s%3N)
    local first_result
    first_result=$(select_tests_with_cache "lib/platform-system.nix") || {
        fail_test "$test_name" "First selection execution failed"
        return 1
    }
    local first_duration=$(($(date +%s%3N) - start_time))

    # 두 번째 선택 실행 (캐시 히트)
    start_time=$(date +%s%3N)
    local second_result
    second_result=$(select_tests_with_cache "lib/platform-system.nix") || {
        fail_test "$test_name" "Second selection execution failed"
        return 1
    }
    local second_duration=$(($(date +%s%3N) - start_time))

    # 캐시된 결과가 더 빨라야 함 (최소 50% 향상)
    local speed_improvement=$((100 * (first_duration - second_duration) / first_duration))
    if [[ $speed_improvement -lt 50 ]]; then
        fail_test "$test_name" "Cache did not provide sufficient speed improvement. First: ${first_duration}ms, Second: ${second_duration}ms, Improvement: ${speed_improvement}%"
        return 1
    fi

    # 결과 일관성 확인
    if [[ "$first_result" != "$second_result" ]]; then
        fail_test "$test_name" "Cached result differs from original result"
        return 1
    fi

    # 정리
    rm -rf "$cache_dir"
    pass_test "$test_name"
}

test_cache_invalidation() {
    local test_name="Cache invalidation on file changes"

    if [[ ! -f "$SMART_SELECTION_MODULE" ]]; then
        fail_test "$test_name" "Smart selection module not implemented (expected RED phase failure)"
        return 0
    fi

    source "$SMART_SELECTION_MODULE"

    local cache_dir="$PROJECT_ROOT/.test-cache/selection"
    mkdir -p "$cache_dir"

    # 초기 캐시 생성
    select_tests_with_cache "lib/platform-system.nix" >/dev/null

    # 캐시 파일 존재 확인
    local cache_files=$(find "$cache_dir" -name "*.json" | wc -l)
    if [[ $cache_files -eq 0 ]]; then
        fail_test "$test_name" "No cache files created"
        rm -rf "$cache_dir"
        return 1
    fi

    # 파일 변경 시뮬레이션 (타임스탬프 변경)
    touch "lib/platform-system.nix" 2>/dev/null || true

    # 캐시 무효화 확인
    if ! cache_should_be_invalidated "lib/platform-system.nix"; then
        fail_test "$test_name" "Cache should be invalidated after file change"
        rm -rf "$cache_dir"
        return 1
    fi

    # 정리
    rm -rf "$cache_dir"
    pass_test "$test_name"
}

# === API 인터페이스 테스트 ===

test_cli_integration() {
    local test_name="CLI integration with smart selection"

    if [[ ! -f "$TEST_CLI" ]]; then
        fail_test "$test_name" "Test CLI not implemented (expected RED phase failure)"
        return 0
    fi

    # --changed 옵션 기본 동작
    local result
    result=$("$TEST_CLI" --changed --dry-run 2>&1) || {
        fail_test "$test_name" "--changed option execution failed"
        return 1
    }

    # 결과에 변경사항 정보가 포함되어야 함
    if ! echo "$result" | grep -qE "(changed|modified|affected)"; then
        fail_test "$test_name" "--changed output should mention changed files"
        return 1
    fi

    # --changed --since 옵션
    result=$("$TEST_CLI" --changed --since main --dry-run 2>&1) || {
        fail_test "$test_name" "--changed --since option execution failed"
        return 1
    }

    pass_test "$test_name"
}

test_programmatic_interface() {
    local test_name="Programmatic JSON API interface"

    if [[ ! -f "$TEST_CLI" ]]; then
        fail_test "$test_name" "Test CLI not implemented (expected RED phase failure)"
        return 0
    fi

    # JSON 형식으로 선택 결과 반환
    local json_result
    json_result=$("$TEST_CLI" --changed --dry-run --format json 2>&1) || {
        fail_test "$test_name" "JSON API interface execution failed"
        return 1
    }

    # JSON 구조 유효성 확인
    if ! echo "$json_result" | jq . >/dev/null 2>&1; then
        fail_test "$test_name" "Invalid JSON response from API"
        return 1
    fi

    # 필수 필드 존재 확인
    local required_fields=("strategy" "total_available" "selected_count" "estimated_duration" "selection_rationale")
    for field in "${required_fields[@]}"; do
        if ! echo "$json_result" | jq -e ".$field" >/dev/null 2>&1; then
            fail_test "$test_name" "Missing required JSON field: $field"
            return 1
        fi
    done

    pass_test "$test_name"
}

# === 메인 테스트 실행 ===

run_smart_selection_tests() {
    start_test_suite "$TEST_SUITE_NAME"

    # 모든 스마트 선택 계약 테스트 실행
    test_git_change_detection
    test_file_mapping_rules
    test_dependency_analysis
    test_fast_feedback_strategy
    test_comprehensive_strategy
    test_selection_cache
    test_cache_invalidation
    test_cli_integration
    test_programmatic_interface

    end_test_suite "$TEST_SUITE_NAME"
}

# 스크립트가 직접 실행될 때만 테스트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_smart_selection_tests
fi
