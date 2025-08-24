#!/usr/bin/env bash
# TDD 테스트: Nix 앱 링크 기능 테스트

set -euo pipefail

# 테스트 설정
TEST_DIR="/tmp/nix-app-links-test"
FAKE_NIX_STORE="$TEST_DIR/fake-nix-store"
FAKE_HOME_APPS="$TEST_DIR/fake-home/Applications"
FAKE_PROFILE="$TEST_DIR/fake-profile"

# 테스트 초기화
setup_test() {
    rm -rf "$TEST_DIR"
    mkdir -p "$FAKE_NIX_STORE"
    mkdir -p "$FAKE_HOME_APPS"
    mkdir -p "$FAKE_PROFILE"

    # 가짜 앱들 생성
    mkdir -p "$FAKE_NIX_STORE/karabiner-elements-14.13.0/Applications/Karabiner-Elements.app"
    mkdir -p "$FAKE_PROFILE/Applications/KeePassXC.app"
    mkdir -p "$FAKE_PROFILE/Applications/Syncthing.app"

    echo "Fake Karabiner app v14" > "$FAKE_NIX_STORE/karabiner-elements-14.13.0/Applications/Karabiner-Elements.app/info.txt"
    echo "Fake KeePassXC app" > "$FAKE_PROFILE/Applications/KeePassXC.app/info.txt"
    echo "Fake Syncthing app" > "$FAKE_PROFILE/Applications/Syncthing.app/info.txt"
}

# 실제 구현 로드
source "$(dirname "${BASH_SOURCE[0]}")/../../lib/nix-app-linker.sh"

# 테스트 1: Karabiner-Elements 링크 테스트
test_karabiner_link() {
    echo "🧪 Test 1: Karabiner-Elements should be linked to Applications"

    setup_test

    if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE"; then
        if [ -L "$FAKE_HOME_APPS/Karabiner-Elements.app" ]; then
            echo "✅ PASS: Karabiner-Elements.app is linked"
            return 0
        else
            echo "❌ FAIL: Karabiner-Elements.app is not linked"
            return 1
        fi
    else
        echo "❌ FAIL: link_nix_apps function failed"
        return 1
    fi
}

# 테스트 2: 여러 앱 자동 감지 테스트
test_multiple_apps_detection() {
    echo "🧪 Test 2: Multiple apps should be auto-detected and linked"

    setup_test

    if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE"; then
        local linked_count=0

        [ -L "$FAKE_HOME_APPS/Karabiner-Elements.app" ] && ((linked_count++))
        [ -L "$FAKE_HOME_APPS/KeePassXC.app" ] && ((linked_count++))
        [ -L "$FAKE_HOME_APPS/Syncthing.app" ] && ((linked_count++))

        if [ $linked_count -eq 3 ]; then
            echo "✅ PASS: All 3 apps are linked"
            return 0
        else
            echo "❌ FAIL: Only $linked_count/3 apps are linked"
            return 1
        fi
    else
        echo "❌ FAIL: link_nix_apps function failed"
        return 1
    fi
}

# 테스트 3: 중복 링크 방지 테스트
test_duplicate_link_prevention() {
    echo "🧪 Test 3: Duplicate links should be prevented"

    setup_test

    # 기존 링크 생성
    ln -sf "/fake/old/path" "$FAKE_HOME_APPS/Karabiner-Elements.app"

    if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE"; then
        local target=$(readlink "$FAKE_HOME_APPS/Karabiner-Elements.app")
        if [[ "$target" == *"karabiner-elements-14.13.0"* ]]; then
            echo "✅ PASS: Old link was replaced with new one"
            return 0
        else
            echo "❌ FAIL: Link was not updated properly: $target"
            return 1
        fi
    else
        echo "❌ FAIL: link_nix_apps function failed"
        return 1
    fi
}

# 테스트 4: Karabiner v15 배제 테스트 (v14만 사용)
test_karabiner_v14_only() {
    echo "🧪 Test 4: Karabiner v15 should be excluded, only v14 used"

    setup_test

    # v15도 추가로 생성
    mkdir -p "$FAKE_NIX_STORE/karabiner-elements-15.3.0/Applications/Karabiner-Elements.app"
    echo "Fake Karabiner app v15" > "$FAKE_NIX_STORE/karabiner-elements-15.3.0/Applications/Karabiner-Elements.app/info.txt"

    if link_nix_apps "$FAKE_HOME_APPS" "$FAKE_NIX_STORE" "$FAKE_PROFILE"; then
        if [ -L "$FAKE_HOME_APPS/Karabiner-Elements.app" ]; then
            local target=$(readlink "$FAKE_HOME_APPS/Karabiner-Elements.app")
            if [[ "$target" == *"karabiner-elements-14.13.0"* ]]; then
                echo "✅ PASS: v14 selected over v15"
                return 0
            else
                echo "❌ FAIL: Wrong version selected: $target"
                return 1
            fi
        else
            echo "❌ FAIL: Karabiner-Elements.app is not linked"
            return 1
        fi
    else
        echo "❌ FAIL: link_nix_apps function failed"
        return 1
    fi
}

# 모든 테스트 실행
run_all_tests() {
    echo "🚀 Running TDD Tests - Checking App Link Functionality"
    echo "======================================================="

    local failed_tests=0

    if ! test_karabiner_link; then
        ((failed_tests++))
    fi

    echo ""

    if ! test_multiple_apps_detection; then
        ((failed_tests++))
    fi

    echo ""

    if ! test_duplicate_link_prevention; then
        ((failed_tests++))
    fi

    echo ""

    if ! test_karabiner_v14_only; then
        ((failed_tests++))
    fi

    echo ""
    echo "======================================================="

    local total_tests=4
    if [ $failed_tests -eq 0 ]; then
        echo "🟢 Improved Implementation Result: All $((total_tests-failed_tests))/$total_tests tests PASSED!"
        echo "✅ No hardcoding - flexible app linking works correctly"
        return 0
    else
        echo "🔴 Test Result: $failed_tests/$total_tests tests failed"
        echo "❌ Implementation needs fixes"
        return 1
    fi
}

# 정리
cleanup() {
    rm -rf "$TEST_DIR"
}

# 메인 실행
main() {
    trap cleanup EXIT
    run_all_tests
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
