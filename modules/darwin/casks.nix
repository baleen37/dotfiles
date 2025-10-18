# macOS Homebrew Cask Definitions
#
# Homebrew Cask를 통해 설치되는 macOS GUI 애플리케이션 목록을 정의합니다.
# nix-homebrew 모듈과 통합되어 선언적으로 GUI 앱을 관리합니다.
#
# 카테고리:
#   - Development Tools: 개발 도구 (DataGrip, Docker Desktop, IntelliJ IDEA)
#   - Communication Tools: 커뮤니케이션 앱 (Discord, Slack, Zoom 등)
#   - Utility Tools: 유틸리티 (Alt-Tab, Claude, Karabiner, Tailscale 등)
#   - Entertainment Tools: 엔터테인먼트 (VLC)
#   - Study Tools: 학습 도구 (Anki)
#   - Productivity Tools: 생산성 도구 (Alfred)
#   - Password Management: 비밀번호 관리 (1Password)
#   - Browsers: 웹 브라우저 (Chrome, Brave, Firefox)
#   - Automation: 자동화 도구 (Hammerspoon)

_:

[
  # Development Tools
  "datagrip" # Database IDE from JetBrains
  "docker-desktop"
  "intellij-idea"

  # Communication Tools
  "discord"
  "notion"
  "slack"
  "telegram"
  "zoom"
  "obsidian"

  # Utility Tools
  "alt-tab"
  "claude"
  "karabiner-elements" # Key remapping and modification tool
  "tailscale-app" # VPN mesh network with GUI
  "teleport-connect" # Teleport GUI client for secure infrastructure access

  # Entertainment Tools
  "vlc"

  # Study Tools
  "anki"

  # Productivity Tools
  "alfred"

  # Password Management
  "1password"
  "1password-cli"

  # Browsers
  "google-chrome"
  "brave-browser"
  "firefox"

  "hammerspoon"
]
