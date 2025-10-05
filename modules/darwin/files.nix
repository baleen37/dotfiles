# macOS-Specific File Mappings
#
# macOS에 특화된 애플리케이션 설정 파일들을 홈 디렉토리에 배포합니다.
# Home Manager의 home.file 옵션과 통합되어 선언적 파일 관리를 제공합니다.
#
# 관리 대상:
#   - Hammerspoon: 윈도우 관리 자동화 설정 (Lua)
#   - Karabiner-Elements: 키보드 커스터마이징 설정 (JSON)
#   - Alt-Tab: 윈도우 전환기 환경설정 (plist)
#   - Alfred: 생산성 런처 환경설정 (plist)
#   - WezTerm: GPU 가속 터미널 에뮬레이터 설정 (Lua)
#
# XDG 표준 경로 사용:
#   - xdg_configHome: ~/.config
#   - xdg_dataHome: ~/.local/share
#   - xdg_stateHome: ~/.local/state

{
  user,
  config,
  ...
}:

let
  userHome = "${config.users.users.${user}.home}";
  xdg_configHome = "${config.users.users.${user}.home}/.config";
in
{
  "${userHome}/.hammerspoon" = {
    source = ./config/hammerspoon;
    recursive = true;
  };

  "${xdg_configHome}/karabiner" = {
    source = ./config/karabiner;
    recursive = true;
  };

  "${userHome}/Library/Preferences/com.lwouis.alt-tab-macos.plist" = {
    source = ./config/alt-tab/com.lwouis.alt-tab-macos.plist;
  };

  "${userHome}/Library/Preferences/com.runningwithcrayons.Alfred.plist" = {
    source = ./config/alfred/com.runningwithcrayons.Alfred.plist;
  };

  # WezTerm configuration (restored from iTerm2)
  "${xdg_configHome}/wezterm/wezterm.lua" = {
    source = ./config/wezterm/wezterm.lua;
  };

  # Keep iTerm2 config commented for backup
  # "${userHome}/Library/Application Support/iTerm2/DynamicProfiles/DynamicProfiles.json" = {
  #   source = ./config/iterm2/DynamicProfiles.json;
  # };

}
