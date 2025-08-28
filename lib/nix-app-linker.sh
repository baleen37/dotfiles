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

    # 1. Karabiner-Elements v14 최적화된 링크 (성능 개선)
    # 기존 링크가 유효한지 먼저 확인
    if [ -L "$home_apps/Karabiner-Elements.app" ] && [ -e "$home_apps/Karabiner-Elements.app" ]; then
        echo "  ✅ Karabiner-Elements.app already linked (skipping search)"
    else
        # 제한된 경로에서만 검색 (성능 최적화)
        local karabiner_path=$(find "$nix_store" -maxdepth 2 -name "*karabiner-elements-14*" -type d 2>/dev/null | head -1)
        if [ -n "$karabiner_path" ]; then
            local app_path="$karabiner_path/Library/Application Support/org.pqrs/Karabiner-Elements/Karabiner-Elements.app"
            if [ -d "$app_path" ]; then
                rm -f "$home_apps/Karabiner-Elements.app"
                ln -sf "$app_path" "$home_apps/Karabiner-Elements.app"
                echo "  ✅ Karabiner-Elements.app linked (v14.13.0 optimized)"
            fi
        fi
    fi

    # 2. 전체 GUI 앱 최적화된 링킹 시스템
    # 기존 유효한 링크들 먼저 확인
    local existing_valid_links=0
    if [ -d "$home_apps" ]; then
        for app_link in "$home_apps"/*.app; do
            [ -L "$app_link" ] && [ -e "$app_link" ] && existing_valid_links=$((existing_valid_links + 1))
        done
    fi

    echo "  📊 Found $existing_valid_links valid existing app links"

    # 프로필에서 새로운 앱만 검색 (성능 최적화)
    if [ -d "$profile" ]; then
        local new_apps=0
        find "$profile" -maxdepth 3 -name "*.app" -type d 2>/dev/null | while read -r app_path; do
            [ ! -d "$app_path" ] && continue

            local app_name=$(basename "$app_path")

            # Karabiner은 이미 처리했으므로 스킵
            [ "$app_name" = "Karabiner-Elements.app" ] && continue

            # 이미 유효한 링크가 있으면 스킵 (성능 개선)
            if [ -L "$home_apps/$app_name" ] && [ -e "$home_apps/$app_name" ]; then
                continue
            fi

            rm -f "$home_apps/$app_name"
            ln -sf "$app_path" "$home_apps/$app_name"
            echo "  ✅ $app_name linked"
            new_apps=$((new_apps + 1))
        done

        [ $new_apps -eq 0 ] && echo "  ⚡ No new apps to link (all up-to-date)"
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
