# app-links.nix - Nix 앱들을 /Applications에 자동으로 심볼릭 링크 생성
# macOS 보안 권한 문제 해결을 위한 확장 가능한 모듈

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.system.nixAppLinks;

  # nix store에서 앱을 찾는 함수
  findNixApp = appName: ''
    APP_PATH=""

    # Applications 폴더에서 우선 검색
    for path in $(find /nix/store -name "${appName}" -type d -path "*/Applications/*" 2>/dev/null | sort -V); do
      if [ -d "$path" ]; then
        APP_PATH="$path"
      fi
    done

    # Applications 폴더에 없으면 전체 검색
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
  createAppLink = appName: ''
    echo "🔗 Linking ${appName}..."

    APP_PATH=$(${findNixApp appName})
    TARGET_PATH="/Applications/${appName}"

    if [ -n "$APP_PATH" ] && [ -d "$APP_PATH" ]; then
      # 기존 링크나 앱 제거
      if [ -L "$TARGET_PATH" ] || [ -d "$TARGET_PATH" ]; then
        rm -rf "$TARGET_PATH"
      fi

      # 심볼릭 링크 생성
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
