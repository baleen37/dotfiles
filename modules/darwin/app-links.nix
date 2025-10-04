# macOS Nix Application Symbolic Links System
#
# Nix로 설치된 GUI 앱들을 /Applications 디렉토리에 심볼릭 링크로 생성합니다.
# macOS 보안 시스템은 /Applications 내의 앱만 접근성 권한을 허용하므로
# Karabiner-Elements 같은 시스템 권한이 필요한 앱의 정상 동작을 위해 필수입니다.
#
# 주요 기능:
#   - /nix/store에서 .app 패키지 자동 탐지
#   - /Applications로 심볼릭 링크 생성
#   - 기존 링크 자동 갱신
#   - 확장 가능한 앱 목록 관리
#
# 사용법:
#   system.nixAppLinks.enable = true;
#   system.nixAppLinks.apps = [ "Karabiner-Elements.app" "Rectangle.app" ];
#
# 참고: 현재는 비활성화 상태 (root 권한 필요), home-manager.nix에서 대체 구현 사용

{ config
, lib
, pkgs
, ...
}:

with lib;

let
  cfg = config.system.nixAppLinks;

  # nix store에서 .app 패키지를 찾는 함수
  # 두 단계 검색 전략으로 최적화:
  #   1. /nix/store/*/Applications/*.app 경로 우선 검색 (일반적인 위치)
  #   2. 발견되지 않으면 전체 /nix/store 검색 (비표준 위치)
  # sort -V를 통해 버전 정렬로 최신 패키지 우선 선택
  findNixApp = appName: ''
    APP_PATH=""

    # 1단계: Applications 폴더에서 우선 검색 (가장 일반적인 경로)
    for path in $(find /nix/store -name "${appName}" -type d -path "*/Applications/*" 2>/dev/null | sort -V); do
      if [ -d "$path" ]; then
        APP_PATH="$path"  # 최신 버전으로 계속 업데이트 (sort -V로 정렬됨)
      fi
    done

    # 2단계: Applications 폴더에 없으면 전체 store 검색 (fallback)
    if [ -z "$APP_PATH" ]; then
      for path in $(find /nix/store -name "${appName}" -type d 2>/dev/null | sort -V); do
        if [ -d "$path" ]; then
          APP_PATH="$path"
        fi
      done
    fi

    echo "$APP_PATH"
  '';

  # 단일 앱 링크 생성 스크립트
  # /nix/store의 .app을 /Applications로 심볼릭 링크
  # 기존 링크/앱이 있으면 제거 후 재생성 (idempotent)
  createAppLink = appName: ''
    echo "🔗 Linking ${appName}..."

    APP_PATH=$(${findNixApp appName})
    TARGET_PATH="/Applications/${appName}"

    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
      # 기존 링크나 앱 제거 (심볼릭 링크 또는 실제 디렉토리 모두 처리)
      if [ -L "$TARGET_PATH" ] || [ -d "$TARGET_PATH" ]; then
        rm -rf "$TARGET_PATH"
      fi

      # 심볼릭 링크 생성 (ln -sf는 기존 파일이 있어도 강제 덮어쓰기)
      ln -sf "$APP_PATH" "$TARGET_PATH"
      echo "   ✅ Successfully linked: $APP_PATH → $TARGET_PATH"
    else
      echo "   ⚠️  ${appName} not found in nix store"
    fi
  '';

  # 모든 앱 링크 생성 스크립트
  createAllAppLinks = concatMapStrings createAppLink cfg.apps;

in
{
  options.system.nixAppLinks = {
    enable = mkEnableOption "Nix app symbolic links to /Applications";

    apps = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "Karabiner-Elements.app"
        "Rectangle.app"
        "Alacritty.app"
      ];
      description = ''
        List of nix-installed app names to create symbolic links for in /Applications.
        This helps with macOS security permissions that only recognize apps in /Applications.
      '';
    };
  };

  config = mkIf cfg.enable {
    system.activationScripts.nixAppLinks = {
      text = ''
        echo "🔗 Creating nix app symbolic links..."

        ${createAllAppLinks}

        echo "✅ Nix app linking complete!"
        echo ""
        echo "📝 Remember to grant security permissions in System Settings:"
        echo "   • Privacy & Security → Input Monitoring"
        echo "   • Privacy & Security → Accessibility"
        echo "   • General → Login Items & Extensions"
        echo ""
      '';
    };
  };
}
