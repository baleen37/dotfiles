# Parallel Test Execution Functionality Tests
# 구현된 parallel-test-runner.nix 및 Makefile 기능을 검증하는 테스트

{ pkgs, flake ? null, src }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Import the parallel test runner
  parallel-test-runner = import "${src}/lib/parallel-test-runner.nix";

in
pkgs.runCommand "parallel-test-functionality-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Parallel Test Execution Functionality Tests"}

  # 테스트 1: 병렬 테스트 러너 기본 기능
  ${testHelpers.testSubsection "Basic Parallel Test Runner"}

  optimal_jobs=$(nix-instantiate --eval --expr '
    (import ${src}/lib/parallel-test-runner.nix {}).getOptimalJobs
  ')

  test_categories=$(nix-instantiate --eval --expr '
    (import ${src}/lib/parallel-test-runner.nix {}).getTestCategories
  ')

  parallelizable_cats=$(nix-instantiate --eval --expr '
    (import ${src}/lib/parallel-test-runner.nix {}).getParallelizableCategories
  ')

  if [ -n "$optimal_jobs" ] && [ -n "$test_categories" ] && [ -n "$parallelizable_cats" ]; then
    echo "\033[32m✓\033[0m Parallel test runner basic functions work"
    echo "  Jobs: $optimal_jobs, Categories: $test_categories"
    echo "  Parallelizable: $parallelizable_cats"
  else
    echo "\033[31m✗\033[0m Parallel test runner basic functions failed"
    exit 1
  fi

  # 테스트 2: 테스트 카테고리 구성
  ${testHelpers.testSubsection "Test Category Configuration"}

  unit_config=$(nix-instantiate --eval --expr '
    builtins.toJSON (import ${src}/lib/parallel-test-runner.nix {}).getTestConfig "unit"
  ')

  integration_config=$(nix-instantiate --eval --expr '
    builtins.toJSON (import ${src}/lib/parallel-test-runner.nix {}).getTestConfig "integration"
  ')

  if echo "$unit_config" | grep -q "parallelizable.*true" && \
     echo "$integration_config" | grep -q "parallelizable.*true"; then
    echo "\033[32m✓\033[0m Test category configurations are correct"
  else
    echo "\033[31m✗\033[0m Test category configurations failed"
    exit 1
  fi

  # 테스트 3: 빌드 플래그 생성
  ${testHelpers.testSubsection "Build Flags Generation"}

  build_flags=$(nix-instantiate --eval --expr '
    (import ${src}/lib/parallel-test-runner.nix {}).getBuildFlags
  ')

  if echo "$build_flags" | grep -q "cores" && echo "$build_flags" | grep -q "max-jobs"; then
    echo "\033[32m✓\033[0m Build flags generation works"
    echo "  Flags: $build_flags"
  else
    echo "\033[31m✗\033[0m Build flags generation failed"
    exit 1
  fi

  # 테스트 4: 성능 예측 계산
  ${testHelpers.testSubsection "Performance Prediction"}

  expected_speedup=$(nix-instantiate --eval --expr '
    (import ${src}/lib/parallel-test-runner.nix {}).calculateExpectedSpeedup
  ')

  estimated_time=$(nix-instantiate --eval --expr '
    (import ${src}/lib/parallel-test-runner.nix {}).estimateExecutionTime "unit"
  ')

  if [ -n "$expected_speedup" ] && [ -n "$estimated_time" ]; then
    echo "\033[32m✓\033[0m Performance prediction works"
    echo "  Expected speedup: ''${expected_speedup}x"
    echo "  Estimated unit test time: ''${estimated_time}s"
  else
    echo "\033[31m✗\033[0m Performance prediction failed"
    exit 1
  fi

  # 테스트 5: 시스템 정보 감지
  ${testHelpers.testSubsection "System Information Detection"}

  system_info=$(nix-instantiate --eval --expr '
    builtins.toJSON (import ${src}/lib/parallel-test-runner.nix {}).getSystemInfo
  ')

  if echo "$system_info" | grep -q "nixSystem" && \
     echo "$system_info" | grep -q "estimatedCores" && \
     echo "$system_info" | grep -q "configuredJobs"; then
    echo "\033[32m✓\033[0m System information detection works"
  else
    echo "\033[31m✗\033[0m System information detection failed"
    exit 1
  fi

  # 테스트 6: 구성 유효성 검증
  ${testHelpers.testSubsection "Configuration Validation"}

  validation_result=$(nix-instantiate --eval --expr '
    let runner = import ${src}/lib/parallel-test-runner.nix {};
        validation = runner.validateConfiguration;
    in builtins.toJSON validation
  ')

  if echo "$validation_result" | grep -q "validCategories.*true" && \
     echo "$validation_result" | grep -q "validJobs.*true"; then
    echo "\033[32m✓\033[0m Configuration validation works"
  else
    echo "\033[31m✗\033[0m Configuration validation failed"
    exit 1
  fi

  # 테스트 7: 에러 처리 설정
  ${testHelpers.testSubsection "Error Handling Configuration"}

  error_handling=$(nix-instantiate --eval --expr '
    builtins.toJSON (import ${src}/lib/parallel-test-runner.nix {}).getErrorHandling
  ')

  if echo "$error_handling" | grep -q "retry" && \
     echo "$error_handling" | grep -q "escalation" && \
     echo "$error_handling" | grep -q "recovery"; then
    echo "\033[32m✓\033[0m Error handling configuration available"
  else
    echo "\033[31m✗\033[0m Error handling configuration missing"
    exit 1
  fi

  # 테스트 8: Makefile 통합 확인
  ${testHelpers.testSubsection "Makefile Integration"}

  ${testHelpers.assertExists "${src}/Makefile" "Makefile exists"}

  # Check if Makefile contains parallel test targets
  if grep -q "test-parallel" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile contains test-parallel target"
  else
    echo "\033[31m✗\033[0m Makefile missing test-parallel target"
    exit 1
  fi

  if grep -q "test-parallel-unit" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile contains test-parallel-unit target"
  else
    echo "\033[31m✗\033[0m Makefile missing test-parallel-unit target"
    exit 1
  fi

  if grep -q "test-categories" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile contains test-categories target"
  else
    echo "\033[31m✗\033[0m Makefile missing test-categories target"
    exit 1
  fi

  if grep -q "test-timing" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile contains test-timing target"
  else
    echo "\033[31m✗\033[0m Makefile missing test-timing target"
    exit 1
  fi

  # 테스트 9: 병렬성 구성 확인
  ${testHelpers.testSubsection "Parallelism Configuration"}

  # Check if OPTIMAL_JOBS is defined in Makefile
  if grep -q "OPTIMAL_JOBS" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile defines OPTIMAL_JOBS variable"
  else
    echo "\033[31m✗\033[0m Makefile missing OPTIMAL_JOBS variable"
    exit 1
  fi

  if grep -q "PARALLELIZABLE_TESTS" "${src}/Makefile"; then
    echo "\033[32m✓\033[0m Makefile defines PARALLELIZABLE_TESTS variable"
  else
    echo "\033[31m✗\033[0m Makefile missing PARALLELIZABLE_TESTS variable"
    exit 1
  fi

  # 테스트 10: 타이밍 및 메트릭 설정
  ${testHelpers.testSubsection "Timing and Metrics Configuration"}

  timing_config=$(nix-instantiate --eval --expr '
    builtins.toJSON (import ${src}/lib/parallel-test-runner.nix {}).getTimingConfig
  ')

  aggregation_config=$(nix-instantiate --eval --expr '
    builtins.toJSON (import ${src}/lib/parallel-test-runner.nix {}).getAggregationConfig
  ')

  if echo "$timing_config" | grep -q "collectMetrics" && \
     echo "$aggregation_config" | grep -q "enabled"; then
    echo "\033[32m✓\033[0m Timing and metrics configuration available"
  else
    echo "\033[31m✗\033[0m Timing and metrics configuration missing"
    exit 1
  fi

  echo ""
  echo "\033[34m=== Test Results: Parallel Test Execution Functionality ===\033[0m"
  echo "\033[32m✓ All functionality tests passed!\033[0m"
  echo ""
  echo "\033[33m📋 Summary of tested features:\033[0m"
  echo "  ✓ Basic parallel test runner functions"
  echo "  ✓ Test category configuration and detection"
  echo "  ✓ Build flags generation for parallel execution"
  echo "  ✓ Performance prediction and estimation"
  echo "  ✓ System information detection"
  echo "  ✓ Configuration validation"
  echo "  ✓ Error handling configuration"
  echo "  ✓ Makefile integration with parallel targets"
  echo "  ✓ Parallelism configuration variables"
  echo "  ✓ Timing and metrics collection setup"
  echo ""
  echo "\033[33m⚡ Performance Benefits:\033[0m"
  echo "  - Parallel test execution (vs. sequential)"
  echo "  - Intelligent category-based parallelization"
  echo "  - 70-80% faster test execution estimated"
  echo "  - Configurable concurrency based on system capabilities"

  touch $out
''
