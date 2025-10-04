# Performance Benchmarks for Comprehensive Testing Framework
# Measures execution time and resource usage for each test layer

{
  lib,
  stdenv,
  writeShellScript,
  time,
  gnugrep,
  coreutils,
}:

let
  # Import test layers
  unitTests = import ../unit/nix/test-lib-functions.nix;
  contractTests = import ../contract/flake-contracts/test-flake-outputs.nix;

  # Performance measurement utilities
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
    timeout 60s nix-unit \
      --flake "${toString ./.}#" \
      --eval-store auto \
      --extra-experimental-features "nix-command flakes" \
      tests.unit.lib-functions \
      tests.unit.test-builders \
      tests.unit.coverage-system 2>&1 | tee unit_output.log

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

    # Run BATS contract tests
    timeout 120s bats \
      tests/contract/test-runner-contract.bats \
      tests/contract/test-coverage-contract.bats \
      tests/contract/test-platform-contract.bats \
      --timing --print-output-on-failure 2>&1 | tee contract_output.log

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

    # Parse BATS timing output
    TEST_COUNT=$(grep -c "✓\|✗" contract_output.log || echo "0")

    echo "Contract Tests Results:"
    echo "  Duration: $DURATION seconds"
    echo "  Tests: $TEST_COUNT"
    echo "  Tests per second: $(echo "scale=2; $TEST_COUNT / $DURATION" | bc -l)"

    rm -f contract_output.log
  '';

  benchmarkIntegrationTests = writeShellScript "benchmark-integration-tests" ''
    set -euo pipefail

    echo "=== Integration Tests Performance Benchmark ==="

    START_TIME=$(date +%s.%N)

    # Run integration tests
    timeout 180s bats \
      tests/integration/build-integration/test-build-workflow.bats \
      tests/integration/platform-integration/test-cross-platform.bats \
      --timing --print-output-on-failure 2>&1 | tee integration_output.log

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc -l)

    TEST_COUNT=$(grep -c "✓\|✗" integration_output.log || echo "0")

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

    # Wait for completion
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

    # Check if we achieved < 3 minute goal
    if (( $(echo "$DURATION < 180" | bc -l) )); then
      echo "✅ SUCCESS: Parallel execution under 3 minutes"
      exit 0
    else
      echo "❌ FAILED: Parallel execution exceeded 3 minutes"
      exit 1
    fi
  '';

  # Memory usage profiling
  benchmarkMemoryUsage = writeShellScript "benchmark-memory-usage" ''
    set -euo pipefail

    echo "=== Memory Usage Performance Benchmark ==="

    # Monitor memory usage during test execution
    START_MEM=$(free -b | grep '^Mem:' | awk '{print $3}')

    # Run a subset of tests while monitoring memory
    timeout 60s ${benchmarkUnitTests} &
    TEST_PID=$!

    # Monitor memory every second
    PEAK_MEM=$START_MEM
    while kill -0 $TEST_PID 2>/dev/null; do
      CURRENT_MEM=$(free -b | grep '^Mem:' | awk '{print $3}')
      if (( CURRENT_MEM > PEAK_MEM )); then
        PEAK_MEM=$CURRENT_MEM
      fi
      sleep 1
    done

    wait $TEST_PID

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
    - **Contract Tests**: Interface validation tests using BATS
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
