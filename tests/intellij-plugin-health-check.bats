#!/usr/bin/env bats

# IntelliJ IDEA 플러그인 호환성 체크 스크립트 테스트

# 테스트 설정
setup() {
    # 테스트 실행 전 초기화
    export TEST_SCRIPT="${BATS_TEST_DIRNAME}/../scripts/intellij-plugin-health-check"
    export TEMP_DIR="${BATS_TMPDIR}/intellij-test"
    mkdir -p "$TEMP_DIR"

    # 테스트용 가짜 IntelliJ 디렉토리 구조 생성
    export FAKE_INTELLIJ_PATH="$TEMP_DIR/IntelliJ IDEA.app"
    export FAKE_PLUGIN_DIR="$TEMP_DIR/plugins"

    mkdir -p "$FAKE_INTELLIJ_PATH/Contents"
    mkdir -p "$FAKE_PLUGIN_DIR"
}

# 테스트 정리
teardown() {
    # 테스트 후 정리
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# 테스트용 Info.plist 파일 생성
create_test_info_plist() {
    local version="$1"
    local plist_path="$FAKE_INTELLIJ_PATH/Contents/Info.plist"

    cat > "$plist_path" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleVersion</key>
    <string>$version</string>
</dict>
</plist>
EOF
}

# 테스트용 플러그인 메타데이터 생성
create_test_plugin() {
    local plugin_name="$1"
    local since_build="$2"
    local until_build="$3"

    local plugin_dir="$FAKE_PLUGIN_DIR/$plugin_name"
    mkdir -p "$plugin_dir/META-INF"

    cat > "$plugin_dir/META-INF/plugin.xml" << EOF
<idea-plugin>
    <id>$plugin_name</id>
    <name>$plugin_name</name>
    <idea-version since-build="$since_build" until-build="$until_build"/>
</idea-plugin>
EOF
}

@test "스크립트 파일이 존재하고 실행 가능한지 확인" {
    [ -f "$TEST_SCRIPT" ]
    [ -x "$TEST_SCRIPT" ]
}

@test "스크립트 도움말 메시지 출력 테스트" {
    run bash "$TEST_SCRIPT" --help || true
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]  # 도움말 출력 후 종료
}

@test "IntelliJ IDEA 버전 감지 기능 테스트" {
    # 테스트용 Info.plist 생성
    create_test_info_plist "242.26775.15"

    # 스크립트에서 버전 추출 함수 테스트
    source "$TEST_SCRIPT"

    run get_intellij_version "$FAKE_INTELLIJ_PATH"
    [ "$status" -eq 0 ]
    [[ "$output" == "242.26775.15" ]]
}

@test "플러그인 호환성 검사 - 호환되는 플러그인" {
    # IntelliJ 버전 설정
    create_test_info_plist "242.26775.15"

    # 호환되는 플러그인 생성 (since-build가 현재 버전보다 낮음)
    create_test_plugin "TestPlugin" "242.20000.0" "242.99999.99"

    # 스크립트 함수 테스트
    source "$TEST_SCRIPT"

    run check_plugin_compatibility "$FAKE_PLUGIN_DIR" "242.26775.15"
    [ "$status" -eq 0 ]  # 호환성 문제 없음
}

@test "플러그인 호환성 검사 - 호환되지 않는 플러그인" {
    # IntelliJ 버전 설정 (낮은 버전)
    create_test_info_plist "242.24807.4"

    # 호환되지 않는 플러그인 생성 (since-build가 현재 버전보다 높음)
    create_test_plugin "IncompatiblePlugin" "242.26775.15" "242.99999.99"

    # 스크립트 함수 테스트
    source "$TEST_SCRIPT"

    run check_plugin_compatibility "$FAKE_PLUGIN_DIR" "242.24807.4"
    [ "$status" -gt 0 ]  # 호환성 문제 발견
    [[ "$output" == *"INCOMPATIBLE_PLUGIN:IncompatiblePlugin"* ]]
}

