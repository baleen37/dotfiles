#!/usr/bin/env bash
# 동적 GUI 앱 링킹 시스템 성능 테스트
# 대량 앱 처리 성능, 메모리 사용량, 확장성 테스트

set -euo pipefail

# 성능 테스트 설정
PERF_TEST_DIR="/tmp/nix-app-performance-test"
FAKE_NIX_STORE="$PERF_TEST_DIR/fake-nix-store"
FAKE_HOME_APPS="$PERF_TEST_DIR/fake-home/Applications"
FAKE_PROFILE="$PERF_TEST_DIR/fake-profile"

# 성능 결과 저장
declare -A PERFORMANCE_METRICS

# 시간 측정 함수 (크로스 플랫폼)
get_timestamp() {
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import time; print(time.time())"
    else
        date +%s.%N
    fi
}

# 메모리 사용량 측정
get_memory_usage() {
    if command -v ps >/dev/null 2>&1; then
        ps -o pid,rss,vsz,comm -p $$ 2>/dev/null | tail -1 | awk '{print $2}'
    else
        echo "0"
    fi
}

# 성능 로깅
log_performance() {
    echo "⚡ [PERF] $*"
}

log_metric() {
    local metric_name="$1"
    local value="$2"
    echo "📊 [METRIC] $metric_name: $value"
    PERFORMANCE_METRICS["$metric_name"]="$value"
}

# 대량 앱 환경 생성
setup_large_scale_test() {
    local app_count="$1"
    log_performance "Setting up test environment with $app_count apps..."

    rm -rf "$PERF_TEST_DIR"
    mkdir -p "$FAKE_NIX_STORE" "$FAKE_HOME_APPS" "$FAKE_PROFILE"

    # 1. 전용 처리 앱들
    mkdir -p "$FAKE_NIX_STORE/karabiner-elements-14.13.0/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements.app"
    mkdir -p "$FAKE_NIX_STORE/wezterm-unstable-2025-08-14/Applications/WezTerm.app"

    # 2. 대량 GUI 앱들 생성 (Applications 폴더)
    for i in $(seq 1 $((app_count / 2))); do
        local app_dir="$FAKE_NIX_STORE/app-$i-1.0.0/Applications/TestApp$i.app"
        mkdir -p "$app_dir"
        echo "Test App $i" > "$app_dir/info.txt"
    done

    # 3. Profile 앱들
    for i in $(seq $((app_count / 2 + 1)) $app_count); do
        local app_dir="$FAKE_PROFILE/Applications/ProfileApp$i.app"
        mkdir -p "$app_dir"
        echo "Profile App $i" > "$app_dir/info.txt"
    done

    # 4. 제외되어야 할 Qt 도구들 (성능 테스트용)
    for i in {1..10}; do
        mkdir -p "$FAKE_NIX_STORE/qttools-$i-bin/bin/QTool$i.app"
        echo "Qt Tool $i" > "$FAKE_NIX_STORE/qttools-$i-bin/bin/QTool$i.app/info.txt"
    done

    # 5. 깊은 경로 구조 (검색 성능 테스트)
    for i in {1..20}; do
        mkdir -p "$FAKE_NIX_STORE/deep/nested/path/level$i/more/nesting"
    done

    log_performance "Test environment ready: $app_count apps created"
}

# 성능 테스트 1: 확장성 테스트 (앱 수 증가에 따른 성능)
test_scalability() {
    log_performance "Testing scalability with increasing number of apps..."

    local app_counts=(10 50 100 200 500)
    local scalability_results=()

    source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

    for count in "${app_counts[@]}"; do
        setup_large_scale_test "$count"

        local start_time=$(get_timestamp)
        local start_memory=$(get_memory_usage)

        link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1

        local end_time=$(get_timestamp)
        local end_memory=$(get_memory_usage)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        local memory_diff=$((end_memory - start_memory))

        # 링크된 앱 수 확인
        local linked_count=$(find "$FAKE_HOME_APPS" -name "*.app" -type l | wc -l)

        scalability_results+=("$count apps: ${duration}s, ${memory_diff}KB memory, $linked_count linked")
        log_metric "scalability_${count}_time" "$duration"
        log_metric "scalability_${count}_memory" "$memory_diff"
        log_metric "scalability_${count}_linked" "$linked_count"

        # 성능 기준 확인 (500개 앱 기준 10초 이내 - 현실적 기준)
        if [ "$count" -eq 500 ] && (( $(echo "$duration > 10.0" | bc -l) )); then
            log_performance "❌ Scalability FAIL: 500 apps took ${duration}s (>10.0s limit)"
            return 1
        fi
    done

    log_performance "✅ Scalability test results:"
    for result in "${scalability_results[@]}"; do
        log_performance "   $result"
    done

    return 0
}

