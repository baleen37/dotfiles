#!/usr/bin/env bash
# Nix App Linker - TDD Green Phase Implementation

set -euo pipefail

# 메인 앱 링크 함수 - 하드코딩 제거된 버전
link_nix_apps() {
    local home_apps="$1"
    local nix_store="$2"
    local profile="$3"

    # Applications 디렉토리 생성
    mkdir -p "$home_apps"

    # 1. Karabiner-Elements v14 전용 링크 (v15 배제)
    local karabiner_path=$(find "$nix_store" -name "Karabiner-Elements.app" -path "*karabiner-elements-14*" -type d 2>/dev/null | head -1 || true)
    if [ -n "$karabiner_path" ] && [ -d "$karabiner_path" ]; then
        rm -f "$home_apps/Karabiner-Elements.app"
        ln -sf "$karabiner_path" "$home_apps/Karabiner-Elements.app"
    fi

    # 2. 현재 설치된 패키지에서 GUI 앱 자동 감지
    if [ -d "$profile" ]; then
        find "$profile" -name "*.app" -type d 2>/dev/null | while read -r app_path; do
            [ ! -d "$app_path" ] && continue

            local app_name=$(basename "$app_path")

            # Karabiner은 이미 처리했으므로 스킵
            [ "$app_name" = "Karabiner-Elements.app" ] && continue

            # 이미 링크된 앱은 스킵
            [ -L "$home_apps/$app_name" ] && continue

            rm -f "$home_apps/$app_name"
            ln -sf "$app_path" "$home_apps/$app_name"
        done
    fi

    return 0
}

# 이 스크립트가 직접 실행될 때
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 인자가 제공된 경우 실행
    if [ $# -ge 3 ]; then
        link_nix_apps "$@"
    else
        echo "Usage: $0 <home_apps_dir> <nix_store_dir> <profile_dir>"
        exit 1
    fi
fi
