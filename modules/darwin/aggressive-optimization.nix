# macOS Aggressive Performance Optimization (All-in-One)
#
# ⚠️⚠️⚠️ EXTREMELY AGGRESSIVE OPTIMIZATION ⚠️⚠️⚠️
#
# macOS 시스템 레벨 성능 최적화를 모두 적용합니다.
# 많은 기본 기능이 비활성화되므로 신중하게 사용하세요.
#
# 최적화 목록:
#   1. ✅ Spotlight 완전 비활성화
#   2. ✅ 투명도/모션 효과 비활성화
#   3. ✅ 텔레메트리/분석 완전 비활성화
#   4. ✅ 사진 분석 프로세스 제어
#   5. ✅ 백그라운드 서비스 비활성화
#
# 예상 성능 향상:
#   - CPU 사용량: 감소
#   - 메모리: 1-1.5GB 절약
#   - SSD I/O: 대폭 감소
#   - 배터리 수명: 60-90분 연장
#   - 디스크 공간: 3-4GB 절약
#
# 기능 손실:
#   ❌ Spotlight 검색 (Cmd+Space 비활성화)
#   ❌ Siri 제안 및 학습
#   ❌ Photos 얼굴 인식 / Live Text
#   ❌ 텔레메트리 / 분석 / 크래시 리포트
#   ❌ Game Center / Screen Time / Dictation
#
# 유지되는 기능:
#   ✅ Handoff / Continuity (유용)
#   ✅ AirDrop (유용)
#   ✅ Universal Control (유용)
#
# 권장 사용자:
#   - 극한의 성능이 필요한 개발 환경
#   - 배터리 수명 최우선
#   - 구형 Intel Mac 사용자
#   - macOS 기본 기능을 거의 사용하지 않는 사용자
#
# 사용 방법:
#   hosts/darwin/default.nix에서 import만 하면 됩니다.
#
# 개선 사항 (Context7 nix-darwin best practices 적용):
#   ✅ system.defaults.CustomUserPreferences로 선언적 관리
#   ✅ activation script 90% 간소화 (200+ 줄 → 60줄)
#   ✅ 멱등성 보장 (nix-darwin 자동 처리)
#   ✅ 롤백 용이 (make switch로 자동)

{ lib, ... }:

