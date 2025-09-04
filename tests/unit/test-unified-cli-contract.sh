#!/usr/bin/env bash
# ABOUTME: 통합 CLI 인터페이스 계약 테스트
# ABOUTME: unified-test-interface.md 계약서의 모든 요구사항을 검증

# TDD RED 페이즈: 이 테스트들은 구현 전까지 실패해야 함

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TEST_LIB="$PROJECT_ROOT/tests/lib"

# 기존 테스트 프레임워크 로드
source "$TEST_LIB/common.sh"
source "$TEST_LIB/test-framework.sh"

# 테스트 설정
readonly TEST_SUITE_NAME="Unified CLI Interface Contract"
readonly UNIFIED_TEST_CLI="$PROJECT_ROOT/tests/lib/unified/test-cli.sh"

# === 계약 요구사항 테스트 ===

test_cli_command_structure() {
    local test_name="CLI command structure matches contract"

    # CLI가 구현되었는지 확인
    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        assert false "$test_name" "CLI file exists" "CLI not found"
        return 1
    fi

    if [[ ! -x "$UNIFIED_TEST_CLI" ]]; then
        assert false "$test_name" "CLI is executable" "CLI not executable"
        return 1
    fi

    # 기본 명령어 구조 테스트: test [CATEGORY] [OPTIONS] [PATTERNS...]
    local output
    output=$("$UNIFIED_TEST_CLI" --help 2>&1) || {
        fail_test "$test_name" "CLI help command failed"
        return 1
    }

    # 도움말에 필수 섹션이 있는지 확인
    local required_sections=(
        "USAGE"
        "CATEGORIES"
        "OPTIONS"
        "EXAMPLES"
    )

    for section in "${required_sections[@]}"; do
        if ! echo "$output" | grep -q "$section"; then
            assert false "$test_name" "Help contains $section" "Missing $section section"
            return 1
        fi
    done

    assert true "$test_name" "All required sections present" "All sections found"
}

test_supported_categories() {
    local test_name="Supported categories match contract"

    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        assert false "$test_name" "CLI file exists" "CLI not found"
        return 1
    fi

    local required_categories=("all" "quick" "unit" "integration" "e2e" "performance" "smoke")
    local help_output
    help_output=$("$UNIFIED_TEST_CLI" --help 2>&1)

    for category in "${required_categories[@]}"; do
        if ! echo "$help_output" | grep -q "\b$category\b"; then
            fail_test "$test_name" "Missing required category: $category"
            return 1
        fi
    done

    pass_test "$test_name"
}

test_global_options() {
    local test_name="Global options match contract specification"

    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        fail_test "$test_name" "CLI not implemented (expected RED phase failure)"
        return 0
    fi

    local required_options=(
        "--help|-h"
        "--version|-v"
        "--format"
        "--verbose"
        "--quiet"
        "--parallel"
        "--timeout"
        "--dry-run"
    )

    local help_output
    help_output=$("$UNIFIED_TEST_CLI" --help 2>&1)

    for option in "${required_options[@]}"; do
        if ! echo "$help_output" | grep -qE "$option"; then
            fail_test "$test_name" "Missing required option: $option"
            return 1
        fi
    done

    pass_test "$test_name"
}

test_filtering_options() {
    local test_name="Filtering options match contract"

    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        fail_test "$test_name" "CLI not implemented (expected RED phase failure)"
        return 0
    fi

    local filtering_options=(
        "--changed"
        "--failed"
        "--tag"
        "--exclude"
        "--platform"
    )

    local help_output
    help_output=$("$UNIFIED_TEST_CLI" --help 2>&1)

    for option in "${filtering_options[@]}"; do
        if ! echo "$help_output" | grep -q "$option"; then
            fail_test "$test_name" "Missing filtering option: $option"
            return 1
        fi
    done

    pass_test "$test_name"
}

