# macOS-Specific Package Definitions
#
# macOS 플랫폼에 특화된 Nix 패키지 목록을 정의합니다.
# shared/packages.nix의 공통 패키지에 macOS 전용 패키지를 추가합니다.
#
# 특징:
#   - Karabiner-Elements v14 커스텀 빌드 포함
#   - dockutil 등 macOS 시스템 도구 제공
#   - shared 패키지와 병합되어 최종 패키지 목록 생성

{ pkgs }:

with pkgs;
let
  # Custom karabiner-elements version 14 (Darwin-only)
  karabiner-elements-14 = karabiner-elements.overrideAttrs (_oldAttrs: {
    version = "14.13.0";
    src = fetchurl {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
      sha256 = "1g3c7jb0q5ag3ppcpalfylhq1x789nnrm767m2wzjkbz3fi70ql2"; # pragma: allowlist secret
    };
  });

  # Import shared packages directly
  shared-packages = import ../shared/packages.nix { inherit pkgs; };

  # Platform-specific packages
  platform-packages = [
    dockutil
    karabiner-elements-14 # Advanced keyboard customizer for macOS (version 14)
  ];
in
# Use the standardized merging pattern
shared-packages ++ platform-packages
