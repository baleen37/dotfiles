# Performance Benchmarking Suite for Testing Framework
#
# 테스트 프레임워크의 성능 벤치마킹을 수행하는 모듈입니다.
#
# 주요 기능:
# - Unit/Contract/Integration/E2E 테스트 레이어별 실행 시간 측정
# - 병렬 실행 시나리오의 성능 벤치마킹
# - 메모리 사용량 프로파일링 및 피크 메모리 추적
# - JSON 형식의 벤치마크 결과 생성 및 리포트 자동화
#
# 사용법:
#   nix build .#checks.x86_64-linux.performance-benchmark
#   nix run .#benchmark -- full  # 전체 벤치마크 실행

{
  writeShellScript,
}:

let
  # Import test layers

  # Performance measurement utilities
  # 개별 테스트의 실행 시간과 메모리 사용량을 측정하는 유틸리티 함수
  # 인자:
  #   testName: 테스트 이름 (측정 결과 식별용)
  #   testFn: 실행할 테스트 함수
  # 반환: JSON 형식의 벤치마크 결과 (실행 시간, 메모리 델타, 타임스탬프)
  measureTime =
    testName: testFn:
    writeShellScript "measure-${testName}" ''
      set -euo pipefail

      echo "=== Benchmarking ${testName} ==="

      # Record start time
      START_TIME=$(date +%s.%N)
      START_MEM=$(free -b | grep '^Mem:' | awk '{print $3}' || echo "0")

      # Run the test
      echo "Running ${testName}..."
      if ${testFn}; then
        RESULT="PASS"
      else
        RESULT="FAIL"
      fi

      # Record end time
      END_TIME=$(date +%s.%N)
      END_MEM=$(free -b | grep '^Mem:' | awk '{print $3}' || echo "0")

      # Calculate metrics
      DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)
      MEM_DELTA=$(echo "$END_MEM - $START_MEM" | bc || echo "0")

      # Output results in JSON format for aggregation
      cat << EOF
      {
        "test": "${testName}",
        "result": "$RESULT",
        "duration_seconds": $DURATION,
        "memory_delta_bytes": $MEM_DELTA,
        "timestamp": "$(date -Iseconds)"
      }
      EOF
    '';

  # Benchmark individual test layers
  benchmarkUnitTests = writeShellScript "benchmark-unit-tests" ''
    set -euo pipefail

    echo "=== Unit Tests Performance Benchmark ==="

    # Time nix-unit execution
    START_TIME=$(date +%s.%N)

    # Run unit tests with time measurement
    # Note: nix-unit will auto-detect flake in current directory
    timeout 60s nix-unit \
      --eval-store auto \
      --extra-experimental-features "nix-command flakes" \
      tests.unit.lib-functions \
      tests.unit.test-builders 2>&1 | tee unit_output.log || true

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

    # Count tests run
    TEST_COUNT=$(grep -c "TEST " unit_output.log || echo "0")
    PASS_COUNT=$(grep -c "PASS " unit_output.log || echo "0")
    FAIL_COUNT=$(grep -c "FAIL " unit_output.log || echo "0")

    echo "Unit Tests Results:"
    echo "  Duration: $DURATION seconds"
    echo "  Tests: $TEST_COUNT"
    echo "  Passed: $PASS_COUNT"
    echo "  Failed: $FAIL_COUNT"
    echo "  Tests per second: $(echo "scale=2; $TEST_COUNT / $DURATION" | bc -l)"

    rm -f unit_output.log
  '';

  benchmarkContractTests = writeShellScript "benchmark-contract-tests" ''
    set -euo pipefail

    echo "=== Contract Tests Performance Benchmark ==="

    START_TIME=$(date +%s.%N)

    # Contract tests removed - no longer using BATS framework
    # Using native Nix test framework instead

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

    echo "Contract Tests Results:"
    echo "  Status: Skipped (migrated to Nix test framework)"
    echo "  Duration: $DURATION seconds"
  '';

  benchmarkIntegrationTests = writeShellScript "benchmark-integration-tests" ''
    set -euo pipefail

    echo "=== Integration Tests Performance Benchmark ==="

    START_TIME=$(date +%s.%N)

    # Run native Nix integration tests
    nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"').test-integration 2>&1 | tee integration_output.log || true

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

    TEST_COUNT=$(grep -c "test.*passed\|test.*failed" integration_output.log || echo "3")

    echo "Integration Tests Results:"
    echo "  Duration: $DURATION seconds"
    echo "  Tests: $TEST_COUNT"
    echo "  Tests per second: $(echo "scale=2; $TEST_COUNT / $DURATION" | bc -l)"

    rm -f integration_output.log
  '';

  benchmarkE2ETests = writeShellScript "benchmark-e2e-tests" ''
    set -euo pipefail

    echo "=== E2E Tests Performance Benchmark ==="

    START_TIME=$(date +%s.%N)

    # Run E2E tests (these may take longer)
    timeout 300s nix build \
      .#checks.x86_64-linux.e2e-full-system \
      .#checks.x86_64-linux.e2e-cross-platform \
      --print-build-logs 2>&1 | tee e2e_output.log

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

    echo "E2E Tests Results:"
    echo "  Duration: $DURATION seconds"
    echo "  Tests: 2 (full-system, cross-platform)"

    rm -f e2e_output.log
  '';

  # Parallel execution benchmark
  # 병렬 실행 성능 테스트: 독립적인 테스트 레이어를 동시에 실행하여 전체 실행 시간 측정
  # 목표: 3분 이내 완료 (< 180초)
  # 전략: Unit/Contract 테스트를 백그라운드 프로세스로 병렬 실행
  benchmarkParallelExecution = writeShellScript "benchmark-parallel-execution" ''
    set -euo pipefail

    echo "=== Parallel Execution Performance Benchmark ==="

    # Test parallel execution of independent test layers
    START_TIME=$(date +%s.%N)

    # Run multiple test layers in parallel using background processes
    ${benchmarkUnitTests} &
    UNIT_PID=$!

    ${benchmarkContractTests} &
    CONTRACT_PID=$!

    # Wait for completion and capture exit codes
    wait $UNIT_PID
    UNIT_EXIT=$?

    wait $CONTRACT_PID
    CONTRACT_EXIT=$?

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

    echo "Parallel Execution Results:"
    echo "  Total Duration: $DURATION seconds"
    echo "  Unit Tests Exit Code: $UNIT_EXIT"
    echo "  Contract Tests Exit Code: $CONTRACT_EXIT"

    # Check if we achieved < 3 minute goal (180 seconds)
    if (( $(echo "$DURATION < 180" | bc -l) )); then
      echo "✅ SUCCESS: Parallel execution under 3 minutes"
      exit 0
    else
      echo "❌ FAILED: Parallel execution exceeded 3 minutes"
      exit 1
    fi
  '';

  # Memory usage profiling
  # 메모리 사용량 프로파일링: 테스트 실행 중 메모리 증가량 및 피크 메모리 추적
  # 측정 방식:
  #   1. 테스트 시작 전 기준 메모리 측정
  #   2. 1초 간격으로 현재 메모리 사용량 폴링
  #   3. 피크 메모리 및 델타 계산 (MB 단위)
  benchmarkMemoryUsage = writeShellScript "benchmark-memory-usage" ''
    set -euo pipefail

    echo "=== Memory Usage Performance Benchmark ==="

    # Monitor memory usage during test execution
    START_MEM=$(free -b | grep '^Mem:' | awk '{print $3}')

    # Run a subset of tests while monitoring memory
    timeout 60s ${benchmarkUnitTests} &
    TEST_PID=$!

    # Monitor memory every second and track peak usage
    PEAK_MEM=$START_MEM
    while kill -0 $TEST_PID 2>/dev/null; do
      CURRENT_MEM=$(free -b | grep '^Mem:' | awk '{print $3}')
      if (( CURRENT_MEM > PEAK_MEM )); then
        PEAK_MEM=$CURRENT_MEM
      fi
      sleep 1
    done

    wait $TEST_PID

    # Calculate memory delta and convert to MB for readability
    MEM_DELTA=$(echo "$PEAK_MEM - $START_MEM" | bc)
    MEM_DELTA_MB=$(echo "scale=2; $MEM_DELTA / 1024 / 1024" | bc)

    echo "Memory Usage Results:"
    echo "  Peak Memory Delta: $MEM_DELTA_MB MB"
    echo "  Start Memory: $(echo "scale=2; $START_MEM / 1024 / 1024" | bc) MB"
    echo "  Peak Memory: $(echo "scale=2; $PEAK_MEM / 1024 / 1024" | bc) MB"
  '';

  # Full benchmark suite
  fullBenchmark = writeShellScript "full-benchmark" ''
        set -euo pipefail

        echo "=========================================="
        echo "    COMPREHENSIVE TESTING FRAMEWORK"
        echo "         PERFORMANCE BENCHMARK"
        echo "=========================================="
        echo ""

        # Create results directory
        RESULTS_DIR="benchmark-results-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$RESULTS_DIR"

        # Record system info
        cat > "$RESULTS_DIR/system-info.txt" << EOF
        Hostname: $(hostname)
        OS: $(uname -a)
        CPU: $(nproc) cores
        Memory: $(free -h | grep '^Mem:' | awk '{print $2}')
        Date: $(date -Iseconds)
        EOF

        echo "System Information:"
        cat "$RESULTS_DIR/system-info.txt"
        echo ""

        # Run individual benchmarks
        echo "Running individual layer benchmarks..."
        ${benchmarkUnitTests} 2>&1 | tee "$RESULTS_DIR/unit-benchmark.log"
        ${benchmarkContractTests} 2>&1 | tee "$RESULTS_DIR/contract-benchmark.log"
        ${benchmarkIntegrationTests} 2>&1 | tee "$RESULTS_DIR/integration-benchmark.log"
        ${benchmarkE2ETests} 2>&1 | tee "$RESULTS_DIR/e2e-benchmark.log"

        echo ""
        echo "Running parallel execution benchmark..."
        ${benchmarkParallelExecution} 2>&1 | tee "$RESULTS_DIR/parallel-benchmark.log"

        echo ""
        echo "Running memory usage benchmark..."
        ${benchmarkMemoryUsage} 2>&1 | tee "$RESULTS_DIR/memory-benchmark.log"

        echo ""
        echo "=========================================="
        echo "         BENCHMARK COMPLETE"
        echo "=========================================="
        echo "Results saved to: $RESULTS_DIR/"
        echo ""

        # Generate summary report
        cat > "$RESULTS_DIR/SUMMARY.md" << 'EOF'
    # Testing Framework Performance Benchmark Summary

    ## Overview
    This benchmark measures the performance of the comprehensive testing framework across all test layers.

    ## Test Layers Measured
    - **Unit Tests**: Fast, isolated component tests using nix-unit
    - **Contract Tests**: Interface validation tests using native Nix testing
    - **Integration Tests**: Module interaction tests
    - **E2E Tests**: Complete system workflow tests

    ## Performance Goals
    - **Total Execution Time**: < 3 minutes (parallel)
    - **Memory Usage**: Efficient resource utilization
    - **Test Coverage**: 90% minimum coverage
    - **Reliability**: Consistent execution across platforms

    ## Results
    See individual benchmark log files for detailed metrics.

    ## Optimization Opportunities
    Based on benchmark results, consider:
    1. Parallel test execution optimization
    2. Memory usage reduction strategies
    3. Test isolation improvements
    4. CI/CD pipeline optimization
    EOF

        echo "Summary report generated: $RESULTS_DIR/SUMMARY.md"
  '';

in
{
  # Export benchmark functions
  inherit
    measureTime
    benchmarkUnitTests
    benchmarkContractTests
    benchmarkIntegrationTests
    benchmarkE2ETests
    benchmarkParallelExecution
    benchmarkMemoryUsage
    fullBenchmark
    ;

  # Main benchmark executable
  benchmark = fullBenchmark;

  # Individual layer benchmarks
  unit = benchmarkUnitTests;
  contract = benchmarkContractTests;
  integration = benchmarkIntegrationTests;
  e2e = benchmarkE2ETests;
  parallel = benchmarkParallelExecution;
  memory = benchmarkMemoryUsage;
}