test_output_formats() {
    local test_name="Output formats match contract specification"

    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        fail_test "$test_name" "CLI not implemented (expected RED phase failure)"
        return 0
    fi

    local supported_formats=("human" "json" "tap" "junit")

    for format in "${supported_formats[@]}"; do
        local result
        result=$("$UNIFIED_TEST_CLI" quick --format "$format" --dry-run 2>&1) || {
            fail_test "$test_name" "Format $format not supported"
            return 1
        }

        # 각 형식에 맞는 출력 구조 확인
        case "$format" in
            "json")
                if ! echo "$result" | jq . >/dev/null 2>&1; then
                    fail_test "$test_name" "Invalid JSON output for format: $format"
                    return 1
                fi
                ;;
            "tap")
                if ! echo "$result" | grep -q "^1\.\."; then
                    fail_test "$test_name" "Invalid TAP format output"
                    return 1
                fi
                ;;
            "human")
                if ! echo "$result" | grep -qE "🚀|Running|Tests"; then
                    fail_test "$test_name" "Invalid human format output"
                    return 1
                fi
                ;;
        esac
    done

    pass_test "$test_name"
}

test_exit_codes() {
    local test_name="Exit codes match contract specification"

    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        fail_test "$test_name" "CLI not implemented (expected RED phase failure)"
        return 0
    fi

    # 성공 케이스 (모든 테스트 통과)
    "$UNIFIED_TEST_CLI" quick --dry-run >/dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        fail_test "$test_name" "Success case should return exit code 0, got: $exit_code"
        return 1
    fi

    # 사용법 오류 케이스
    "$UNIFIED_TEST_CLI" --invalid-option >/dev/null 2>&1
    local exit_code=$?
    if [[ $exit_code -ne 2 ]]; then
        fail_test "$test_name" "Usage error should return exit code 2, got: $exit_code"
        return 1
    fi

    pass_test "$test_name"
}

test_backward_compatibility() {
    local test_name="Backward compatibility with existing commands"

    # 기존 명령어들이 새로운 인터페이스로 매핑되는지 확인
    local legacy_mappings=(
        "make test:test all"
        "make test-quick:test quick"
        "make test-core:test unit"
        "make smoke:test smoke"
    )

    for mapping in "${legacy_mappings[@]}"; do
        local legacy="${mapping%%:*}"
        local new="${mapping##*:}"

        # 레거시 명령어 실행 시 적절한 경고와 함께 새 명령어로 리디렉션되는지 확인
        # 구현되지 않았으므로 현재는 실패
        fail_test "$test_name" "Legacy command mapping not implemented: $legacy → $new"
    done
}

test_performance_contract() {
    local test_name="Performance requirements per contract"

    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        fail_test "$test_name" "CLI not implemented (expected RED phase failure)"
        return 0
    fi

    # 응답 시간 보장: 명령어 시작 → 첫 출력 < 500ms
    local start_time=$(date +%s%3N)
    "$UNIFIED_TEST_CLI" --version >/dev/null 2>&1
    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    if [[ $duration -gt 500 ]]; then
        fail_test "$test_name" "Version command took ${duration}ms (>500ms contract violation)"
        return 1
    fi

    # Quick 카테고리 실행 시간: < 10초
    start_time=$(date +%s%3N)
    "$UNIFIED_TEST_CLI" quick --dry-run >/dev/null 2>&1
    end_time=$(date +%s%3N)
    duration=$((end_time - start_time))

    if [[ $duration -gt 10000 ]]; then
        fail_test "$test_name" "Quick test execution took ${duration}ms (>10s contract violation)"
        return 1
    fi

    pass_test "$test_name"
}

# === 메인 테스트 실행 ===

run_contract_tests() {
    start_test_suite "$TEST_SUITE_NAME"

    # 모든 계약 테스트 실행
    test_cli_command_structure
    test_supported_categories
    test_global_options
    test_filtering_options
    test_output_formats
    test_exit_codes
    test_backward_compatibility
    test_performance_contract

    end_test_suite "$TEST_SUITE_NAME"
}

# 스크립트가 직접 실행될 때만 테스트 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_contract_tests
fi
