# Claude CLI Comprehensive Test Suite
# 모든 테스트를 조직화하고 실행하는 마스터 테스트 파일

{ pkgs }:

let
  # 테스트 모듈들 가져오기
  unitTests = import ./unit/claude-cli-unit-tests.nix { inherit pkgs; };
  integrationTests = import ./integration/claude-cli-integration-tests.nix { inherit pkgs; };
  e2eTests = import ./e2e/claude-cli-e2e-tests.nix { inherit pkgs; };
  testLib = import ./lib/claude-cli-test-lib.nix { inherit pkgs; };

  # 테스트 실행 및 결과 집계 함수
  runTestSuite = testName: tests: pkgs.writeShellScript "run-${testName}" ''
    echo "=========================================="
    echo "Claude CLI ${testName} Test Suite"
    echo "Started at: $(date)"
    echo "=========================================="

    total_tests=0
    passed_tests=0
    failed_tests=0

    # 각 테스트 실행
    ${builtins.concatStringsSep "\n" (builtins.map (testEntry:
      let
        testKey = builtins.head testEntry;
        testValue = builtins.head (builtins.tail testEntry);
      in ''
        echo ""
        echo "Running ${testKey}..."
        echo "------------------------------------------"
        total_tests=$((total_tests + 1))

        if ${testValue}; then
          echo "✅ ${testKey} PASSED"
          passed_tests=$((passed_tests + 1))
        else
          echo "❌ ${testKey} FAILED"
          failed_tests=$((failed_tests + 1))
        fi
      ''
    ) (builtins.map (name: [name (builtins.getAttr name tests)]) (builtins.attrNames tests)))}

    echo ""
    echo "=========================================="
    echo "${testName} Test Suite Results"
    echo "=========================================="
    echo "Total Tests: $total_tests"
    echo "Passed: $passed_tests"
    echo "Failed: $failed_tests"
    echo "Success Rate: $(( passed_tests * 100 / total_tests ))%"
    echo "Completed at: $(date)"
    echo "=========================================="

    if [[ $failed_tests -gt 0 ]]; then
      echo "❌ ${testName} test suite FAILED"
      exit 1
    else
      echo "✅ ${testName} test suite PASSED"
      exit 0
    fi
  '';

in

