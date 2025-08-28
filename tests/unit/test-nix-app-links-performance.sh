#!/usr/bin/env bash
# TDD 성능 테스트: linkNixApps 최적화 검증

set -euo pipefail

# 테스트 설정
TEST_DIR="/tmp/nix-app-performance-test"
FAKE_NIX_STORE="$TEST_DIR/fake-nix-store"
FAKE_HOME_APPS="$TEST_DIR/fake-home/Applications"
FAKE_PROFILE="$TEST_DIR/fake-profile"

# 성능 측정 함수 (macOS 호환)
measure_time() {
    local start_time=$(python3 -c "import time; print(time.time())")
    "$@"
    local end_time=$(python3 -c "import time; print(time.time())")
    python3 -c "print($end_time - $start_time)"
}

# 테스트 초기화
setup_performance_test() {
    rm -rf "$TEST_DIR"
    mkdir -p "$FAKE_NIX_STORE"
    mkdir -p "$FAKE_HOME_APPS"
    mkdir -p "$FAKE_PROFILE"

    # Karabiner 앱 생성 (실제 경로 구조 모방)
    mkdir -p "$FAKE_NIX_STORE/vfdwh7882bnr8jnfq66f4fk5cksnigy1-karabiner-elements-14.13.0/Library/Application Support/org.pqrs/Karabiner-Elements"
    mkdir -p "$FAKE_NIX_STORE/vfdwh7882bnr8jnfq66f4fk5cksnigy1-karabiner-elements-14.13.0/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements.app"

    # 여러 가짜 앱 생성 (더 많이 생성해서 성능 차이 확실히 만들기)
    for i in {1..50}; do
        mkdir -p "$FAKE_PROFILE/Applications/TestApp$i.app"
        echo "Test app $i" > "$FAKE_PROFILE/Applications/TestApp$i.app/info.txt"
    done

    # nix store에도 더 깊은 구조 만들기
    for i in {1..10}; do
        mkdir -p "$FAKE_NIX_STORE/deep/nested/path$i"
        mkdir -p "$FAKE_NIX_STORE/another/deep/nested/path$i"
    done
}

# 최적화된 링크 함수 (테스트용)
link_nix_apps_optimized() {
    local home_apps="$1"
    local nix_store="$2"
    local profile="$3"

    mkdir -p "$home_apps"

    # 1. Karabiner-Elements 최적화된 링크
    if [ -L "$home_apps/Karabiner-Elements.app" ] && [ -e "$home_apps/Karabiner-Elements.app" ]; then
        echo "  ✅ Karabiner-Elements.app already linked (skipping search)"
    else
        local karabiner_path=$(find "$nix_store" -maxdepth 2 -name "*karabiner-elements-14*" -type d 2>/dev/null | head -1)
        if [ -n "$karabiner_path" ]; then
            local app_path="$karabiner_path/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements.app"
            if [ -d "$app_path" ]; then
                rm -f "$home_apps/Karabiner-Elements.app"
                ln -sf "$app_path" "$home_apps/Karabiner-Elements.app"
            fi
        fi
    fi

    # 2. 다른 앱들 최적화된 링크
    if [ -d "$profile" ]; then
        find "$profile" -maxdepth 3 -name "*.app" -type d 2>/dev/null | while read -r app_path; do
            [ ! -d "$app_path" ] && continue
            local app_name=$(basename "$app_path")
            [ "$app_name" = "Karabiner-Elements.app" ] && continue

            # 기존 유효한 링크 재사용
            if [ -L "$home_apps/$app_name" ] && [ -e "$home_apps/$app_name" ]; then
                continue
            fi

            rm -f "$home_apps/$app_name"
            ln -sf "$app_path" "$home_apps/$app_name"
        done
    fi
}

# 기존 방식 (성능 비교용)
link_nix_apps_old() {
    local home_apps="$1"
    local nix_store="$2"
    local profile="$3"

    mkdir -p "$home_apps"

    # 전체 nix store 검색 (느림)
    local karabiner_path=$(find "$nix_store" -name "Karabiner-Elements.app" -path "*karabiner-elements-14*" -type d 2>/dev/null | head -1 || true)
    if [ -n "$karabiner_path" ] && [ -d "$karabiner_path" ]; then
        rm -f "$home_apps/Karabiner-Elements.app"
        ln -sf "$karabiner_path" "$home_apps/Karabiner-Elements.app"
    fi

    # 무조건 모든 앱 다시 링크 (비효율)
    if [ -d "$profile" ]; then
        find "$profile" -name "*.app" -type d 2>/dev/null | while read -r app_path; do
            [ ! -d "$app_path" ] && continue
            local app_name=$(basename "$app_path")
            [ "$app_name" = "Karabiner-Elements.app" ] && continue

            rm -f "$home_apps/$app_name"
            ln -sf "$app_path" "$home_apps/$app_name"
        done
    fi
}

