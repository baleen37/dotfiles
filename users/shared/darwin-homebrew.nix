# Homebrew Configuration
#
# GUI applications and Mac App Store apps managed via Homebrew.
# Casks, brews, taps, and MAS apps.

{ ... }:

let
  # Homebrew Cask definitions (GUI applications)
  homebrew-casks = [
    # Development Tools
    "datagrip" # Database IDE from JetBrains
    "ghostty" # GPU-accelerated terminal emulator
    "utm" # Virtual machine manager for macOS

    # Fonts
    "font-jetbrains-mono" # JetBrains Mono font for terminal

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
    "orbstack" # Docker and Linux VM management
    "tailscale-app" # VPN mesh network with GUI
    "teleport-connect" # Teleport GUI client for secure infrastructure access

    # Entertainment Tools
    "vlc"

    # Study Tools
    "anki"

    # Productivity Tools
    "alfred"
    "raycast"

    # Password Management
    "1password"
    "1password-cli"

    # Browsers
    "google-chrome"
    "brave-browser"
    "firefox"

    "hammerspoon"
  ];
in
{
  # Optimized Homebrew setup for development workflow with performance considerations
  homebrew = {
    enable = true;
    casks = homebrew-casks;

    # Development Services Configuration
    brews = [
      "daipeihust/tap/im-select" # Switch input method from terminal (for Obsidian Vim IME control)
    ];

    # Performance Optimization: Selective Cleanup Strategy
    # Prevents unexpected interruptions during development while maintaining system hygiene
    onActivation = {
      autoUpdate = false; # Manual updates for predictability and control
      upgrade = false; # Avoid automatic upgrades during system rebuilds
      # cleanup = "uninstall";  # Commented for safety during development - enable when needed
    };

    # Optimized Global Homebrew Settings
    # Enhances package management efficiency and dependency tracking
    global = {
      brewfile = true; # Enable Brewfile support for reproducible setups
    };

    # Mac App Store Applications (Optimized Metadata)
    # Carefully selected apps for development productivity and system management
    # IDs obtained via: nix shell nixpkgs#mas && mas search <app name>
    masApps = {
      "Magnet" = 441258766; # Window management tool with multi-monitor support
      "KakaoTalk" = 869223134; # Communication platform (if needed)
    };

    # Extended Package Repository Access
    # Additional Homebrew taps for specialized packages and development tools
    # Note: homebrew/cask is now built into Homebrew by default (since 2023)
    taps = [
      "daipeihust/tap" # im-select
    ];
  };
}