rec {
  # 개별 테스트 스위트들
  unit = runTestSuite "Unit" unitTests;
  integration = runTestSuite "Integration" integrationTests;
  e2e = runTestSuite "E2E" e2eTests;

  # 전체 테스트 스위트 실행
  all = pkgs.writeShellScript "run-all-claude-cli-tests" ''
    echo "========================================================"
    echo "Claude CLI Comprehensive Test Suite"
    echo "========================================================"
    echo "Running all tests: Unit → Integration → E2E"
    echo "Started at: $(date)"
    echo ""

    # 테스트 결과 추적
    suite_results=()
    overall_success=true

    # Unit Tests
    echo "🧪 Starting Unit Tests..."
    if ${runTestSuite "Unit" unitTests}; then
      suite_results+=("✅ Unit Tests: PASSED")
    else
      suite_results+=("❌ Unit Tests: FAILED")
      overall_success=false
    fi

    echo ""
    echo "🔗 Starting Integration Tests..."
    if ${runTestSuite "Integration" integrationTests}; then
      suite_results+=("✅ Integration Tests: PASSED")
    else
      suite_results+=("❌ Integration Tests: FAILED")
      overall_success=false
    fi

    echo ""
    echo "🚀 Starting E2E Tests..."
    if ${runTestSuite "E2E" e2eTests}; then
      suite_results+=("✅ E2E Tests: PASSED")
    else
      suite_results+=("❌ E2E Tests: FAILED")
      overall_success=false
    fi

    # 최종 결과 리포트
    echo ""
    echo "========================================================"
    echo "FINAL TEST RESULTS"
    echo "========================================================"

    for result in "''${suite_results[@]}"; do
      echo "$result"
    done

    echo ""
    echo "Completed at: $(date)"

    if $overall_success; then
      echo ""
      echo "🎉 ALL CLAUDE CLI TESTS PASSED!"
      echo "Claude CLI commands are ready for production use."
      echo ""
      echo "Usage:"
      echo "  cc                    # Start Claude CLI"
      echo "  ccw <branch-name>     # Git worktree workflow"
      echo ""
      exit 0
    else
      echo ""
      echo "💥 SOME TESTS FAILED!"
      echo "Please review the test output above and fix issues."
      echo ""
      exit 1
    fi
  '';

  # 빠른 스모크 테스트
  smoke = pkgs.writeShellScript "claude-cli-smoke-test" ''
    echo "🚀 Claude CLI Smoke Test"
    echo "========================"

    # 기본 정의 확인
    ${testLib.claudeCliDefinitions}

    # 기본 기능 테스트
    echo "Testing basic functionality..."

    # CC alias 테스트
    if alias cc >/dev/null 2>&1; then
      echo "✅ cc alias defined"
    else
      echo "❌ cc alias missing"
      exit 1
    fi

    # CCW 함수 테스트
    if declare -f ccw >/dev/null 2>&1; then
      echo "✅ ccw function defined"
    else
      echo "❌ ccw function missing"
      exit 1
    fi

    # 기본 사용법 테스트
    if ccw 2>&1 | grep -q "Usage: ccw"; then
      echo "✅ ccw usage message working"
    else
      echo "❌ ccw usage message failed"
      exit 1
    fi

    echo ""
    echo "🎉 Smoke test passed! Basic functionality is working."
    echo ""
    echo "To run comprehensive tests:"
    echo "  nix run .#tests.claude-cli-test-suite.all"
  '';

  # 성능 테스트
  performance = pkgs.writeShellScript "claude-cli-performance-test" ''
    echo "⚡ Claude CLI Performance Test"
    echo "============================="

    ${testLib.claudeCliDefinitions}
    ${testLib.createTestRepo "performance-test"}

    # CCW 실행 시간 측정
    echo "Measuring ccw performance..."

    start_time=$(date +%s%N)
    ccw "perf-test-branch" >/dev/null 2>&1
    end_time=$(date +%s%N)

    execution_time=$(( (end_time - start_time) / 1000000 ))  # milliseconds

    echo "ccw execution time: ''${execution_time}ms"

    # 성능 기준: 5초 이내 (5000ms)
    if [[ $execution_time -lt 5000 ]]; then
      echo "✅ Performance test passed (under 5 seconds)"
    else
      echo "⚠️  Performance test warning (over 5 seconds)"
    fi

    # 정리
    cd "$test_repo"
    git worktree remove "../perf-test-branch" 2>/dev/null || true
    rm -rf "../perf-test-branch" 2>/dev/null || true
    git branch -D "perf-test-branch" 2>/dev/null || true

    echo "Performance test completed."
  '';

  # 개발자 친화적인 테스트 러너
  dev = pkgs.writeShellScript "claude-cli-dev-test" ''
    echo "🔧 Claude CLI Development Test Runner"
    echo "===================================="
    echo ""
    echo "Available test commands:"
    echo "  smoke        - Quick smoke test (< 10 seconds)"
    echo "  unit         - Unit tests (< 1 minute)"
    echo "  integration  - Integration tests (< 5 minutes)"
    echo "  e2e          - End-to-end tests (< 10 minutes)"
    echo "  performance  - Performance benchmarks"
    echo "  all          - Complete test suite (< 20 minutes)"
    echo ""

    case "''${1:-help}" in
      "smoke")
        ${smoke}
        ;;
      "unit")
        ${runTestSuite "Unit" unitTests}
        ;;
      "integration")
        ${runTestSuite "Integration" integrationTests}
        ;;
      "e2e")
        ${runTestSuite "E2E" e2eTests}
        ;;
      "performance")
        ${performance}
        ;;
      "all")
        ${all}
        ;;
      *)
        echo "Usage: nix run .#tests.claude-cli-test-suite.dev [smoke|unit|integration|e2e|performance|all]"
        echo ""
        echo "Examples:"
        echo "  nix run .#tests.claude-cli-test-suite.dev smoke"
        echo "  nix run .#tests.claude-cli-test-suite.dev unit"
        echo "  nix run .#tests.claude-cli-test-suite.dev all"
        ;;
    esac
  '';
}
