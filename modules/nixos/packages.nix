{ pkgs }:

with pkgs;
let
  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };

  # Platform-specific packages
  platform-packages = [
    # NixOS-specific packages (cross-platform packages moved to shared/packages.nix)

    # Linux-specific app management
    appimage-run

    # Linux desktop productivity tools
    galculator

    # Linux audio tools
    pavucontrol # Pulse audio controls

    # Linux media tools
    vlc # Cross-platform media player (Linux only)
    font-manager # Font management application (Linux only)

    # Linux desktop and window management tools
    rofi
    rofi-calc
    libnotify
    pcmanfm # File browser
    xdg-utils

    # Linux desktop utilities
    yad # yad-calendar is used with polybar
    xdotool

    # PDF viewer (Linux-focused, though available on other platforms)
    zathura
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
