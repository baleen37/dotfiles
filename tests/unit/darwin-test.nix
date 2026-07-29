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