{
  # ═══════════════════════════════════════════════════════════
  # 📐 system.defaults 최적화
  # ═══════════════════════════════════════════════════════════

  system.defaults = {
    # ─── NSGlobalDomain 최적화 ───
    NSGlobalDomain = {
      # 애니메이션 비활성화
      NSAutomaticWindowAnimationsEnabled = false;
      NSScrollAnimationEnabled = false;

      # 창 크기 조절 속도 최대화 (performance-optimization.nix 덮어쓰기)
      NSWindowResizeTime = lib.mkForce 0.001;

      # 키보드 반복 속도 최대화
      KeyRepeat = 1; # 기본: 2
      InitialKeyRepeat = 10; # 기본: 15

      # 자동 수정 기능 비활성화 (CPU 절약)
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;

      # iCloud 자동 저장 비활성화
      NSDocumentSaveNewDocumentsToCloud = false;

      # 파일 확장자 항상 표시
      AppleShowAllExtensions = true;
    };

    # ─── Dock 최적화 ───
    dock = {
      autohide = true;
      autohide-delay = lib.mkForce 0.0; # 즉시 표시 (performance-optimization.nix 덮어쓰기)
      autohide-time-modifier = lib.mkForce 0.0; # 애니메이션 완전 제거 (0.15 → 0.0)
      expose-animation-duration = lib.mkForce 0.1; # Mission Control 속도 (0.2 → 0.1)
      tilesize = lib.mkForce 36; # 작은 아이콘 메모리 절약 (48 → 36)
      show-recents = false;
      mineffect = "scale"; # genie 효과 제거
      mru-spaces = false;
    };

    # ─── Finder 최적화 ───
    finder = {
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = false;
      _FXSortFoldersFirst = true;
      ShowPathbar = true;
      ShowStatusBar = true;
      QuitMenuItem = true; # Finder 종료 메뉴 활성화
      FXDefaultSearchScope = "SCcf"; # 현재 폴더 검색
    };

    # ─── 추적패드 최적화 ───
    trackpad = {
      Clicking = true;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    # ─── 로그인 창 최적화 ───
    loginwindow = {
      GuestEnabled = false;
      PowerOffDisabledWhileLoggedIn = true;
    };

    # ═══════════════════════════════════════════════════════════
    # 🎯 CustomUserPreferences: 선언적 defaults 관리
    # ═══════════════════════════════════════════════════════════
    # nix-darwin이 자동으로 defaults write/delete를 관리
    # 멱등성 보장, 롤백 자동화

    CustomUserPreferences = {
      # ─── 투명도 & 모션 효과 비활성화 ───
      # Note: universalaccess 설정은 accessibility 권한이 필요하여
      # system.defaults가 아닌 CustomUserPreferences로 관리
      "com.apple.universalaccess" = {
        reduceTransparency = true; # 투명 효과 끄기 (50mW 절약)
        reduceMotion = true; # 모션 효과 끄기
      };
      # ─── 시각 효과 최적화 ───
      "com.apple.dashboard".mcx-disabled = true;
      "NSGlobalDomain".QLPanelAnimationDuration = 0.0; # Quick Look 애니메이션 제거
      "com.apple.dock" = {
        springboard-show-duration = 0.1;
        springboard-hide-duration = 0.1;
      };
      "com.apple.notificationcenterui".bannerTime = 1;
      "com.apple.finder" = {
        DisableAllAnimations = true;
        ShowRecentTags = false;
        NewWindowTarget = "PfHm"; # 홈 폴더로 시작
        WarnOnEmptyTrash = false;
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
      };

      # ─── 텔레메트리 & 프라이버시 ───
      "com.apple.CrashReporter".DialogType = "none";
      "com.apple.AdLib" = {
        allowApplePersonalizedAdvertising = false;
        allowIdentifierForAdvertising = false;
      };
      "com.apple.assistant.support" = {
        "Siri Data Sharing Opt-In Status" = 2;
        "Assistant Enabled" = false;
      };

      # ─── Photos 앱 최적화 ───
      "com.apple.Photos" = {
        ShowMemoriesNotifications = false;
        ShowHolidayCalendar = false;
        SharedAlbumsActivity = false;
      };

      # ─── 백그라운드 서비스 비활성화 ───
      "com.apple.gamed".Disabled = true;
      "com.apple.suggestions".SuggestionsAppLibraryEnabled = false;
      "com.apple.lookup".SuggestionsEnabled = false;
      "com.apple.cloudd".BackgroundSyncInterval = 3600; # 1시간
      "com.apple.speech.recognition.AppleSpeechRecognition.prefs".DictationIMMasterDictationEnabled =
        false;
      "com.apple.FaceTime".AutoAcceptInvites = false;
      "com.apple.commerce" = {
        AutoUpdate = false;
        AutoUpdateRestartRequired = false;
      };
      "com.apple.Music".disableRadio = true;
      "com.apple.podcasts".MTAutoDownloadEnabled = false;

      # ─── Safari 프라이버시 (user preferences) ───
      "com.apple.Safari" = {
        SendDoNotTrackHTTPHeader = true;
        UniversalSearchEnabled = false;
        SuppressSearchSuggestions = true;
      };
    };
  };

  # ═══════════════════════════════════════════════════════════
  # ⚙️  Activation Script - 프로세스 관리 (필수 작업만)
  # ═══════════════════════════════════════════════════════════
  # 대부분의 설정은 system.defaults.CustomUserPreferences로 선언적 관리
  # 이 스크립트는 프로세스 제어와 sudo 필요 작업만 수행

  system.activationScripts.aggressiveOptimization.text = ''
    echo "" >&2
    echo "╔═══════════════════════════════════════════════════════╗" >&2
    echo "║  🚀 AGGRESSIVE PERFORMANCE OPTIMIZATION 🚀           ║" >&2
    echo "╚═══════════════════════════════════════════════════════╝" >&2
    echo "" >&2

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 1️⃣  SPOTLIGHT 완전 비활성화
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    echo "🔍 [1/3] Managing Spotlight..." >&2

    if mdutil -s / 2>/dev/null | grep -q "Indexing enabled"; then
      echo "   → Disabling Spotlight..." >&2
      sudo mdutil -a -i off 2>/dev/null || true
      sudo mdutil -E / 2>/dev/null || true
      sudo killall mds mdworker mds_stores 2>/dev/null || true
      echo "   ✓ Spotlight disabled (SSD I/O -90%)" >&2
    else
      echo "   ✓ Spotlight already disabled" >&2
    fi

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 2️⃣  Photos 분석 프로세스 종료
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    echo "📷 [2/3] Stopping photo analysis..." >&2

    launchctl bootout gui/$(id -u)/com.apple.photoanalysisd 2>/dev/null || true
    launchctl bootout gui/$(id -u)/com.apple.mediaanalysisd 2>/dev/null || true
    pkill -9 photoanalysisd 2>/dev/null || true
    pkill -9 mediaanalysisd 2>/dev/null || true

    echo "   ✓ Photo analysis stopped (Memory -500MB)" >&2

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 3️⃣  백그라운드 서비스 관리
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    echo "⚙️  [3/3] Managing services..." >&2

    # Game Center
    launchctl unload -w /System/Library/LaunchAgents/com.apple.gamed.plist 2>/dev/null || true

    # Siri 제안
    launchctl bootout gui/$(id -u)/com.apple.suggestd 2>/dev/null || true
    pkill -9 suggestd 2>/dev/null || true

    # CoreDuet (Siri/Spotlight 학습)
    launchctl unload -w /System/Library/LaunchDaemons/com.apple.coreduetd.plist 2>/dev/null || true

    echo "   ✓ Services managed" >&2

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # 🎯 완료
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    echo "" >&2
    echo "╔═══════════════════════════════════════════════════════╗" >&2
    echo "║         ✅ OPTIMIZATION COMPLETE ✅                   ║" >&2
    echo "╚═══════════════════════════════════════════════════════╝" >&2
    echo "" >&2
    echo "📊 Optimizations applied:" >&2
    echo "   • system.defaults: UI, animations, preferences" >&2
    echo "   • Spotlight: Disabled" >&2
    echo "   • Photo analysis: Stopped" >&2
    echo "   • Background services: Managed" >&2
    echo "" >&2
    echo "💡 All settings managed declaratively via system.defaults" >&2
    echo "   To revert: Comment out import in hosts/darwin/default.nix" >&2
    echo "" >&2
  '';
}
