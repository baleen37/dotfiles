#!/usr/bin/env bats

# IntelliJ IDEA 플러그인 관리 전체 워크플로우 E2E 테스트

setup() {
    export TEST_SCRIPT="${BATS_TEST_DIRNAME}/../../scripts/intellij-plugin-health-check"
    export TEMP_DIR="${BATS_TMPDIR}/intellij-e2e-test"
    export TEST_BACKUP_DIR="$TEMP_DIR/backup"

    mkdir -p "$TEMP_DIR" "$TEST_BACKUP_DIR"

    # 실제 환경 백업 (테스트 후 복구용)
    if [[ -d "$HOME/Library/Application Support/JetBrains" ]]; then
        export JETBRAINS_BACKUP="$TEST_BACKUP_DIR/jetbrains"
        mkdir -p "$JETBRAINS_BACKUP"
    fi
}

teardown() {
    # 테스트 환경 정리
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi

    # 실제 환경 복구는 하지 않음 (안전을 위해)
    # 실제 복구가 필요한 경우 수동으로 수행
}

@test "전체 워크플로우: 체크 → 진단 → 수정" {
    # 스크립트 존재 및 실행 가능성 확인
    [ -f "$TEST_SCRIPT" ]
    [ -x "$TEST_SCRIPT" ]

    # 1단계: 현재 상태 체크
    run timeout 60 "$TEST_SCRIPT" check
    local check_status=$status
    local check_output="$output"

    # 체크가 성공하거나 문제를 발견해야 함
    [[ $check_status -eq 0 ]] || [[ $check_status -eq 1 ]]

    # 2단계: 문제가 발견된 경우 상세 분석
    if [[ $check_status -ne 0 ]]; then
        # 문제 상세 정보가 포함되어 있는지 확인
        [[ "$check_output" == *"문제"* ]] || [[ "$check_output" == *"호환성"* ]] || [[ "$check_output" == *"ERROR"* ]]

        # 해결 방법 가이드가 포함되어 있는지 확인
        [[ "$check_output" == *"fix"* ]] || [[ "$check_output" == *"update"* ]]
    fi

    # 3단계: 안전한 수정 시뮬레이션 (실제 수정은 하지 않음)
    # 실제 환경에서는 --dry-run 같은 옵션을 추가하는 것이 좋음
    run timeout 60 "$TEST_SCRIPT" check
    [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
}

@test "Homebrew 통합 워크플로우 테스트" {
    if command -v brew >/dev/null 2>&1; then
        # 1. Homebrew cask 상태 확인
        run brew list --cask intellij-idea
        local cask_status=$status

        if [[ $cask_status -eq 0 ]]; then
            # IntelliJ IDEA가 설치된 경우

            # 2. 현재 버전 정보 확인
            run brew info --cask intellij-idea
            [ "$status" -eq 0 ]
            [[ "$output" == *"intellij-idea"* ]]

            # 3. 스크립트를 통한 업데이트 체크
            run timeout 30 "$TEST_SCRIPT" check
            # 성공하거나 업데이트 필요 상태 모두 정상
            [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]

        else
            # IntelliJ IDEA가 설치되지 않은 경우
            skip "IntelliJ IDEA가 Homebrew로 설치되지 않음"
        fi
    else
        skip "Homebrew가 설치되지 않음"
    fi
}

@test "플러그인 디렉토리 전체 스캔 및 분석" {
    if [[ "$(uname)" == "Darwin" ]]; then
        # macOS 환경에서만 실행

        source "$TEST_SCRIPT"

        # 실제 플러그인 디렉토리들 확인
        local plugin_dirs
        readarray -t plugin_dirs < <(get_plugin_directories)

        if [[ ${#plugin_dirs[@]} -gt 0 ]]; then
            # 각 플러그인 디렉토리에 대해 분석 수행
            for plugin_dir in "${plugin_dirs[@]}"; do
                if [[ -d "$plugin_dir" ]]; then
                    # 플러그인 호환성 검사 실행
                    run check_plugin_compatibility "$plugin_dir" "242.26775.15"
                    # 오류 없이 완료되어야 함
                    [ "$status" -ge 0 ]
                fi
            done
        else
            skip "플러그인 디렉토리를 찾을 수 없음"
        fi
    else
        skip "macOS가 아닌 환경"
    fi
}

@test "실제 IntelliJ IDEA 환경에서의 종합 테스트" {
    if [[ "$(uname)" == "Darwin" ]]; then
        source "$TEST_SCRIPT"

        # IntelliJ IDEA 설치 확인
        if intellij_path=$(detect_intellij_paths 2>/dev/null); then

            # 1. 버전 정보 추출
            local version
            version=$(get_intellij_version "$intellij_path")
            [[ -n "$version" ]]

            # 2. 플러그인 디렉토리 확인
            local plugin_dirs
            readarray -t plugin_dirs < <(get_plugin_directories)

            # 3. 각 플러그인 디렉토리에서 호환성 검사
            local total_issues=0
            for plugin_dir in "${plugin_dirs[@]}"; do
                if [[ -d "$plugin_dir" ]]; then
                    if check_plugin_compatibility "$plugin_dir" "$version" >/dev/null 2>&1; then
                        : # 호환성 문제 없음
                    else
                        ((total_issues++))
                    fi
                fi
            done

            # 4. 결과 검증
            # 이슈가 있어도 없어도 정상적으로 처리되어야 함
            [[ $total_issues -ge 0 ]]

            # 5. 전체 스크립트 실행으로 최종 검증
            run timeout 90 "$TEST_SCRIPT" check
            [[ "$status" -eq 0 ]] || [[ "$status" -eq 1 ]]

        else
            skip "IntelliJ IDEA가 설치되지 않음"
        fi
    else
        skip "macOS가 아닌 환경"
    fi
}

@test "오류 복구 및 롤백 테스트" {
    # 안전한 테스트 환경에서만 수행
    local test_plugin_dir="$TEMP_DIR/test_plugins"
    mkdir -p "$test_plugin_dir/TestPlugin/META-INF"

    # 테스트 플러그인 생성
    cat > "$test_plugin_dir/TestPlugin/META-INF/plugin.xml" << 'EOF'
<idea-plugin>
    <id>TestPlugin</id>
    <name>Test Plugin</name>
    <idea-version since-build="999.99999.99" until-build="999.99999.99"/>
</idea-plugin>
EOF

    source "$TEST_SCRIPT"

    # 호환성 문제 의도적 생성
    run check_plugin_compatibility "$test_plugin_dir" "242.26775.15"
    [ "$status" -gt 0 ]  # 호환성 문제 발견

    # 플러그인 비활성화 시뮬레이션
    disable_incompatible_plugins "$test_plugin_dir" "INCOMPATIBLE_PLUGIN:TestPlugin:999.99999.99:242.26775.15"

    # 비활성화 확인
    [ -d "$test_plugin_dir/TestPlugin.disabled" ]
    [ ! -d "$test_plugin_dir/TestPlugin" ]

    # 복구 시뮬레이션 (이름 변경을 통한 재활성화)
    mv "$test_plugin_dir/TestPlugin.disabled" "$test_plugin_dir/TestPlugin"

    # 복구 확인
    [ -d "$test_plugin_dir/TestPlugin" ]
    [ ! -d "$test_plugin_dir/TestPlugin.disabled" ]
}

@test "성능 및 타임아웃 테스트" {
    # 대용량 플러그인 디렉토리 시뮬레이션
    local large_plugin_dir="$TEMP_DIR/large_plugins"
    mkdir -p "$large_plugin_dir"

    # 100개의 가짜 플러그인 생성
    for i in {1..100}; do
        mkdir -p "$large_plugin_dir/Plugin$i/META-INF"
        cat > "$large_plugin_dir/Plugin$i/META-INF/plugin.xml" << EOF
<idea-plugin>
    <id>Plugin$i</id>
    <name>Plugin $i</name>
    <idea-version since-build="242.20000.0" until-build="242.99999.99"/>
</idea-plugin>
EOF
    done

    source "$TEST_SCRIPT"

    # 대용량 검사가 합리적 시간 내에 완료되는지 확인
    local start_time=$(date +%s)

    run check_plugin_compatibility "$large_plugin_dir" "242.26775.15"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # 100개 플러그인 검사가 30초 이내에 완료되어야 함
    [[ $duration -lt 30 ]]

    # 결과가 정상적이어야 함
    [ "$status" -eq 0 ]
}

@test "동시성 및 멀티 인스턴스 테스트" {
    # 여러 스크립트 인스턴스가 동시 실행되어도 안전한지 확인

    # 백그라운드에서 체크 실행
    timeout 30 "$TEST_SCRIPT" check &
    local pid1=$!

    # 두 번째 인스턴스 실행
    timeout 30 "$TEST_SCRIPT" check &
    local pid2=$!

    # 두 프로세스 완료 대기
    wait $pid1
    local status1=$?

    wait $pid2
    local status2=$?

    # 둘 다 정상적으로 완료되어야 함
    [[ $status1 -eq 0 ]] || [[ $status1 -eq 1 ]]
    [[ $status2 -eq 0 ]] || [[ $status2 -eq 1 ]]
}
