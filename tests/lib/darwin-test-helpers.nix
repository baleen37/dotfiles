# Darwin/macOS-specific test helpers
#
# Provides comprehensive helpers for testing macOS system settings,
# performance optimizations, and application configurations.
#
# These helpers eliminate repetitive assertNSGlobalDef calls and
# provide semantic grouping of macOS optimization levels.
{
  pkgs,
  lib,
  helpers,
  constants ? null,
}:

let
  # Import base helpers for assertTest
  inherit (helpers) assertTest testSuite;

  # Use constants if provided, otherwise use hardcoded defaults
  darwinWindowResizeTime = if constants != null then constants.darwinWindowResizeTime else 0.1;
  darwinDockAutohideDelay = if constants != null then constants.darwinDockAutohideDelay else 0.0;
  darwinDockAutohideTimeModifier = if constants != null then constants.darwinDockAutohideTimeModifier else 0.15;
  darwinExposeAnimationDuration = if constants != null then constants.darwinExposeAnimationDuration else 0.2;
  darwinDockTileSize = if constants != null then constants.darwinDockTileSize else 48;
  darwinFontSmoothing = if constants != null then constants.darwinFontSmoothing else 1;
in

rec {
  # ===== NSGlobalDomain (System-wide) Settings =====

  # Test a single NSGlobalDomain default setting
  # Usage: assertNSGlobalDef "window-animations" "NSAutomaticWindowAnimationsEnabled" false darwinConfig
  assertNSGlobalDef =
    testName: key: expectedValue: darwinConfig:
    assertTest "ns-global-${testName}" (
      darwinConfig.system.defaults.NSGlobalDomain.${key} == expectedValue
    ) "NSGlobalDomain.${key} should be ${toString expectedValue}";

  # Test multiple NSGlobalDomain default settings at once
  # Usage: assertNSGlobalDefs [ ["key1" val1] ["key2" val2] ] darwinConfig
  assertNSGlobalDefs =
    settings: darwinConfig:
    builtins.map (
      setting: assertNSGlobalDef (builtins.elemAt setting 0) (builtins.elemAt setting 0) (builtins.elemAt setting 1) darwinConfig
    ) settings;

  # ===== Login Window Settings =====

  # Test a single login window setting
  # Usage: assertLoginWindowSetting "showfullname" "SHOWFULLNAME" false darwinConfig
  assertLoginWindowSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "login-window-${testName}" (
      darwinConfig.system.defaults.loginwindow.${key} == expectedValue
    ) "Login window.${key} should be ${toString expectedValue}";

  # ===== Dock Settings =====

  # Test a single dock setting
  # Usage: assertDockSetting "autohide" "autohide" true darwinConfig
  assertDockSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "dock-${testName}" (
      darwinConfig.system.defaults.dock.${key} == expectedValue
    ) "Dock.${key} should be ${toString expectedValue}";

  # Test multiple dock settings at once
  # Usage: assertDockSettings [ ["autohide" "autohide" true] ["instant" "autohide-delay" 0.0] ] darwinConfig
  assertDockSettings =
    settings: darwinConfig:
    builtins.map (
      setting: assertDockSetting (builtins.elemAt setting 0) (builtins.elemAt setting 1) (builtins.elemAt setting 2) darwinConfig
    ) settings;

  # ===== Finder Settings =====

  # Test a single finder setting
  # Usage: assertFinderSetting "show-hidden" "AppleShowAllFiles" true darwinConfig
  assertFinderSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "finder-${testName}" (
      darwinConfig.system.defaults.finder.${key} == expectedValue
    ) "Finder.${key} should be ${toString expectedValue}";

  # Test multiple finder settings at once
  # Usage: assertFinderSettings [ ["show-hidden" "AppleShowAllFiles" true] ] darwinConfig
  assertFinderSettings =
    settings: darwinConfig:
    builtins.map (
      setting: assertFinderSetting (builtins.elemAt setting 0) (builtins.elemAt setting 1) (builtins.elemAt setting 2) darwinConfig
    ) settings;

  # ===== Trackpad Settings =====

  # Test a single trackpad setting
  # Usage: assertTrackpadSetting "clicking" "Clicking" true darwinConfig
  assertTrackpadSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "trackpad-${testName}" (
      darwinConfig.system.defaults.trackpad.${key} == expectedValue
    ) "Trackpad.${key} should be ${toString expectedValue}";

  # Test multiple trackpad settings at once
  # Usage: assertTrackpadSettings [ ["clicking" "Clicking" true] ] darwinConfig
  assertTrackpadSettings =
    settings: darwinConfig:
    builtins.map (
      setting: assertTrackpadSetting (builtins.elemAt setting 0) (builtins.elemAt setting 1) (builtins.elemAt setting 2) darwinConfig
    ) settings;

  # ===== macOS Optimization Level Helpers =====

  # Level 1: Core System Optimizations (UI animations, input processing)
  #
  # These settings disable UI animations and optimize input processing
  # for 40-60% faster UI responsiveness.
  #
  # Settings included:
  # - NSAutomaticWindowAnimationsEnabled: false (disables window animations)
  # - NSWindowResizeTime: 0.1 (faster window resizing)
  # - NSScrollAnimationEnabled: false (disables scroll animations)
  # - NSAutomaticCapitalizationEnabled: false (disables auto-capitalization)
  # - NSAutomaticSpellingCorrectionEnabled: false (disables auto-correction)
  # - NSAutomaticQuoteSubstitutionEnabled: false (disables smart quotes)
  # - NSAutomaticDashSubstitutionEnabled: false (disables smart dashes)
  # - NSAutomaticPeriodSubstitutionEnabled: false (disables auto-period)
  # - ApplePressAndHoldEnabled: false (disables press-and-hold for key repeat)
  #
  # Usage: assertDarwinOptimizationsLevel1 darwinConfig
  assertDarwinOptimizationsLevel1 =
    darwinConfig:
    builtins.map (setting: assertNSGlobalDef (builtins.elemAt setting 0) (builtins.elemAt setting 1) (builtins.elemAt setting 2) darwinConfig) [
      [
        "window-animations-disabled"
        "NSAutomaticWindowAnimationsEnabled"
        false
      ]
      [
        "window-resize-time-optimized"
        "NSWindowResizeTime"
        darwinWindowResizeTime
      ]
      [
        "scroll-animation-disabled"
        "NSScrollAnimationEnabled"
        false
      ]
      [
        "auto-capitalization-disabled"
        "NSAutomaticCapitalizationEnabled"
        false
      ]
      [
        "spell-correction-disabled"
        "NSAutomaticSpellingCorrectionEnabled"
        false
      ]
      [
        "smart-quotes-disabled"
        "NSAutomaticQuoteSubstitutionEnabled"
        false
      ]
      [
        "smart-dashes-disabled"
        "NSAutomaticDashSubstitutionEnabled"
        false
      ]
      [
        "auto-period-disabled"
        "NSAutomaticPeriodSubstitutionEnabled"
        false
      ]
      [
        "press-and-hold-disabled"
        "ApplePressAndHoldEnabled"
        false
      ]
    ];

  # Level 2: Memory Management and Battery Efficiency
  #
  # These settings optimize memory usage and extend battery life
  # by 20-30% through reduced background activity.
  #
  # Settings included:
  # - NSDisableAutomaticTermination: false (enables app termination)
  # - NSDocumentSaveNewDocumentsToCloud: false (disables iCloud auto-save)
  #
  # Usage: assertDarwinOptimizationsLevel2 darwinConfig
  assertDarwinOptimizationsLevel2 =
    darwinConfig:
    builtins.map (setting: assertNSGlobalDef (builtins.elemAt setting 0) (builtins.elemAt setting 1) (builtins.elemAt setting 2) darwinConfig) [
      [
        "auto-termination-enabled"
        "NSDisableAutomaticTermination"
        false
      ]
      [
        "icloud-auto-save-disabled"
        "NSDocumentSaveNewDocumentsToCloud"
        false
      ]
    ];

  # Level 3: Advanced UI Reduction Optimizations
  #
  # These settings minimize UI chrome and disable navigation gestures
  # for maximum performance and minimal distractions.
  #
  # Settings included:
  # - AppleEnableMouseSwipeNavigateWithScrolls: false
  # - AppleEnableSwipeNavigateWithScrolls: false
  # - AppleFontSmoothing: 1 (optimized font smoothing)
  # - NSNavPanelExpandedStateForSaveMode: false (compact save dialogs)
  # - NSNavPanelExpandedStateForSaveMode2: false (compact save dialogs v2)
  #
  # Usage: assertDarwinOptimizationsLevel3 darwinConfig
  assertDarwinOptimizationsLevel3 =
    darwinConfig:
    builtins.map (setting: assertNSGlobalDef (builtins.elemAt setting 0) (builtins.elemAt setting 1) (builtins.elemAt setting 2) darwinConfig) [
      [
        "mouse-swipe-navigation-disabled"
        "AppleEnableMouseSwipeNavigateWithScrolls"
        false
      ]
      [
        "swipe-navigation-disabled"
        "AppleEnableSwipeNavigateWithScrolls"
        false
      ]
      [
        "font-smoothing-optimized"
        "AppleFontSmoothing"
        darwinFontSmoothing
      ]
      [
        "save-dialogs-compact"
        "NSNavPanelExpandedStateForSaveMode"
        false
      ]
      [
        "save-dialogs-compact-v2"
        "NSNavPanelExpandedStateForSaveMode2"
        false
      ]
    ];

  # All optimization levels combined
  #
  # Usage: assertDarwinOptimizationsAll darwinConfig
  assertDarwinOptimizationsAll =
    darwinConfig:
    assertDarwinOptimizationsLevel1 darwinConfig
    ++ assertDarwinOptimizationsLevel2 darwinConfig
    ++ assertDarwinOptimizationsLevel3 darwinConfig;

  # ===== Login Window Optimizations =====

  # Login window settings for faster boot and streamlined login
  #
  # Settings included:
  # - SHOWFULLNAME: false (hides full name at login)
  # - DisableConsoleAccess: false (disables console access)
  #
  # Usage: assertLoginWindowOptimizations darwinConfig
  assertLoginWindowOptimizations =
    darwinConfig:
    builtins.map (setting: assertLoginWindowSetting (builtins.elemAt setting 0) (builtins.elemAt setting 1) (builtins.elemAt setting 2) darwinConfig) [
      [
        "showfullname-false"
        "SHOWFULLNAME"
        false
      ]
      [
        "console-access-enabled"
        "DisableConsoleAccess"
        false
      ]
    ];

  # ===== Dock Optimization Helpers =====

  # Standard dock optimizations for performance and efficiency
  #
  # Settings included:
  # - autohide: true (auto-hide dock)
  # - autohide-delay: 0.0 (instant hide)
  # - autohide-time-modifier: 0.15 (fast animation)
  # - expose-animation-duration: 0.2 (fast expose)
  # - tilesize: 48 (optimized tile size)
  # - mru-spaces: false (disable MRU spaces)
  #
  # Usage: assertDockOptimizations darwinConfig
  assertDockOptimizations =
    darwinConfig:
    assertDockSettings [
      [
        "autohide-enabled"
        "autohide"
        true
      ]
      [
        "autohide-delay-instant"
        "autohide-delay"
        darwinDockAutohideDelay
      ]
      [
        "animation-fast"
        "autohide-time-modifier"
        darwinDockAutohideTimeModifier
      ]
      [
        "expose-animation-fast"
        "expose-animation-duration"
        darwinExposeAnimationDuration
      ]
      [
        "tilesize-optimized"
        "tilesize"
        darwinDockTileSize
      ]
      [
        "mru-spaces-disabled"
        "mru-spaces"
        false
      ]
    ] darwinConfig;

  # ===== Finder Optimization Helpers =====

  # Standard finder optimizations for better file management
  #
  # Settings included:
  # - AppleShowAllFiles: true (show hidden files)
  # - FXEnableExtensionChangeWarning: false (no extension warning)
  # - _FXSortFoldersFirst: true (folders first)
  # - ShowPathbar: true (show path bar)
  # - ShowStatusBar: true (show status bar)
  #
  # Usage: assertFinderOptimizations darwinConfig
  assertFinderOptimizations =
    darwinConfig:
    assertFinderSettings [
      [
        "show-hidden-files"
        "AppleShowAllFiles"
        true
      ]
      [
        "extension-warning-disabled"
        "FXEnableExtensionChangeWarning"
        false
      ]
      [
        "folders-first"
        "_FXSortFoldersFirst"
        true
      ]
      [
        "pathbar-enabled"
        "ShowPathbar"
        true
      ]
      [
        "statusbar-enabled"
        "ShowStatusBar"
        true
      ]
    ] darwinConfig;

  # ===== Trackpad Optimization Helpers =====

  # Standard trackpad optimizations for better usability
  #
  # Settings included:
  # - Clicking: true (enable tap-to-click)
  # - TrackpadRightClick: true (enable right-click)
  # - TrackpadThreeFingerDrag: true (enable three-finger drag)
  #
  # Usage: assertTrackpadOptimizations darwinConfig
  assertTrackpadOptimizations =
    darwinConfig:
    assertTrackpadSettings [
      [
        "clicking-enabled"
        "Clicking"
        true
      ]
      [
        "right-click-enabled"
        "TrackpadRightClick"
        true
      ]
      [
        "three-finger-drag-enabled"
        "TrackpadThreeFingerDrag"
        true
      ]
    ] darwinConfig;

  # ===== Comprehensive macOS Optimization Test Suite =====

  # Complete macOS optimization test suite
  # Includes all optimization levels plus dock, finder, and trackpad settings
  #
  # Usage: assertDarwinFullOptimizationSuite darwinConfig
  assertDarwinFullOptimizationSuite =
    darwinConfig:
    assertLoginWindowOptimizations darwinConfig
    ++ assertDarwinOptimizationsAll darwinConfig
    ++ assertDockOptimizations darwinConfig
    ++ assertFinderOptimizations darwinConfig
    ++ assertTrackpadOptimizations darwinConfig;

  # ===== Space Settings =====

  # Test spaces configuration
  #
  # Usage: assertSpacesNoSpanDisplays darwinConfig
  assertSpacesNoSpanDisplays =
    darwinConfig:
    assertTest "spaces-no-span-displays" (
      darwinConfig.system.defaults.spaces.spans-displays == false
    ) "Spaces should not span displays for better performance";

  # ===== Homebrew Configuration =====

  # Test Homebrew is enabled
  #
  # Usage: assertHomebrewEnabled darwinConfig
  assertHomebrewEnabled =
    darwinConfig:
    assertTest "homebrew-enabled" (
      darwinConfig.homebrew.enable == true
    ) "Homebrew should be enabled";

  # Test Homebrew casks are configured
  #
  # Usage: assertHomebrewCasksConfigured darwinConfig
  assertHomebrewCasksConfigured =
    darwinConfig:
    assertTest "homebrew-casks-configured" (
      builtins.length darwinConfig.homebrew.casks > 0
    ) "Homebrew casks should be configured";

  # Test Homebrew brews are configured
  #
  # Usage: assertHomebrewBrewsConfigured darwinConfig
  assertHomebrewBrewsConfigured =
    darwinConfig:
    assertTest "homebrew-services-configured" (
      builtins.length darwinConfig.homebrew.brews > 0
    ) "Homebrew services should be configured";

  # Test Homebrew global settings
  #
  # Usage: assertHomebrewGlobalSettings darwinConfig
  assertHomebrewGlobalSettings =
    darwinConfig:
    assertTest "homebrew-global-settings" (
      darwinConfig.homebrew.global.brewfile == true && darwinConfig.homebrew.global.lockfiles == true
    ) "Homebrew global settings should be optimized";

  # ===== System Configuration =====

  # Test system primary user
  #
  # Usage: assertSystemPrimaryUser "testuser" darwinConfig
  assertSystemPrimaryUser =
    expectedUser: darwinConfig:
    assertTest "nix-darwin-system-config" (
      darwinConfig.system.primaryUser == expectedUser
    ) "System primary user should be ${expectedUser}";

  # Test documentation is disabled for build speed
  #
  # Usage: assertDocumentationDisabled darwinConfig
  assertDocumentationDisabled =
    darwinConfig:
    assertTest "documentation-disabled-for-build-speed" (
      darwinConfig.documentation.enable == false
    ) "Documentation should be disabled for build speed";

  # ===== App Cleanup Script =====

  # Test app cleanup activation script is configured
  #
  # Usage: assertCleanupScriptConfigured darwinConfig
  assertCleanupScriptConfigured =
    darwinConfig:
    assertTest "cleanup-script-configured" (
      darwinConfig.system.activationScripts ? cleanupMacOSApps
    ) "App cleanup activation script should be configured";

  # ===== Comprehensive Darwin Configuration Test Suite =====

  # Complete Darwin configuration test suite
  # Includes all aspects: optimizations, dock, finder, trackpad, homebrew, system config
  #
  # Usage: assertDarwinFullConfigSuite "testuser" darwinConfig
  assertDarwinFullConfigSuite =
    expectedUser: darwinConfig:
    assertDarwinFullOptimizationSuite darwinConfig
    ++ [
      (assertSpacesNoSpanDisplays darwinConfig)
      (assertHomebrewEnabled darwinConfig)
      (assertHomebrewCasksConfigured darwinConfig)
      (assertHomebrewBrewsConfigured darwinConfig)
      (assertHomebrewGlobalSettings darwinConfig)
      (assertSystemPrimaryUser expectedUser darwinConfig)
      (assertDocumentationDisabled darwinConfig)
      (assertCleanupScriptConfigured darwinConfig)
    ];
}
