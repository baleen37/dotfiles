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

    # nix-community.cachix.org 활용을 위한 trusted-users 설정
    settings = {
      trusted-users = [ "root" "@admin" user ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };


  environment.systemPackages = with pkgs;
    (import ../../modules/shared/packages.nix { inherit pkgs; });

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
