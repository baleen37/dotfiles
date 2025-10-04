# Alacritty 터미널 에뮬레이터 설정
#
# Alacritty 터미널의 폰트, 색상, 윈도우 설정을 관리하는 모듈
#
# 주요 설정:
#   - 폰트: MesloLGS NF (Powerline 글리프 지원)
#       - Linux: 10pt
#       - macOS: 14pt
#   - 색상 스킴: 커스텀 다크 테마 (Ocean 기반)
#   - 커서: Block 스타일
#   - 윈도우: 불투명도 100%, 패딩 24px
#   - 동적 패딩: 윈도우 크기에 따라 자동 조정
#
# 색상 팔레트:
#   - 배경: #1f2528 (어두운 청회색)
#   - 전경: #c0c5ce (밝은 회색)
#   - Normal: 표준 ANSI 색상
#   - Bright: 밝은 ANSI 색상
#
# VERSION: 3.1.0 (Extracted from terminal.nix)
# LAST UPDATED: 2024-10-04

{ config
, pkgs
, lib
, platformInfo
, userInfo
, ...
}:

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
