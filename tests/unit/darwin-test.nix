# tests/unit/darwin-test.nix
#
# Covers users/shared/darwin/{default,homebrew,scripts}.nix.
#
# default.nix declares its siblings via `imports`, which only the module system
# expands, so the three files are merged by hand here — that is why the config
# below is a plain attribute set rather than an evaluated configuration.
#
# Values that were deliberately tuned live in tests/lib/constants.nix; the
# grouped `system.defaults` assertions are in tests/lib/darwin-test-helpers.nix.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  assertions = import ../lib/common-assertions.nix { inherit pkgs lib; };
  constants = import ../lib/constants.nix { inherit pkgs lib; };
  darwinHelpers = import ../lib/darwin-test-helpers.nix {
    inherit
      pkgs
      lib
      helpers
      constants
      ;
  };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };

  testUser = "baleen";

  darwinConfig =
    lib.recursiveUpdate
      (lib.recursiveUpdate (import ../../users/shared/darwin/default.nix {
        inherit pkgs lib;
        config = mockConfig.mkEmptyConfig;
        currentSystemUser = testUser;
      }) (import ../../users/shared/darwin/homebrew.nix { }))
      (import ../../users/shared/darwin/scripts.nix { });

  customPrefs = darwinConfig.system.defaults.CustomUserPreferences;
  multitouch = customPrefs."com.apple.AppleMultitouchTrackpad";
  bluetooth = customPrefs."com.apple.driver.AppleBluetoothMultitouch.trackpad";

  # Bound rather than inlined so each condition below stays a single short line:
  # nixfmt reflows multi-line operator chains, and the threshold at which it joins
  # or splits them is not worth guessing at.
  homebrewCasks = darwinConfig.homebrew.casks;
  homebrewTaps = darwinConfig.homebrew.taps;
  preActivationText = (darwinConfig.system.activationScripts.preActivation or { text = ""; }).text;
  homebrewExtraConfig = darwinConfig.homebrew.extraConfig;
  forceClick = customPrefs.NSGlobalDomain."com.apple.trackpad.forceClick";
  tapGesture = multitouch.TrackpadThreeFingerTapGesture;
  btTapGesture = bluetooth.TrackpadThreeFingerTapGesture;

  forceClickUsable = forceClick == true && multitouch.ForceSuppressed == 0;
  threeFingerTapOff = tapGesture == 0 && btTapGesture == 0;

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "darwin" (
    darwinHelpers.assertGlobalDomainDefaults darwinConfig
    ++ darwinHelpers.assertDockDefaults darwinConfig
    ++ darwinHelpers.assertFinderDefaults darwinConfig
    ++ darwinHelpers.assertTrackpadDefaults darwinConfig
    ++ darwinHelpers.assertLoginWindowDefaults darwinConfig
    ++ darwinHelpers.assertSpacesDefaults darwinConfig
    ++ [
      (darwinHelpers.assertSystemPrimaryUser testUser darwinConfig)
      (darwinHelpers.assertDocumentationDisabled darwinConfig)
      (darwinHelpers.assertCleanupScriptConfigured darwinConfig)

      # Homebrew supplies the GUI apps; an empty cask list means a switch would
      # silently uninstall all of them.
      (assertions.assertAttrEquals "homebrew-enabled" darwinConfig.homebrew "enable" true null)
      (assertions.assertListNotEmpty "homebrew-casks-not-empty" homebrewCasks null)

      (helpers.assertTest "switch-cask-configured" (
        lib.elem "Sanyam-G/switch/switch" homebrewCasks && lib.elem "Sanyam-G/switch" homebrewTaps
      ) "Switch should be installed from its Homebrew tap")

      (helpers.assertTest "magnet-not-configured" (
        !(darwinConfig.homebrew.masApps ? Magnet)
        && !(lib.hasInfix "Magnet.app" preActivationText)
        && !(lib.hasInfix "441258766" homebrewExtraConfig)
      ) "Magnet should not be managed after switching to Hammerspoon")

      (helpers.assertTest "spotlight-indexing-for-mas" (
        lib.hasInfix "/usr/bin/mdutil -E -i on /" preActivationText
        && lib.hasInfix "/usr/bin/mdimport" preActivationText
        && lib.hasInfix "/Applications/KakaoTalk.app" preActivationText
      ) "Activation should enable Spotlight and index the configured MAS apps")

      (helpers.assertTest "spotlight-single-app-has-no-loop" (
        !(lib.hasInfix "for app in" preActivationText)
      ) "A single configured MAS app should not use a single-iteration loop")

      (helpers.assertTest "mas-existing-app-skip-configured" (
        lib.hasInfix "HOMEBREW_BUNDLE_MAS_SKIP" homebrewExtraConfig
        && lib.hasInfix "Applications/KakaoTalk.app" homebrewExtraConfig
        && lib.hasInfix "869223134" homebrewExtraConfig
      ) "Existing App Store apps should be skipped while Spotlight is unavailable")

      # FileVault makes loginwindow.autoLoginUser a no-op, so it must stay unset
      # rather than be set to something misleading.
      (helpers.assertTest "login-window-auto-login-unset" (
        !(darwinConfig.system.defaults.loginwindow ? autoLoginUser)
      ) "loginwindow.autoLoginUser should not be configured; FileVault ignores it")

      # One-finger force-click lookup is only reachable through
      # CustomUserPreferences, and three-finger tap has to be off or both
      # gestures fight over the same tap.
      (helpers.assertTest "trackpad-force-click-lookup-enabled" forceClickUsable
        "Force click lookup should be enabled and not suppressed"
      )

      (helpers.assertTest "trackpad-three-finger-lookup-disabled" threeFingerTapOff
        "Three-finger tap lookup should be disabled for both trackpad drivers"
      )
    ]
  );
}
