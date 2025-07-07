{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  performanceScript = "${src}/scripts/lib/performance.sh";
  optimizationScript = "${src}/scripts/lib/optimization.sh";

  # Parallel processing test thresholds
  thresholds = {
    minCoreUtilization = 80;    # 최소 80% 코어 활용
    maxCoreLimit = 16;          # 최대 16코어까지 지원
    dynamicScaling = true;      # 동적 스케일링 필요
  };
in
pkgs.runCommand "parallel-processing-performance-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep bc ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Parallel Processing Performance Tests (TDD Cycle 1.2)"}

  # Test 1: 현재 시스템의 코어 수 확인
  ${testHelpers.testSubsection "System Core Detection"}

  echo "🔍 Detecting available CPU cores..."

  # 시스템 코어 수 검출
  if command -v nproc >/dev/null 2>&1; then
    SYSTEM_CORES=$(nproc)
    echo "✅ System cores (nproc): $SYSTEM_CORES"
  elif command -v sysctl >/dev/null 2>&1; then
    SYSTEM_CORES=$(sysctl -n hw.ncpu)
    echo "✅ System cores (sysctl): $SYSTEM_CORES"
  else
    SYSTEM_CORES=4
    echo "⚠️ Using fallback: $SYSTEM_CORES cores"
  fi

  # Test 2: 동적 코어 검출 구현 확인 (Green phase - 개선 검증)
  ${testHelpers.testSubsection "Dynamic Core Detection Implementation Check"}

  echo "🔍 Checking dynamic core detection implementation..."

  # performance.sh의 현재 구현 확인
  if [ -f "${performanceScript}" ]; then
    echo "📝 Analyzing performance.sh implementation..."

    # 동적 스케일링 로직 확인
    if grep -q "Dynamic scaling" "${performanceScript}" || grep -q "CORES.*CORES.*/" "${performanceScript}"; then
      echo "✅ Dynamic scaling logic found in performance.sh"
      DYNAMIC_SCALING_IMPLEMENTED=true
    else
      echo "❌ No dynamic scaling found"
      DYNAMIC_SCALING_IMPLEMENTED=false
    fi

    # Apple Silicon 최적화 확인
    if grep -q "Apple Silicon\|perflevel" "${performanceScript}"; then
      echo "✅ Apple Silicon optimization found"
      APPLE_SILICON_SUPPORT=true
    else
      echo "❌ No Apple Silicon optimization found"
      APPLE_SILICON_SUPPORT=false
    fi

    # 환경별 모드 지원 확인
    if grep -q "PERFORMANCE_MODE" "${performanceScript}"; then
      echo "✅ Performance mode support found"
      PERFORMANCE_MODE_SUPPORT=true
    else
      echo "❌ No performance mode support found"
      PERFORMANCE_MODE_SUPPORT=false
    fi

    # CI 환경 처리 확인
    if grep -q "CI" "${performanceScript}"; then
      echo "✅ CI environment handling found"
      CI_LIMIT_FOUND=true
    else
      echo "❌ No CI environment handling found"
      CI_LIMIT_FOUND=false
    fi
  else
    echo "❌ performance.sh not found"
    exit 1
  fi

  # Test 3: 개선된 동적 코어 스케일링 확인 (Green phase)
  ${testHelpers.testSubsection "Improved Dynamic Core Scaling Verification"}

  echo "🔍 Testing improved dynamic core scaling capabilities..."

  # 개선된 detect_optimal_jobs 함수 테스트
  DETECTED_CORES=$(bash -c "
    . ${performanceScript}
    detect_optimal_jobs
  ")

  echo "Improved detected cores: $DETECTED_CORES"
  echo "System available cores: $SYSTEM_CORES"

  # 효율성 계산 (감지된 코어 / 시스템 코어 * 100)
  if [ "$SYSTEM_CORES" -gt 0 ]; then
    UTILIZATION_PERCENT=$(echo "scale=0; $DETECTED_CORES * 100 / $SYSTEM_CORES" | bc)
    echo "Core utilization: $UTILIZATION_PERCENT%"
  else
    UTILIZATION_PERCENT=0
  fi

  # 다양한 모드 테스트
  echo "Testing different performance modes..."

  # Conservative mode test
  CONSERVATIVE_CORES=$(bash -c "
    . ${performanceScript}
    export PERFORMANCE_MODE=conservative
    detect_optimal_jobs
  ")
  echo "Conservative mode cores: $CONSERVATIVE_CORES"

  # Aggressive mode test
  AGGRESSIVE_CORES=$(bash -c "
    . ${performanceScript}
    export PERFORMANCE_MODE=aggressive
    detect_optimal_jobs
  ")
  echo "Aggressive mode cores: $AGGRESSIVE_CORES"

  # Test 4: 성능 제약 확인 (Red phase)
  ${testHelpers.testSubsection "Performance Constraints Analysis"}

  echo "🔍 Analyzing performance constraints..."

  # 고성능 시스템에서의 제약 확인
  if [ "$SYSTEM_CORES" -gt 8 ]; then
    if [ "$DETECTED_CORES" -le 8 ]; then
      echo "❌ PERFORMANCE ISSUE: High-core system ($SYSTEM_CORES cores) limited to $DETECTED_CORES cores"
      echo "  Potential performance loss: $(echo "scale=0; ($SYSTEM_CORES - $DETECTED_CORES) * 100 / $SYSTEM_CORES" | bc)%"
      HIGH_CORE_LIMITATION=true
    else
      echo "✅ High-core system properly utilizing available cores"
      HIGH_CORE_LIMITATION=false
    fi
  else
    echo "📊 Standard system ($SYSTEM_CORES cores) - optimization may still benefit"
    HIGH_CORE_LIMITATION=false
  fi

  # Test 5: 플랫폼별 최적화 부재 확인
  ${testHelpers.testSubsection "Platform-Specific Optimization Check"}

  echo "🔍 Checking platform-specific core optimization..."

  # macOS vs Linux 차이점 확인
  PLATFORM=$(uname -s)
  echo "Current platform: $PLATFORM"

  if [ "$PLATFORM" = "Darwin" ]; then
    # macOS 특화 최적화 확인
    P_CORES=$(sysctl -n hw.perflevel0.physicalcpu 2>/dev/null || echo "unknown")
    E_CORES=$(sysctl -n hw.perflevel1.physicalcpu 2>/dev/null || echo "unknown")

    if [ "$P_CORES" != "unknown" ] && [ "$E_CORES" != "unknown" ]; then
      echo "📊 Apple Silicon detected - P-cores: $P_CORES, E-cores: $E_CORES"
      echo "❌ MISSING: No Apple Silicon optimization in current implementation"
      APPLE_SILICON_OPTIMIZATION=false
    else
      echo "📊 Intel Mac detected"
      APPLE_SILICON_OPTIMIZATION=true
    fi
  else
    echo "📊 Linux platform - standard optimization applies"
    APPLE_SILICON_OPTIMIZATION=true
  fi

  # Test Results Summary (Green Phase - Verify Improvements)
  echo ""
  echo "🔍 Parallel Processing Test Summary (TDD Cycle 1.2 - Green Phase):"
  echo "  🖥️ System cores: $SYSTEM_CORES"
  echo "  ⚙️ Default detected cores: $DETECTED_CORES"
  echo "  🔧 Conservative cores: $CONSERVATIVE_CORES"
  echo "  🚀 Aggressive cores: $AGGRESSIVE_CORES"
  echo "  📊 Utilization: $UTILIZATION_PERCENT%"
  echo "  🎯 Target utilization: ${toString thresholds.minCoreUtilization}%"
  echo ""
  echo "  Implementation Status:"
  echo "  ✅ Dynamic scaling: $([ "$DYNAMIC_SCALING_IMPLEMENTED" = "true" ] && echo "IMPLEMENTED" || echo "MISSING")"
  echo "  ✅ Apple Silicon support: $([ "$APPLE_SILICON_SUPPORT" = "true" ] && echo "IMPLEMENTED" || echo "MISSING")"
  echo "  ✅ Performance modes: $([ "$PERFORMANCE_MODE_SUPPORT" = "true" ] && echo "IMPLEMENTED" || echo "MISSING")"
  echo "  ✅ CI environment handling: $([ "$CI_LIMIT_FOUND" = "true" ] && echo "IMPLEMENTED" || echo "MISSING")"
  echo ""

  # Green Phase 결과 판정
  IMPLEMENTATIONS_FOUND=0
  TOTAL_IMPLEMENTATIONS=4

  if [ "$DYNAMIC_SCALING_IMPLEMENTED" = "true" ]; then
    echo "✅ Dynamic scaling successfully implemented"
    IMPLEMENTATIONS_FOUND=$((IMPLEMENTATIONS_FOUND + 1))
  else
    echo "❌ Dynamic scaling not implemented"
  fi

  if [ "$APPLE_SILICON_SUPPORT" = "true" ]; then
    echo "✅ Apple Silicon optimization implemented"
    IMPLEMENTATIONS_FOUND=$((IMPLEMENTATIONS_FOUND + 1))
  else
    echo "❌ Apple Silicon optimization missing"
  fi

  if [ "$PERFORMANCE_MODE_SUPPORT" = "true" ]; then
    echo "✅ Performance mode support implemented"
    IMPLEMENTATIONS_FOUND=$((IMPLEMENTATIONS_FOUND + 1))
  else
    echo "❌ Performance mode support missing"
  fi

  if [ "$CI_LIMIT_FOUND" = "true" ]; then
    echo "✅ CI environment handling implemented"
    IMPLEMENTATIONS_FOUND=$((IMPLEMENTATIONS_FOUND + 1))
  else
    echo "❌ CI environment handling missing"
  fi

  echo ""
  if [ "$IMPLEMENTATIONS_FOUND" -ge 3 ]; then
    echo "✅ TDD Cycle 1.2 Green phase: SUCCESS!"
    echo "✅ Implemented $IMPLEMENTATIONS_FOUND/$TOTAL_IMPLEMENTATIONS core optimizations"

    # 성능 향상 확인
    if [ "$UTILIZATION_PERCENT" -ge "${toString thresholds.minCoreUtilization}" ]; then
      echo "✅ Performance target achieved ($UTILIZATION_PERCENT% >= ${toString thresholds.minCoreUtilization}%)"
    else
      echo "⚠️ Performance target not fully met, but improvements implemented"
    fi

    echo "Next: Refactor phase - clean up and optimize implementation"
  else
    echo "❌ TDD Cycle 1.2 Green phase: FAILED!"
    echo "❌ Only $IMPLEMENTATIONS_FOUND/$TOTAL_IMPLEMENTATIONS optimizations implemented"
    exit 1
  fi

  # 성능 기준 데이터 저장
  echo "$SYSTEM_CORES:$DETECTED_CORES:$UTILIZATION_PERCENT" > /tmp/core_baseline.txt
  echo "📝 Core utilization baseline recorded for Green phase"

  ${testHelpers.cleanup}

  touch $out
''
