#!/usr/bin/env bash
# 동적 Nix GUI 앱 링킹 시스템 v2.0
# 모든 Nix GUI 앱을 자동으로 감지하여 ~/Applications에 심볼릭 링크 생성

set -euo pipefail

# 메인 앱 링크 함수 - 완전 동적 감지 버전
link_nix_apps() {
  local home_apps="$1"
  local nix_store="$2"
  local profile="$3"

  echo "  🔗 Dynamic Nix GUI App Linker v2.0"
  echo "  📍 Target: $home_apps"
  echo ""

  # Applications 디렉토리 생성
  mkdir -p "$home_apps"

  # 1. WezTerm 전용 링킹 로직
  if [ -L "$home_apps/WezTerm.app" ] && [ -e "$home_apps/WezTerm.app" ]; then
    echo "  ✅ WezTerm.app already linked (skipping search)"
  else
    # WezTerm 검색 (Applications 폴더에서 우선 검색)
    local wezterm_path=$(find "$nix_store" -maxdepth 3 -name "WezTerm.app" -path "*/Applications/*" -type d 2> /dev/null | head -1)
    if [ -n "$wezterm_path" ]; then
      rm -f "$home_apps/WezTerm.app"
      ln -sf "$wezterm_path" "$home_apps/WezTerm.app"
      echo "  ✅ WezTerm.app linked (Nix optimized)"
    fi
  fi

  # 2. 동적 GUI 앱 감지 및 링킹 시스템
  echo "  🔍 Dynamically scanning for all GUI apps in Nix store..."

  local additional_apps=0

  # Nix store에서 모든 .app 디렉토리 동적 검색 (성능 최적화됨)
  local discovered_apps=()

  # 1단계: Applications 폴더 우선 검색 (가장 일반적) - 성능 최적화됨
  while IFS= read -r -d '' app_path; do
    local app_name=$(basename "$app_path")

    # 이미 전용 처리된 앱들 제외 (빠른 검사)
    case "$app_name" in
      "WezTerm.app")
        continue
        ;;
    esac

    discovered_apps+=("$app_path")
  done < <(find "$nix_store" -maxdepth 3 -path "*/Applications/*.app" -type d -print0 2> /dev/null)

  # 2단계: 특별한 패턴의 앱들 검색 (Qt 도구 등)
  while IFS= read -r -d '' app_path; do
    local app_name=$(basename "$app_path")

    # 개발 도구나 시스템 유틸리티는 제외
    case "$app_name" in
      "qml.app" | "Assistant.app" | "Designer.app" | "Linguist.app" | "pixeltool.app" | "qdbusviewer.app")
        continue
        ;;
    esac

    discovered_apps+=("$app_path")
  done < <(find "$nix_store" -maxdepth 4 -name "*.app" -path "*/bin/*" -type d -print0 2> /dev/null)

  # 발견된 앱들을 링크
  for app_path in "${discovered_apps[@]}"; do
    local app_name=$(basename "$app_path")

    # 이미 유효한 링크가 있으면 스킵
    if [ -L "$home_apps/$app_name" ] && [ -e "$home_apps/$app_name" ]; then
      # Home Manager와 중복 체크 - Home Manager가 관리 중이면 우선권 부여
      if [ -L "$home_apps/Home Manager Apps/$app_name" ]; then
        echo "  ⚠️  $app_name skipped (managed by Home Manager)"
        continue
      fi
      continue
    fi

    # Home Manager가 이미 관리 중인 앱은 중복 링크 방지
    if [ -L "$home_apps/Home Manager Apps/$app_name" ] && [ -e "$home_apps/Home Manager Apps/$app_name" ]; then
      echo "  ⚠️  $app_name skipped (already managed by Home Manager)"
      continue
    fi

    rm -f "$home_apps/$app_name"
    ln -sf "$app_path" "$home_apps/$app_name"
    echo "  ✅ $app_name linked (dynamically discovered)"
    additional_apps=$((additional_apps + 1))
  done

  # 3. 전체 GUI 앱 최적화된 링킹 시스템
  # 기존 유효한 링크들 먼저 확인
  local existing_valid_links=0
  if [ -d "$home_apps" ]; then
    for app_link in "$home_apps"/*.app; do
      [ -L "$app_link" ] && [ -e "$app_link" ] && existing_valid_links=$((existing_valid_links + 1))
    done
  fi

  echo "  📊 Found $existing_valid_links valid existing app links"

  # 4. 프로필에서 새로운 앱만 검색 (성능 최적화)
  if [ -d "$profile" ]; then
    local new_apps=0
    while IFS= read -r -d '' app_path; do
      [ ! -d "$app_path" ] && continue

      local app_name=$(basename "$app_path")

      # 이미 전용 처리된 앱들 스킵
      [ "$app_name" = "WezTerm.app" ] && continue

      # 이미 유효한 링크가 있으면 스킵 (성능 개선)
      if [ -L "$home_apps/$app_name" ] && [ -e "$home_apps/$app_name" ]; then
        continue
      fi

      rm -f "$home_apps/$app_name"
      ln -sf "$app_path" "$home_apps/$app_name"
      echo "  ✅ $app_name linked"
      new_apps=$((new_apps + 1))
    done < <(find "$profile" -maxdepth 3 -name "*.app" -type d -print0 2> /dev/null)

    [ $new_apps -eq 0 ] && echo "  ⚡ No new apps to link (all up-to-date)"
  fi

  # 5. 요약 리포트 출력
  echo ""
  echo "  🎯 Dynamic GUI App Linking Summary:"
  echo "    • Specialized apps: WezTerm (manual handling)"
  echo "    • Dynamically discovered: $additional_apps apps found and linked"
  echo '    • Profile apps: processed from $HOME/.nix-profile'
  echo "    • Total valid links: $existing_valid_links"
  echo "    • 🚀 All future Nix GUI apps will be auto-discovered!"
  echo ""

  return 0
}

# 이 스크립트가 직접 실행될 때
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  # 인자가 제공된 경우 실행
  if [ $# -ge 3 ]; then
    link_nix_apps "$@"
  else
    echo "Usage: $0 <home_apps_dir> <nix_store_dir> <profile_dir>"
    exit 1
  fi
fi