# 테스트 1: 첫 실행 성능 테스트
test_first_run_performance() {
    echo "🧪 Performance Test 1: First run speed comparison"

    setup_performance_test

    # 기존 방식 측정
    local old_time
    old_time=$(measure_time link_nix_apps_old "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE")
    rm -rf "$FAKE_HOME_APPS"

    # 최적화된 방식 측정
    local new_time
    new_time=$(measure_time link_nix_apps_optimized "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE")

    echo "  Old method: ${old_time}s"
    echo "  Optimized method: ${new_time}s"

    # 성능 개선 확인 (최소 20% 개선 요구)
    if (( $(echo "$new_time < $old_time * 0.8" | bc -l) )); then
        local improvement=$(echo "scale=2; ($old_time - $new_time) / $old_time * 100" | bc)
        echo "✅ PASS: ${improvement}% performance improvement"
        return 0
    else
        echo "❌ FAIL: No significant performance improvement"
        return 1
    fi
}

# 테스트 2: 재실행 성능 테스트 (기존 링크 재사용)
test_rerun_performance() {
    echo "🧪 Performance Test 2: Re-run with existing links"

    setup_performance_test

    # 첫 실행으로 링크 생성
    link_nix_apps_optimized "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" > /dev/null

    # 재실행 성능 측정
    local rerun_time
    rerun_time=$(measure_time link_nix_apps_optimized "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE")

    echo "  Re-run time: ${rerun_time}s"

    # 재실행은 0.1초 이내여야 함
    if (( $(echo "$rerun_time < 0.1" | bc -l) )); then
        echo "✅ PASS: Re-run is very fast (< 0.1s)"
        return 0
    else
        echo "❌ FAIL: Re-run is too slow (${rerun_time}s >= 0.1s)"
        return 1
    fi
}

# 테스트 3: 링크 유효성 검증
test_link_correctness() {
    echo "🧪 Performance Test 3: Link correctness verification"

    setup_performance_test
    link_nix_apps_optimized "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE" > /dev/null

    local correct_links=0
    local total_expected=51  # Karabiner + 50 test apps

    # 모든 예상 링크 확인
    [ -L "$FAKE_HOME_APPS/Karabiner-Elements.app" ] && [ -e "$FAKE_HOME_APPS/Karabiner-Elements.app" ] && ((correct_links++))

    for i in {1..50}; do
        [ -L "$FAKE_HOME_APPS/TestApp$i.app" ] && [ -e "$FAKE_HOME_APPS/TestApp$i.app" ] && ((correct_links++))
    done

    if [ $correct_links -eq $total_expected ]; then
        echo "✅ PASS: All $total_expected links are correct and valid"
        return 0
    else
        echo "❌ FAIL: Only $correct_links/$total_expected links are valid"
        return 1
    fi
}

# 모든 성능 테스트 실행
run_performance_tests() {
    echo "⚡ Running Performance TDD Tests - linkNixApps Optimization"
    echo "==========================================================="

    local failed_tests=0

    if ! test_first_run_performance; then
        ((failed_tests++))
    fi

    echo ""

    if ! test_rerun_performance; then
        ((failed_tests++))
    fi

    echo ""

    if ! test_link_correctness; then
        ((failed_tests++))
    fi

    echo ""
    echo "==========================================================="

    local total_tests=3
    if [ $failed_tests -eq 0 ]; then
        echo "🟢 Performance Optimization: All $((total_tests-failed_tests))/$total_tests tests PASSED!"
        echo "⚡ linkNixApps is now significantly faster"
        return 0
    else
        echo "🔴 Performance Issues: $failed_tests/$total_tests tests failed"
        echo "❌ Optimization needs improvement"
        return 1
    fi
}

# 정리
cleanup() {
    rm -rf "$TEST_DIR"
}

# 메인 실행
main() {
    # bc 명령어 확인
    if ! command -v bc &> /dev/null; then
        echo "❌ 'bc' command is required for performance measurements"
        echo "💡 Install with: brew install bc"
        return 1
    fi

    trap cleanup EXIT
    run_performance_tests
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
