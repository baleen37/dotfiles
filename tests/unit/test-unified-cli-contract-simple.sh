#!/usr/bin/env bash
# ABOUTME: 통합 CLI 인터페이스 계약 테스트 (간단한 독립 버전)
# ABOUTME: TDD RED 페이즈 확인을 위한 기본적인 실패 테스트

set -euo pipefail

readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly UNIFIED_TEST_CLI="$PROJECT_ROOT/tests/lib/unified/test-cli.sh"

# 간단한 테스트 프레임워크
TESTS_RUN=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_function="$2"

    echo "Running: $test_name"
    ((TESTS_RUN++))

    if $test_function; then
        echo "✓ PASS: $test_name"
    else
        echo "✗ FAIL: $test_name"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# === TDD RED 페이즈 테스트들 ===

test_cli_not_implemented() {
    # 구현되지 않았으므로 파일이 존재하지 않아야 함 (RED 페이즈)
    if [[ ! -f "$UNIFIED_TEST_CLI" ]]; then
        echo "  Expected failure: CLI not implemented yet (RED phase)"
        return 0  # 이것이 예상된 실패 상태
    else
        echo "  Unexpected: CLI file exists before implementation"
        return 1
    fi
}

test_smart_selection_not_implemented() {
    local smart_selection="$PROJECT_ROOT/tests/lib/unified/smart-selection.sh"
    if [[ ! -f "$smart_selection" ]]; then
        echo "  Expected failure: Smart selection not implemented yet (RED phase)"
        return 0
    else
        echo "  Unexpected: Smart selection exists before implementation"
        return 1
    fi
}

test_data_models_not_implemented() {
    local test_suite_model="$PROJECT_ROOT/tests/lib/unified/test-suite.sh"
    if [[ ! -f "$test_suite_model" ]]; then
        echo "  Expected failure: TestSuite model not implemented yet (RED phase)"
        return 0
    else
        echo "  Unexpected: TestSuite model exists before implementation"
        return 1
    fi
}

test_directories_created() {
    local unified_dir="$PROJECT_ROOT/tests/lib/unified"
    if [[ -d "$unified_dir" ]]; then
        echo "  Directory structure created: $unified_dir"
        return 0
    else
        echo "  Setup incomplete: unified directory missing"
        return 1
    fi
}

test_config_created() {
    local config_file="$PROJECT_ROOT/tests/config/test-interface-config.sh"
    if [[ -f "$config_file" ]]; then
        echo "  Configuration file created: $config_file"
        return 0
    else
        echo "  Setup incomplete: configuration file missing"
        return 1
    fi
}

# === 메인 실행 ===

main() {
    echo "=== TDD RED Phase Verification ==="
    echo "Testing that implementations don't exist yet (expected failures)"
    echo ""

    # Setup 검증 (성공해야 함)
    run_test "Directory structure created" test_directories_created
    run_test "Configuration file created" test_config_created

    # Implementation 검증 (실패해야 함 - RED 페이즈)
    run_test "CLI not implemented (expected)" test_cli_not_implemented
    run_test "Smart selection not implemented (expected)" test_smart_selection_not_implemented
    run_test "Data models not implemented (expected)" test_data_models_not_implemented

    echo "=== Test Results ==="
    echo "Tests run: $TESTS_RUN"
    echo "Tests failed: $TESTS_FAILED"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 RED phase verification PASSED - Ready for implementation!"
        echo "All core components are correctly NOT implemented yet."
        return 0
    else
        echo "❌ RED phase verification FAILED"
        echo "Some components may be partially implemented before tests."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
