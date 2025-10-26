# Alacritty terminal emulator configuration
#
# Alacritty terminal fonts, colors, and window settings
#
# Main settings:
#   - Font: MesloLGS NF (Powerline glyph support)
#       - Linux: 10pt
#       - macOS: 14pt
#   - Color scheme: Custom dark theme (Ocean-based)
#   - Cursor: Block style
#   - Window: 100% opacity, 24px padding
#   - Dynamic padding: Auto-adjust based on window size
#
# Color palette:
#   - Background: #1f2528 (dark blue-gray)
#   - Foreground: #c0c5ce (light gray)
#   - Normal: Standard ANSI colors
#   - Bright: Bright ANSI colors
#
# VERSION: 4.0.0 (Mitchell-style migration)
# LAST UPDATED: 2025-10-25

{ pkgs, lib, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      cursor = {
        style = "Block";
      };

      window = {
        opacity = 1.0;
        padding = {
          x = 24;
          y = 24;
        };
      };

      font = {
        normal = {
          family = "MesloLGS NF";
          style = "Regular";
        };
        size = lib.mkMerge [
          (lib.mkIf pkgs.stdenv.hostPlatform.isLinux 10)
          (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin 14)
        ];
      };

      dynamic_padding = true;
      decorations = "full";
      title = "Terminal";
      class = {
        instance = "Alacritty";
        general = "Alacritty";
      };

      colors = {
        primary = {
          background = "0x1f2528";
          foreground = "0xc0c5ce";
        };

        normal = {
          black = "0x1f2528";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xc0c5ce";
        };

        bright = {
          black = "0x65737e";
          red = "0xec5f67";
          green = "0x99c794";
          yellow = "0xfac863";
          blue = "0x6699cc";
          magenta = "0xc594c5";
          cyan = "0x5fb3b3";
          white = "0xd8dee9";
        };
      };
    };
  };
}
