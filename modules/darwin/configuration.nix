{ config, pkgs, hostName, ... }: # hostName 추가

{
  users.users =
    if hostName == "baleen" then {
      baleen = {
        shell = pkgs.bashInteractive;
        home = "/Users/baleen";
      };
    } else if hostName == "jito" then {
      jito = {
        shell = pkgs.zsh; # Using zsh as it's your default shell
        home = "/Users/jito";
      };
    } else {}; # 다른 호스트 이름의 경우 빈 사용자 설정을 반환하거나 오류 처리

  # 트랙패드 설정
  system.defaults = {
    # dock configurations
    dock = {
      autohide = true;
    };

        # system configurations
    NSGlobalDomain = {
      AppleShowAllFiles = true;
      AppleInterfaceStyleSwitchesAutomatically = false;
      AppleICUForce24HourTime = true;
      AppleShowAllExtensions = true;

      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;

      InitialKeyRepeat = 15;
      KeyRepeat = 1;
      NSWindowResizeTime = null;
      NSAutomaticWindowAnimationsEnabled = false;

      "com.apple.trackpad.scaling" = 3.0;
    };

  };
  system.defaults.NSGlobalDomain = {
  };

  system.stateVersion = 6;
}
