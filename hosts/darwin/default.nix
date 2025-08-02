{ config, pkgs, lib, ... }:

let
  getUser = import ../../lib/user-resolution.nix {
    returnFormat = "string";
  };
  user = getUser;
in

{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/darwin/app-links.nix
    ../../modules/shared
  ];

  nix = {
    enable = false;  # Determinate Nix와 충돌 방지를 위해 비활성화
    # package = pkgs.nix;  # Determinate가 관리하므로 비활성화

    # gc = {
    #   automatic = false;  # nix.enable = false일 때 자동 GC 비활성화
    #   interval = { Weekday = 0; Hour = 2; Minute = 0; };
    #   options = "--delete-older-than 30d";
    # };

    # 캐시 최적화를 위한 다중 substituters 설정
    settings = {
      trusted-users = [ "root" "@admin" user ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://devenv.cachix.org"
        "https://pre-commit-hooks.cachix.org"
        "https://numtide.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPiCgKpvNhFE8gvXv6bZg6RzjWUYqZFFI="
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmBo7Rc="
        "numtide.cachix.org-1:2ps1kLBUWjxIneOy2Oa9+LG8+NJf2XRAYsGGHghiZZ0="
      ];
      # 캐시 효율성 최적화 설정
      max-jobs = "auto";
      cores = 0; # 모든 CPU 코어 사용
      system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      keep-outputs = true;
      keep-derivations = true;
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      warn-dirty = false
      auto-optimise-store = true
      builders-use-substitutes = true
    '';
  };

  # zsh를 시스템에서 사용 가능한 쉘로 등록 (사용자 shell은 modules/darwin/home-manager.nix에서 설정됨)
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

  # Nix 앱들을 /Applications에 자동으로 심볼릭 링크 생성
  system.nixAppLinks = {
    enable = true;
    apps = [
      "Karabiner-Elements.app"
      # 필요한 다른 앱들을 여기에 추가 가능
    ];
  };

  system = {
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;

    activationScripts.postActivation.text = ''
      # Nix 설정 상태 확인 및 피드백
      echo "Checking Nix configuration..."

      # nix-community.cachix.org 캐시 활용 상태 확인
      if nix show-config | grep -q "nix-community.cachix.org"; then
        echo "✅ nix-community.cachix.org substituter가 활성화되어 빌드 성능이 향상됩니다."
      else
        echo "⚠️  nix-community.cachix.org substituter가 비활성화되어 있습니다."
      fi

      # trusted-users 설정 확인
      if nix show-config | grep -q "trusted-users.*${user}"; then
        echo "✅ trusted-users 설정이 완료되어 substituter 경고가 제거됩니다."
      else
        echo "⚠️  trusted-users 설정이 누락되었습니다."
      fi

      echo ""

      # 한영키 전환을 Shift+Cmd+Space로 설정 (Nix 구현)
      ${(import ../../lib/keyboard-input-settings.nix { inherit pkgs lib; }).activationScript}

      # Trackpad Speed 설정 (실제 tracking speed 제어)
      echo "Setting trackpad speed to maximum..."
      defaults write com.apple.AppleMultitouchTrackpad TrackpadSpeed -int 5
      defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadSpeed -int 5

      # 추가 설정 안내
      echo ""
      echo "📝 추가 설정 안내:"
      echo "• Karabiner-Elements가 /Applications에 자동 링크되어 보안 권한 설정 가능"
      echo "• 시스템 설정에서 필요한 권한들을 허용해주세요"
      echo "• Nix trusted-users 설정이 완료되었습니다. 다음 빌드부터 경고 메시지가 줄어들 것입니다."
      echo ""
    '';

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        KeyRepeat = 2; # Values: 120, 90, 60, 30, 12, 6, 2
        InitialKeyRepeat = 15; # Values: 120, 94, 68, 35, 25, 15

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;

        # Trackpad tracking speed 설정 (0.0 ~ 3.0, 기본값: 1.0, 최대: 3.0)
        "com.apple.trackpad.scaling" = 3.0;

        # 추가 trackpad 설정 (더 빠른 동작을 위함)
        "com.apple.trackpad.enableSecondaryClick" = true;
        "com.apple.trackpad.forceClick" = true;
      };


      dock = {
        autohide = true;
        show-recents = false;
        launchanim = true;
        orientation = "bottom";
        tilesize = 48;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };
}
