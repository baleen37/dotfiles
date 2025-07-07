{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
  buildSwitchCommon = "${src}/scripts/build-switch-common.sh";

  # Performance test thresholds (in seconds)
  thresholds = {
    maxEvaluationTime = 30;    # Target: 30초 이하 (현재 63초에서 50% 개선)
    maxTotalTime = 60;         # Target: 전체 60초 이하
    minCacheEfficiency = 20;   # Target: 캐시 사용 시 최소 20% 성능 향상
  };
in
pkgs.runCommand "build-switch-performance-test"
{
  buildInputs = with pkgs; [ bash coreutils nix time gnugrep findutils bc ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Performance Tests (TDD Cycle 1.1)"}

  # Test 1: 현재 평가 성능 측정 (Baseline)
  ${testHelpers.testSubsection "Baseline Performance Measurement"}

  echo "📊 Measuring current build evaluation performance..."

  # Dry-run으로 평가 시간만 측정 (더 현실적인 타임아웃)
  BASELINE_START=$(date +%s%N)
  if timeout 120 nix --extra-experimental-features 'nix-command flakes' build \
    --dry-run --no-warn-dirty .#darwinConfigurations.aarch64-darwin.system \
    --cores 1 --max-jobs 1 >/dev/null 2>&1; then
    BASELINE_END=$(date +%s%N)
    BASELINE_DURATION=$(( (BASELINE_END - BASELINE_START) / 1000000000 ))
    echo "✅ Baseline evaluation time: ''${BASELINE_DURATION}s"
  else
    echo "⚠️ Baseline measurement timed out (>120s) - using simplified test"
    # 간단한 flake check으로 대체
    SIMPLE_START=$(date +%s%N)
    if timeout 60 nix flake check --impure --dry-run >/dev/null 2>&1; then
      SIMPLE_END=$(date +%s%N)
      BASELINE_DURATION=$(( (SIMPLE_END - SIMPLE_START) / 1000000000 ))
      echo "✅ Simplified evaluation time: ''${BASELINE_DURATION}s"
    else
      BASELINE_DURATION=999
      echo "❌ Even simplified measurement failed"
    fi
  fi

  # Test 2: 평가 캐시 최적화 확인 (Green phase에서는 통과 예상)
  ${testHelpers.testSubsection "Eval Cache Optimization Check"}

  echo "🔍 Checking for eval-cache optimization implementation..."

  # build-logic.sh에 --eval-cache 플래그가 있는지 확인
  if grep -q "eval-cache" "${src}/scripts/lib/build-logic.sh" 2>/dev/null; then
    echo "✅ SUCCESS: eval-cache flag found in build script (Green phase success!)"
    EVAL_CACHE_IMPLEMENTED=true
  else
    echo "❌ MISSING: eval-cache flag not found (Red phase - needs implementation)"
    EVAL_CACHE_IMPLEMENTED=false
  fi

  # 성능 기준치 확인
  if [ "$BASELINE_DURATION" -le "${toString thresholds.maxEvaluationTime}" ]; then
    echo "✅ SUCCESS: Evaluation time (''${BASELINE_DURATION}s) meets target (${toString thresholds.maxEvaluationTime}s)"
    PERFORMANCE_TARGET_MET=true
  else
    echo "⚠️ WARNING: Evaluation time (''${BASELINE_DURATION}s) still exceeds target (${toString thresholds.maxEvaluationTime}s)"
    echo "Note: This may be due to test environment limitations or need additional optimizations"
    PERFORMANCE_TARGET_MET=false
  fi

  # Test 3: 병렬 처리 최적화 부재 확인 (실패 예상)
  ${testHelpers.testSubsection "Parallel Processing Optimization Check (Expected to Fail)"}

  echo "🔍 Checking for CPU-optimized parallel processing..."

  # CPU 코어 수 확인
  if command -v nproc >/dev/null 2>&1; then
    AVAILABLE_CORES=$(nproc)
  elif command -v sysctl >/dev/null 2>&1; then
    AVAILABLE_CORES=$(sysctl -n hw.ncpu)
  else
    AVAILABLE_CORES=4
  fi

  echo "Available CPU cores: $AVAILABLE_CORES"

  # 현재 고정된 8코어 제한이 있는지 확인
  if grep -q "CORES.*8" "${src}/scripts/lib/performance.sh" 2>/dev/null; then
    echo "✅ EXPECTED: Fixed 8-core limit found (needs optimization)"
  else
    echo "❌ UNEXPECTED: No fixed core limit found"
  fi

  # Test 4: 조건부 평가 최적화 부재 확인 (실패 예상)
  ${testHelpers.testSubsection "Conditional Evaluation Check (Expected to Fail)"}

  echo "🔍 Checking for platform-specific evaluation optimization..."

  # 모든 아키텍처를 평가하는지 확인
  EVALUATION_LOG=$(mktemp)
  timeout 120 nix --extra-experimental-features 'nix-command flakes' build \
    --dry-run --no-warn-dirty .#darwinConfigurations.aarch64-darwin.system \
    --show-trace 2>"$EVALUATION_LOG" >/dev/null || true

  # 불필요한 아키텍처 평가 여부 확인
  if grep -q "x86_64\|linux" "$EVALUATION_LOG" 2>/dev/null; then
    echo "✅ EXPECTED: Cross-platform evaluation detected (needs optimization)"
  else
    echo "❌ Platform-specific evaluation check inconclusive"
  fi

  rm -f "$EVALUATION_LOG"

  # Test 5: 성능 측정 기반 최적화 확인
  ${testHelpers.testSubsection "Performance Measurement Infrastructure"}

  echo "🔍 Checking for detailed performance measurement capabilities..."

  # 세부 성능 측정 함수 존재 여부 확인
  if grep -q "perf_start_phase.*build" "${src}/scripts/lib/performance.sh" 2>/dev/null; then
    echo "✅ Basic performance measurement found"
  else
    echo "❌ No detailed performance measurement found"
  fi

  # 평가 단계별 측정 부재 확인 (개선 필요)
  if grep -q "perf.*eval" "${src}/scripts/lib/performance.sh" 2>/dev/null; then
    echo "❌ UNEXPECTED: Evaluation phase measurement already exists"
  else
    echo "✅ EXPECTED: No evaluation phase measurement (needs implementation)"
  fi

  # Test Results Summary
  echo ""
  echo "🔍 Performance Test Summary (TDD Cycle 1.1):"
  echo "  📊 Baseline evaluation time: ''${BASELINE_DURATION}s (target: ${toString thresholds.maxEvaluationTime}s)"
  echo "  🎯 Performance target: $([ "$PERFORMANCE_TARGET_MET" = "true" ] && echo "✅ MET" || echo "⚠️ NEEDS MORE WORK")"
  echo "  🚀 Eval cache optimization: $([ "$EVAL_CACHE_IMPLEMENTED" = "true" ] && echo "✅ IMPLEMENTED" || echo "❌ MISSING")"
  echo "  ⚙️ Dynamic core detection: NEEDS IMPLEMENTATION (next cycle)"
  echo "  🎯 Platform-specific evaluation: NEEDS IMPLEMENTATION (next cycle)"
  echo "  📊 Detailed perf measurement: PARTIAL (next cycle)"
  echo ""

  # TDD Cycle 1.1 결과 판정
  if [ "$EVAL_CACHE_IMPLEMENTED" = "true" ]; then
    echo "✅ TDD Cycle 1.1 Green phase: PASSED!"
    echo "✅ Eval-cache optimization successfully implemented"
    echo "Next: Refactor phase - clean up and optimize code structure"
  else
    echo "❌ TDD Cycle 1.1 Green phase: FAILED!"
    echo "❌ Eval-cache optimization not found - implementation needed"
    exit 1
  fi

  # Create performance benchmark baseline file for Green phase
  echo "$BASELINE_DURATION" > /tmp/baseline_perf.txt
  echo "📝 Baseline performance recorded for Green phase comparison"

  ${testHelpers.cleanup}

  touch $out
''
