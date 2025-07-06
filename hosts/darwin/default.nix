{ config, pkgs, ... }:

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
    enable = false;  # Determinate Nix가 nix 설정 관리
    package = pkgs.nix;

    # Determinate Nix가 자동으로 관리하므로 settings 제거
    # trusted-users, substituters, trusted-public-keys 모두 자동 설정됨

    gc = {
      automatic = false;  # nix.enable = false일 때는 자동 GC 비활성화
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
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
      # 한영키 전환을 Shift+Cmd+Space로 설정
      echo "Setting up Korean input switching to Shift+Cmd+Space..."

      # HIToolbox의 AppleSymbolicHotKeys 설정
      ${pkgs.python3}/bin/python3 -c "
import plistlib
import os

plist_path = os.path.expanduser('~/Library/Preferences/com.apple.HIToolbox.plist')

try:
    with open(plist_path, 'rb') as f:
        data = plistlib.load(f)
except FileNotFoundError:
    data = {}

if 'AppleSymbolicHotKeys' not in data:
    data['AppleSymbolicHotKeys'] = {}

# 키 ID 60과 61을 Shift+Cmd+Space로 설정
for key_id in ['60', '61']:
    data['AppleSymbolicHotKeys'][key_id] = {
        'enabled': True,
        'value': {
            'parameters': [49, 49, 1179648],  # Space (49) + Shift+Cmd (1179648)
            'type': 'standard'
        }
    }

with open(plist_path, 'wb') as f:
    plistlib.dump(data, f)

print('Korean input switching configured successfully')
"

      # 추가 설정 안내
      echo ""
      echo "📝 추가 설정 안내:"
      echo "• Karabiner-Elements가 /Applications에 자동 링크되어 보안 권한 설정 가능"
      echo "• 시스템 설정에서 필요한 권한들을 허용해주세요"
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
