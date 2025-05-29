{ config, pkgs, hostName, ... }: # hostName 추가

let
  mkUser = { username, homeDirectory, shell }:
    { ${username} = { inherit shell; home = homeDirectory; }; };
in
{
  nixpkgs.config.allowUnfree = true;

  users.users =
    if hostName == "baleen" then
      mkUser { username = "baleen"; homeDirectory = "/Users/baleen"; shell = pkgs.bashInteractive; }
    else if hostName == "jito" then
      mkUser { username = "jito"; homeDirectory = "/Users/jito"; shell = pkgs.zsh; }
    else {}; # 다른 호스트 이름의 경우 빈 사용자 설정을 반환하거나 오류 처리

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

  system.stateVersion = 6;
}
