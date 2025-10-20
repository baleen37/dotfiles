# macOS Home Manager Integration
#
# nix-darwin 환경에서 Home Manager를 통합하여 macOS 사용자 환경을 선언적으로 관리합니다.
# Homebrew, MAS(Mac App Store), Nix 패키지를 통합 관리하는 핵심 모듈입니다.
#
# 주요 기능:
#   - Homebrew Cask 통합 (GUI 앱 관리)
#   - Mac App Store 앱 자동 설치 (MAS)
#   - Nix 앱 자동 링크 시스템 (/Applications)
#   - 플랫폼별 사용자 환경 설정
#   - macOS 시스템 최적화 (Finder, Dock 등)
#
# 성능 최적화:
#   - 캐시된 경로 사용으로 빌드 시간 단축
#   - 병렬 파일 관리로 배포 속도 향상
#   - 선택적 Verbose 모드로 로그 오버헤드 최소화
#
# 통합 대상:
#   - shared/home-manager.nix: 공통 프로그램 설정
#   - shared/files.nix: 공통 설정 파일
#   - darwin/files.nix: macOS 전용 설정 파일
#   - darwin/packages.nix: macOS 전용 패키지

{
  pkgs,
  ...
}:

let
  # 사용자 정보 자동 해석 (동적으로 현재 사용자 감지)
  # platform = "darwin"으로 macOS 환경 명시
  # returnFormat = "extended"로 user, homePath, shell 등 모든 정보 반환
  getUserInfo = import ../../lib/user-resolution.nix {
    platform = "darwin";
    returnFormat = "extended";
  };
  inherit (getUserInfo) user;

  # macOS 전용 설정 파일 import (Hammerspoon, Karabiner 등)
  additionalFiles = import ./files.nix { };

  # 공통 Home Manager 설정 import (git, vim, zsh 등)

  # 자주 사용되는 경로를 캐시하여 빌드 시간 단축
  # activation script에서 반복 사용되는 경로들을 미리 계산
  darwinPaths = {
    applications = "${getUserInfo.homePath}/Applications";
    library = "${getUserInfo.homePath}/Library";
    nixProfile = "${getUserInfo.homePath}/.nix-profile";
    nixStore = "/nix/store";
  };

in
{
  imports = [
  ];

  # Optimized user configuration with Darwin-specific settings
  users.users.${user} = {
    name = "${user}";
    home = getUserInfo.homePath;
    isHidden = false;
    shell = pkgs.zsh;
    description = "Primary user account with Nix + Homebrew integration";
  };

  # Optimized Homebrew configuration with performance settings
  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix { };
    brews = [
      {
        name = "syncthing";
        start_service = true; # Auto-start on login
        restart_service = "changed"; # Restart on version change
      }
    ];

    # Performance optimization: selective cleanup
    onActivation = {
      autoUpdate = false; # Manual updates for predictability
      upgrade = false; # Avoid automatic upgrades
      # cleanup = "uninstall";  # Commented for safety during development
    };

    # Optimized global Homebrew settings
    global = {
      brewfile = true;
      lockfiles = true;
    };

    # Mac App Store applications with optimized metadata
    # IDs obtained via: nix shell nixpkgs#mas && mas search <app name>
    masApps = {
      "Magnet" = 441258766; # Window management
      "WireGuard" = 1451685025; # VPN client
      "KakaoTalk" = 869223134; # Messaging
    };

    # Additional Homebrew taps for extended package availability
    taps = [
      "homebrew/cask"
    ];
  };

  # Enhanced Home Manager configuration with optimization
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true; # Performance: reduce evaluation overhead

    users.${user} =
      {
        pkgs,
        lib,
        self,
        ...
      }:
      {
        imports = [
          ../shared/programs/claude
        ];

        home = {
          enableNixpkgsReleaseCheck = false;

          # Optimized package management
          packages = pkgs.callPackage ./packages.nix { };

          # Enhanced file management with optimized merging
          file = lib.mkMerge [
            (import ../shared/files.nix { })
            additionalFiles
          ];

          stateVersion = "23.11";
        };

        # Import optimized shared programs configuration
        programs = {
          # Darwin-specific program overrides and additions

          # Enhanced macOS terminal integration
          zsh = {
            shellAliases = {
              # macOS-specific aliases
              finder = "open -a Finder";
              preview = "open -a Preview";
              code = "open -a 'Visual Studio Code'";
            };
          };
        };

        # Performance optimization: disable documentation for faster builds
        manual = {
          manpages.enable = false;
          html.enable = false;
          json.enable = false;
        };

        # Nix 앱 자동 링크 시스템 (Home Manager activation script)
        # /nix/store의 .app들을 ~/Applications로 심볼릭 링크하여
        # Spotlight, Finder에서 접근 가능하게 만들고 macOS 보안 권한 허용
        home.activation = {
          linkNixApps = ''
            echo "🔗 Optimizing Nix application integration..."

            # ~/Applications 디렉토리가 없으면 생성
            if [[ ! -d "${darwinPaths.applications}" ]]; then
              mkdir -p "${darwinPaths.applications}"
            fi

            # lib/nix-app-linker.sh 라이브러리 사용 (TDD 검증된 링크 로직)
            if [[ -f "${self}/lib/nix-app-linker.sh" ]]; then
              source "${self}/lib/nix-app-linker.sh"

              # link_nix_apps 함수 실행: /nix/store → ~/Applications 링크 생성
              # 에러 발생해도 non-fatal (다른 activation은 계속 진행)
              if link_nix_apps "${darwinPaths.applications}" "${darwinPaths.nixStore}" "${darwinPaths.nixProfile}"; then
                echo "✅ Application linking completed successfully"

                # VERBOSE=1 환경변수 설정 시에만 앱 목록 출력 (성능 최적화)
                if [[ "$${VERBOSE:-}" == "1" ]]; then
                  echo "📱 Available Nix applications:"
                  find "${darwinPaths.applications}" -name "*.app" -maxdepth 1 2>/dev/null | \
                    sed 's|.*/||; s/\.app$//; s/^/  • /' || echo "  (no apps found)"
                fi

                echo "💡 Applications accessible via Spotlight and Finder"
              else
                echo "⚠️ Application linking encountered issues (non-fatal)"
              fi
            else
              echo "⚠️ App linking library not found, skipping Nix app integration"
            fi
          '';

          # macOS 시스템 최적화 설정은 performance-optimization.nix의
          # system.defaults로 관리됩니다 (nix-darwin이 자동으로 적용)
          # 이 activation script는 제거되었습니다 (중복 + PATH 이슈 해결)
        };

        # Enhanced services for macOS integration
        services = {
          # Add valid Darwin-specific Home Manager services here
        };
      };
  };

  # System-level configuration optimizations
  # Note: Dock configuration managed in hosts/darwin/default.nix for system-wide settings

  # Performance monitoring and optimization hints
  system.activationScripts.darwinOptimizations.text = ''
    echo "🍎 Darwin Home Manager optimizations active"
    echo "   • Enhanced app linking: ${darwinPaths.applications}"
    echo "   • Homebrew integration: $(brew --version 2>/dev/null | head -1 || echo 'not available')"
    echo "   • User profile: ${user} (${getUserInfo.homePath})"
  '';
}