@test "복수 플러그인 호환성 혼합 테스트" {
    # IntelliJ 버전 설정
    create_test_info_plist "242.25000.0"

    # 호환되는 플러그인
    create_test_plugin "CompatiblePlugin" "242.20000.0" "242.99999.99"

    # 호환되지 않는 플러그인
    create_test_plugin "IncompatiblePlugin" "242.26000.0" "242.99999.99"

    # 스크립트 함수 테스트
    source "$TEST_SCRIPT"

    run check_plugin_compatibility "$FAKE_PLUGIN_DIR" "242.25000.0"
    [ "$status" -gt 0 ]  # 호환성 문제 발견
    [[ "$output" == *"INCOMPATIBLE_PLUGIN:IncompatiblePlugin"* ]]
    [[ "$output" != *"INCOMPATIBLE_PLUGIN:CompatiblePlugin"* ]]
}

@test "존재하지 않는 플러그인 디렉토리 처리" {
    source "$TEST_SCRIPT"

    run check_plugin_compatibility "/nonexistent/directory" "242.26775.15"
    [ "$status" -eq 0 ]  # 오류가 아닌 정상 처리
}

@test "플러그인 메타데이터가 없는 경우 처리" {
    # 메타데이터 없는 플러그인 디렉토리 생성
    mkdir -p "$FAKE_PLUGIN_DIR/EmptyPlugin"

    source "$TEST_SCRIPT"

    run check_plugin_compatibility "$FAKE_PLUGIN_DIR" "242.26775.15"
    [ "$status" -eq 0 ]  # 오류 없이 처리
}

@test "Homebrew 설치 확인 테스트" {
    # brew 명령어 존재 여부에 따른 처리 테스트
    if command -v brew >/dev/null 2>&1; then
        source "$TEST_SCRIPT"

        # Homebrew가 설치된 경우
        run check_intellij_updates
        # 성공하거나 업데이트 필요 상태 모두 정상
        [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]
    else
        skip "Homebrew가 설치되지 않음"
    fi
}

@test "플러그인 비활성화 기능 테스트" {
    # 테스트 플러그인 생성
    create_test_plugin "TestPlugin" "242.26775.15" "242.99999.99"

    source "$TEST_SCRIPT"

    # 플러그인이 존재하는지 확인
    [ -d "$FAKE_PLUGIN_DIR/TestPlugin" ]

    # 비활성화 실행
    disable_incompatible_plugins "$FAKE_PLUGIN_DIR" "INCOMPATIBLE_PLUGIN:TestPlugin:242.26775.15:242.24807.4"

    # 플러그인이 비활성화되었는지 확인
    [ -d "$FAKE_PLUGIN_DIR/TestPlugin.disabled" ]
    [ ! -d "$FAKE_PLUGIN_DIR/TestPlugin" ]
}

@test "스크립트 전체 실행 테스트 - 체크 모드" {
    # Mock IntelliJ 설치 경로 설정을 위한 임시 함수 오버라이드
    source "$TEST_SCRIPT"

    # detect_intellij_paths 함수 오버라이드
    detect_intellij_paths() {
        echo "$FAKE_INTELLIJ_PATH"
        return 0
    }

    # get_plugin_directories 함수 오버라이드
    get_plugin_directories() {
        echo "$FAKE_PLUGIN_DIR"
    }

    # 테스트 환경 설정
    create_test_info_plist "242.26775.15"
    create_test_plugin "TestPlugin" "242.20000.0" "242.99999.99"

    # check_intellij_updates 함수 오버라이드 (Homebrew 없는 환경 대응)
    check_intellij_updates() {
        return 0  # 업데이트 불필요
    }

    export -f detect_intellij_paths get_plugin_directories check_intellij_updates

    run main "check"
    [ "$status" -eq 0 ]
}

@test "잘못된 Info.plist 파일 처리" {
    # 잘못된 형식의 Info.plist 생성
    echo "invalid plist content" > "$FAKE_INTELLIJ_PATH/Contents/Info.plist"

    source "$TEST_SCRIPT"

    run get_intellij_version "$FAKE_INTELLIJ_PATH"
    [ "$status" -eq 0 ]
    # 잘못된 plist에서는 unknown이 반환되거나 PlistBuddy 오류 메시지가 포함될 수 있음
    [[ "$output" == *"unknown"* ]] || [[ "$output" == *"Error"* ]] || [[ "$output" == "" ]]
}

@test "빈 플러그인 디렉토리 처리" {
    # 빈 플러그인 디렉토리
    mkdir -p "$FAKE_PLUGIN_DIR"

    source "$TEST_SCRIPT"

    run check_plugin_compatibility "$FAKE_PLUGIN_DIR" "242.26775.15"
    [ "$status" -eq 0 ]
}