# 성능 테스트 2: 중복 실행 성능 (캐싱 효과)
test_caching_performance() {
    log_performance "Testing caching performance with repeated executions..."

    setup_large_scale_test 100

    source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

    local execution_times=()

    # 첫 실행 (콜드 스타트)
    local start_time=$(get_timestamp)
    link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1
    local end_time=$(get_timestamp)
    local first_run_time=$(echo "$end_time - $start_time" | bc -l)
    execution_times+=("$first_run_time")

    # 5번 추가 실행 (웜 스타트)
    for i in {2..6}; do
        start_time=$(get_timestamp)
        link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1
        end_time=$(get_timestamp)
        local run_time=$(echo "$end_time - $start_time" | bc -l)
        execution_times+=("$run_time")
    done

    # 캐싱 효과 분석
    local avg_warm_time=0
    for i in {1..5}; do
        avg_warm_time=$(echo "$avg_warm_time + ${execution_times[$i]}" | bc -l)
    done
    avg_warm_time=$(echo "scale=3; $avg_warm_time / 5" | bc -l)

    local caching_improvement=$(echo "scale=2; ($first_run_time - $avg_warm_time) / $first_run_time * 100" | bc -l)

    log_metric "first_run_time" "$first_run_time"
    log_metric "avg_warm_time" "$avg_warm_time"
    log_metric "caching_improvement" "${caching_improvement}%"

    # 캐싱 효과가 있는지 확인 (20% 이상 개선)
    if (( $(echo "$caching_improvement > 20" | bc -l) )); then
        log_performance "✅ Caching performance PASS: ${caching_improvement}% improvement"
        return 0
    else
        log_performance "❌ Caching performance FAIL: only ${caching_improvement}% improvement"
        return 1
    fi
}

# 성능 테스트 3: 메모리 효율성 테스트
test_memory_efficiency() {
    log_performance "Testing memory efficiency with various workloads..."

    local memory_results=()

    source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

    # 다양한 크기의 워크로드 테스트
    local workloads=(50 100 200 500)

    for workload in "${workloads[@]}"; do
        setup_large_scale_test "$workload"

        # 베이스라인 메모리
        local baseline_memory=$(get_memory_usage)

        # 실행 중 메모리 (백그라운드에서 측정)
        link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1 &
        local link_pid=$!

        sleep 0.5  # 실행 중간에 측정
        local peak_memory=$(get_memory_usage)

        wait $link_pid

        # 실행 후 메모리
        local final_memory=$(get_memory_usage)

        local memory_usage=$((peak_memory - baseline_memory))
        local memory_per_app=$((memory_usage / workload))

        memory_results+=("$workload apps: ${memory_usage}KB total, ${memory_per_app}KB/app")

        log_metric "memory_${workload}_total" "$memory_usage"
        log_metric "memory_${workload}_per_app" "$memory_per_app"

        # 메모리 효율성 기준 (앱당 100KB 이하)
        if [ $memory_per_app -gt 100 ]; then
            log_performance "❌ Memory efficiency FAIL: $memory_per_app KB/app (>100KB limit)"
            return 1
        fi
    done

    log_performance "✅ Memory efficiency test results:"
    for result in "${memory_results[@]}"; do
        log_performance "   $result"
    done

    return 0
}

