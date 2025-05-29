{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Raycast 관련 설정
  home.packages = with pkgs; [
    raycast
  ];


  # 기타 설정...
  #   home.activation.configureRaycast = lib.hm.dag.entryAfter ["writeBoundary"] ''
  #   if [ -d "/Applications/Raycast.app" ] || [ -d "$HOME/Applications/Home Manager Apps/Raycast.app" ]; then
  #     echo "Configuring Raycast settings..."

  #     # 기본 단축키 설정 (Command+Space)
  #     defaults write com.raycast.macos hotkeyModifiers -int 1048576
  #     defaults write com.raycast.macos hotkeyKey -int 49

  #     # 시작시 자동 실행
  #     defaults write com.raycast.macos openAtLogin -bool true

  #     # 메뉴바에 표시
  #     defaults write com.raycast.macos showInMenuBar -bool true

  #     # 테마 설정 (시스템 테마 따르기)
  #     defaults write com.raycast.macos theme -string "system"

  #     # 자주 사용하는 확장 프로그램 활성화
  #     # defaults write com.raycast.macos enabledExtensions -array \
  #     #   "com.raycast.extensions.spotlight" \
  #     #   "com.raycast.extensions.calculator" \
  #     #   "com.raycast.extensions.system"

  #     echo "Raycast configuration complete"
  #   else
  #     echo "Raycast is not installed or not found. Skipping configuration."
  #   fi
  # '';
}
