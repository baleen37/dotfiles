# macOS Default Apps Cleanup
#
# macOS 기본 앱 중 불필요한 앱을 자동으로 제거하는 설정입니다.
# `make switch` 실행 시 activation script를 통해 자동으로 실행됩니다.
#
# 제거 대상 앱 (약 6-8GB 절약):
#   - GarageBand (2-3GB) - 음악 제작
#   - iMovie (3-4GB) - 비디오 편집
#   - TV (200MB) - Apple TV+
#   - Podcasts (100MB) - 팟캐스트
#   - News (50MB) - Apple News
#   - Stocks (30MB) - 주식
#   - Freeform (50MB) - 화이트보드
#
# 안전 장치:
#   - 명시된 앱만 제거 (실수 방지)
#   - 시스템 필수 앱 보호 (Finder, App Store, Safari 등)
#   - dotfiles 버전 관리로 추적 가능
#
# 주의사항:
#   - SIP (System Integrity Protection) 활성화 시 일부 시스템 앱은 제거 불가
#   - 제거 후 App Store에서 재설치 가능

{ pkgs, ... }:

{
  system.activationScripts.cleanupMacOSApps = {
    text = ''
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "🧹 Removing unused macOS default apps..." >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2

      # 제거할 앱 목록
      apps=(
        "GarageBand.app"
        "iMovie.app"
        "TV.app"
        "Podcasts.app"
        "News.app"
        "Stocks.app"
        "Freeform.app"
      )

      removed_count=0
      skipped_count=0

      for app in "''${apps[@]}"; do
        app_path="/Applications/$app"

        if [ -e "$app_path" ]; then
          echo "  🗑️  Removing: $app" >&2

          # sudo 없이 제거 시도 (사용자 설치 앱)
          if rm -rf "$app_path" 2>/dev/null; then
            removed_count=$((removed_count + 1))
          else
            # sudo로 재시도 (시스템 앱)
            if sudo rm -rf "$app_path" 2>/dev/null; then
              removed_count=$((removed_count + 1))
            else
              echo "     ⚠️  Failed to remove (SIP protected): $app" >&2
              skipped_count=$((skipped_count + 1))
            fi
          fi
        else
          echo "  ✓  Already removed: $app" >&2
        fi
      done

      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
      echo "✨ Cleanup complete!" >&2
      echo "   - Removed: $removed_count apps" >&2
      echo "   - Skipped: $skipped_count apps (protected)" >&2
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    '';
  };
}
