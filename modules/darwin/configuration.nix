{ config, pkgs, ... }:

{
  users.users.baleen = {
    shell = pkgs.bashInteractive;
    home = "/Users/baleen";
  };

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