# 성능 테스트 4: 동시성 테스트 (병렬 실행)
test_concurrency_safety() {
    log_performance "Testing concurrency safety with parallel executions..."

    setup_large_scale_test 100

    source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

    # 5개 프로세스 병렬 실행
    local pids=()
    local temp_dirs=()

    for i in {1..5}; do
        local temp_apps="$PERF_TEST_DIR/concurrent-$i/Applications"
        temp_dirs+=("$temp_apps")
        mkdir -p "$temp_apps"

        link_nix_apps "$temp_apps" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1 &
        pids+=($!)
    done

    # 모든 프로세스 대기
    local failed_processes=0
    for pid in "${pids[@]}"; do
        if ! wait $pid; then
            ((failed_processes++))
        fi
    done

    # 결과 검증
    local successful_links=0
    for temp_dir in "${temp_dirs[@]}"; do
        local link_count=$(find "$temp_dir" -name "*.app" -type l 2>/dev/null | wc -l)
        if [ "$link_count" -gt 0 ]; then
            ((successful_links++))
        fi
    done

    log_metric "concurrent_processes" "${#pids[@]}"
    log_metric "failed_processes" "$failed_processes"
    log_metric "successful_concurrent_links" "$successful_links"

    if [ $failed_processes -eq 0 ] && [ $successful_links -eq ${#temp_dirs[@]} ]; then
        log_performance "✅ Concurrency safety PASS: All $successful_links parallel executions successful"
        return 0
    else
        log_performance "❌ Concurrency safety FAIL: $failed_processes failures, $successful_links successes"
        return 1
    fi
}

# 성능 테스트 5: 극한 부하 테스트
test_stress_conditions() {
    log_performance "Testing under stress conditions (1000+ apps, deep nesting)..."

    # 극한 환경 설정
    setup_large_scale_test 1000

    # 매우 깊은 네스팅 구조 추가
    for i in {1..50}; do
        mkdir -p "$FAKE_NIX_STORE/$(printf 'deep%.0s/' {1..10})level$i"
    done

    source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

    local start_time=$(get_timestamp)
    local start_memory=$(get_memory_usage)

    # 타임아웃 설정 (30초)
    timeout 30s link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" >/dev/null 2>&1
    local exit_code=$?

    local end_time=$(get_timestamp)
    local end_memory=$(get_memory_usage)

    local duration=$(echo "$end_time - $start_time" | bc -l)
    local memory_usage=$((end_memory - start_memory))
    local linked_count=$(find "$FAKE_HOME_APPS" -name "*.app" -type l 2>/dev/null | wc -l)

    log_metric "stress_duration" "$duration"
    log_metric "stress_memory" "$memory_usage"
    log_metric "stress_linked_count" "$linked_count"

    if [ $exit_code -eq 0 ] && [ "$linked_count" -gt 500 ] && (( $(echo "$duration < 30" | bc -l) )); then
        log_performance "✅ Stress test PASS: $linked_count apps linked in ${duration}s"
        return 0
    else
        log_performance "❌ Stress test FAIL: exit=$exit_code, linked=$linked_count, time=${duration}s"
        return 1
    fi
}

# 모든 성능 테스트 실행
run_performance_tests() {
    echo "🚀 Running Dynamic GUI App Linking Performance Tests"
    echo "===================================================="

    local failed_tests=0
    local total_tests=5

    echo ""
    if ! test_scalability; then
        ((failed_tests++))
    fi

    echo ""
    if ! test_caching_performance; then
        ((failed_tests++))
    fi

    echo ""
    if ! test_memory_efficiency; then
        ((failed_tests++))
    fi

    echo ""
    if ! test_concurrency_safety; then
        ((failed_tests++))
    fi

    echo ""
    if ! test_stress_conditions; then
        ((failed_tests++))
    fi

    echo ""
    echo "===================================================="
    echo "📊 Performance Test Summary:"

    for metric in "${!PERFORMANCE_METRICS[@]}"; do
        echo "   $metric: ${PERFORMANCE_METRICS[$metric]}"
    done

    echo ""

    if [ $failed_tests -eq 0 ]; then
        echo "🟢 Performance Test Result: All $total_tests tests PASSED!"
        echo "⚡ Dynamic linking system meets all performance requirements"
        echo "🚀 Ready for production workloads!"
        return 0
    else
        echo "🔴 Performance Test Result: $failed_tests/$total_tests tests failed"
        echo "❌ Performance optimization needed"
        return 1
    fi
}

# 정리
cleanup() {
    rm -rf "$PERF_TEST_DIR"
}

# 메인 실행
main() {
    trap cleanup EXIT

    # BC(1) 계산기 확인
    if ! command -v bc >/dev/null 2>&1; then
        echo "⚠️  Warning: 'bc' calculator not found. Some calculations may fail."
        echo "Install with: brew install bc (macOS) or apt-get install bc (Linux)"
    fi

    run_performance_tests
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
