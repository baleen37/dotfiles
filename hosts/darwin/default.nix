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
    ../../modules/shared
  ];

  nix = {
    enable = false;  # Determinate Nix와의 충돌 방지
    package = pkgs.nix;

    settings = {
      trusted-users = [ "@admin" "${user}" ];
      # substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      # trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };

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
