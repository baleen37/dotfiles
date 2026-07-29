# tests/lib/darwin-test-helpers.nix
#
# Assertions over `system.defaults` in users/shared/darwin/default.nix.
#
# Settings are declared as attribute sets keyed by the real macOS preference
# key, so the test name is derived from the key rather than tracked alongside it.
# Tuned numeric values come from constants.nix; booleans are inline because the
# value is the whole meaning ("animations off").
{
  lib,
  helpers,
  constants,
  ...
}:

let
  pretty = lib.generators.toPretty { multiline = false; };

  # settings :: { <preference key> = <expected value>; }
  assertDefaults =
    domain: settings: darwinConfig:
    lib.mapAttrsToList (
      key: expected:
      helpers.assertTest "${domain}-${key}" (darwinConfig.system.defaults.${domain}.${key} == expected)
        "system.defaults.${domain}.${key} should be ${pretty expected}"
    ) settings;
in
{
  # UI animation, text substitution and key-repeat behaviour. All of these are
  # "off" because macOS defaults them on and they cost latency on every keystroke.
  assertGlobalDomainDefaults = assertDefaults "NSGlobalDomain" {
    NSAutomaticWindowAnimationsEnabled = false;
    NSScrollAnimationEnabled = false;
    NSWindowResizeTime = constants.darwinWindowResizeTime;

    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    ApplePressAndHoldEnabled = false;

    # Let macOS reclaim idle apps, and keep new documents off iCloud.
    NSDisableAutomaticTermination = false;
    NSDocumentSaveNewDocumentsToCloud = false;

    # Swipe-to-navigate fires accidentally while scrolling horizontally.
    AppleEnableMouseSwipeNavigateWithScrolls = false;
    AppleEnableSwipeNavigateWithScrolls = false;
    AppleFontSmoothing = constants.darwinFontSmoothing;
    NSNavPanelExpandedStateForSaveMode = false;
    NSNavPanelExpandedStateForSaveMode2 = false;
  };

  assertDockDefaults = assertDefaults "dock" {
    autohide = true;
    autohide-delay = constants.darwinDockAutohideDelay;
    autohide-time-modifier = constants.darwinDockAutohideTimeModifier;
    expose-animation-duration = constants.darwinExposeAnimationDuration;
    tilesize = constants.darwinDockTileSize;
    # Spaces that reorder themselves make keyboard switching unpredictable.
    mru-spaces = false;
  };

  assertFinderDefaults = assertDefaults "finder" {
    AppleShowAllFiles = true;
    FXEnableExtensionChangeWarning = false;
    _FXSortFoldersFirst = true;
    ShowPathbar = true;
    ShowStatusBar = true;
  };

  assertTrackpadDefaults = assertDefaults "trackpad" {
    Clicking = true;
    TrackpadRightClick = true;
    TrackpadThreeFingerDrag = true;
  };

  assertLoginWindowDefaults = assertDefaults "loginwindow" {
    SHOWFULLNAME = false;
    DisableConsoleAccess = false;
  };

  assertSpacesDefaults = assertDefaults "spaces" {
    spans-displays = false;
  };

  assertSystemPrimaryUser =
    expectedUser: darwinConfig:
    helpers.assertTest "system-primary-user" (darwinConfig.system.primaryUser == expectedUser)
      "system.primaryUser should follow currentSystemUser (${expectedUser})";

  assertDocumentationDisabled =
    darwinConfig:
    helpers.assertTest "documentation-disabled" (darwinConfig.documentation.enable == false)
      "documentation.enable should stay false; building man pages dominates switch time";

  # Asserts on postActivation's text rather than on the presence of an attribute.
  # nix-darwin splices only a fixed set of segment names into the script it runs,
  # so a custom `system.activationScripts.<name>` evaluates fine while never
  # executing -- and an attribute-presence check passes in exactly that case,
  # which is how this script stayed dead for as long as it did.
  assertCleanupScriptConfigured =
    darwinConfig:
    helpers.assertTest "cleanup-script-in-post-activation" (
      lib.hasInfix "GarageBand.app" darwinConfig.system.activationScripts.postActivation.text
    ) "App cleanup must live in the postActivation segment so nix-darwin actually runs it";
}
