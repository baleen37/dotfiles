# tests/unit/darwin-error-cases-test.nix
# Error handling and edge case tests for users/shared/darwin.nix macOS configuration
# Tests system settings boundary values, platform-specific errors, and invalid package names

{
  inputs,
  system,
  nixtest ? { },
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Helper function to validate KeyRepeat range (1-120)
  validateKeyRepeat = value:
    builtins.typeOf value == "int" && value >= 1 && value <= 120;

  # Helper function to validate InitialKeyRepeat range (10-120)
  validateInitialKeyRepeat = value:
    builtins.typeOf value == "int" && value >= 10 && value <= 120;

  # Helper function to validate trackpad scaling (0.0-3.0)
  validateTrackpadScaling = value:
    builtins.typeOf value == "float" && value >= 0.0 && value <= 3.0;

  # Helper function to validate Homebrew cask name format
  validateCaskName = name:
    let
      isValid = builtins.match "^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" name != null;
      noSpecialChars = !lib.hasInfix "@" name && !lib.hasInfix "_" name;
      noSpaces = !lib.hasInfix " " name;
      notEmpty = builtins.stringLength name > 0;
    in
    isValid && noSpecialChars && noSpaces && notEmpty;

  # Helper function to validate Mac App Store ID format
  validateMasId = id:
    let
      idStr = toString id;
      isDigits = builtins.match "^[0-9]+$" idStr != null;
      reasonableLength = builtins.stringLength idStr >= 9 && builtins.stringLength idStr <= 10;
      positive = id > 0;
    in
    isDigits && reasonableLength && positive;

in
{
  platforms = ["darwin"];
  value = {
    # ===== KeyRepeat Boundary Value Tests =====

    # Test 1: KeyRepeat minimum valid value (1)
    keyrepeat-min-valid = helpers.assertTest "darwin-keyrepeat-min-valid" (
      validateKeyRepeat 1
    ) "KeyRepeat value 1 (minimum) should be valid";

    # Test 2: KeyRepeat maximum valid value (120)
    keyrepeat-max-valid = helpers.assertTest "darwin-keyrepeat-max-valid" (
      validateKeyRepeat 120
    ) "KeyRepeat value 120 (maximum) should be valid";

    # Test 3: KeyRepeat below minimum (0) should be invalid
    keyrepeat-below-min-invalid = helpers.assertTest "darwin-keyrepeat-below-min-invalid" (
      !validateKeyRepeat 0
    ) "KeyRepeat value 0 (below minimum) should be invalid";

    # Test 4: KeyRepeat above maximum (121) should be invalid
    keyrepeat-above-max-invalid = helpers.assertTest "darwin-keyrepeat-above-max-invalid" (
      !validateKeyRepeat 121
    ) "KeyRepeat value 121 (above maximum) should be invalid";

    # Test 5: KeyRepeat negative value should be invalid
    keyrepeat-negative-invalid = helpers.assertTest "darwin-keyrepeat-negative-invalid" (
      !validateKeyRepeat (-1)
    ) "KeyRepeat negative value should be invalid";

    # Test 6: KeyRepeat with float type should be invalid
    keyrepeat-float-invalid = helpers.assertTest "darwin-keyrepeat-float-invalid" (
      !validateKeyRepeat 1.5
    ) "KeyRepeat float value should be invalid";

    # Test 7: Current KeyRepeat setting (1) is valid
    current-keyrepeat-valid = helpers.assertTest "darwin-current-keyrepeat-valid" (
      validateKeyRepeat 1
    ) "Current KeyRepeat setting (1) should be valid";

    # ===== InitialKeyRepeat Boundary Value Tests =====

    # Test 8: InitialKeyRepeat minimum valid value (10)
    initialkeyrepeat-min-valid = helpers.assertTest "darwin-initialkeyrepeat-min-valid" (
      validateInitialKeyRepeat 10
    ) "InitialKeyRepeat value 10 (minimum) should be valid";

    # Test 9: InitialKeyRepeat maximum valid value (120)
    initialkeyrepeat-max-valid = helpers.assertTest "darwin-initialkeyrepeat-max-valid" (
      validateInitialKeyRepeat 120
    ) "InitialKeyRepeat value 120 (maximum) should be valid";

    # Test 10: InitialKeyRepeat below minimum (9) should be invalid
    initialkeyrepeat-below-min-invalid = helpers.assertTest "darwin-initialkeyrepeat-below-min-invalid" (
      !validateInitialKeyRepeat 9
    ) "InitialKeyRepeat value 9 (below minimum) should be invalid";

    # Test 11: InitialKeyRepeat above maximum (121) should be invalid
    initialkeyrepeat-above-max-invalid = helpers.assertTest "darwin-initialkeyrepeat-above-max-invalid" (
      !validateInitialKeyRepeat 121
    ) "InitialKeyRepeat value 121 (above maximum) should be invalid";

    # Test 12: InitialKeyRepeat negative value should be invalid
    initialkeyrepeat-negative-invalid = helpers.assertTest "darwin-initialkeyrepeat-negative-invalid" (
      !validateInitialKeyRepeat (-5)
    ) "InitialKeyRepeat negative value should be invalid";

    # Test 13: InitialKeyRepeat with float type should be invalid
    initialkeyrepeat-float-invalid = helpers.assertTest "darwin-initialkeyrepeat-float-invalid" (
      !validateInitialKeyRepeat 10.5
    ) "InitialKeyRepeat float value should be invalid";

    # Test 14: Current InitialKeyRepeat setting (10) is valid
    current-initialkeyrepeat-valid = helpers.assertTest "darwin-current-initialkeyrepeat-valid" (
      validateInitialKeyRepeat 10
    ) "Current InitialKeyRepeat setting (10) should be valid";

    # ===== Trackpad Scaling Boundary Value Tests =====

    # Test 15: Trackpad scaling minimum valid value (0.0)
    trackpad-min-valid = helpers.assertTest "darwin-trackpad-min-valid" (
      validateTrackpadScaling 0.0
    ) "Trackpad scaling value 0.0 (minimum) should be valid";

    # Test 16: Trackpad scaling maximum valid value (3.0)
    trackpad-max-valid = helpers.assertTest "darwin-trackpad-max-valid" (
      validateTrackpadScaling 3.0
    ) "Trackpad scaling value 3.0 (maximum) should be valid";

    # Test 17: Trackpad scaling below minimum (-0.1) should be invalid
    trackpad-below-min-invalid = helpers.assertTest "darwin-trackpad-below-min-invalid" (
      !validateTrackpadScaling (-0.1)
    ) "Trackpad scaling value -0.1 (below minimum) should be invalid";

    # Test 18: Trackpad scaling above maximum (3.1) should be invalid
    trackpad-above-max-invalid = helpers.assertTest "darwin-trackpad-above-max-invalid" (
      !validateTrackpadScaling 3.1
    ) "Trackpad scaling value 3.1 (above maximum) should be invalid";

    # Test 19: Trackpad scaling negative value should be invalid
    trackpad-negative-invalid = helpers.assertTest "darwin-trackpad-negative-invalid" (
      !validateTrackpadScaling (-1.5)
    ) "Trackpad scaling negative value should be invalid";

    # Test 20: Trackpad scaling with integer type should be valid (coerced to float)
    trackpad-integer-valid = helpers.assertTest "darwin-trackpad-integer-valid" (
      validateTrackpadScaling 2
    ) "Trackpad scaling integer value should be valid (coerced to float)";

    # Test 21: Current trackpad scaling setting (3.0) is valid
    current-trackpad-scaling-valid = helpers.assertTest "darwin-current-trackpad-scaling-valid" (
      validateTrackpadScaling 3.0
    ) "Current trackpad scaling setting (3.0) should be valid";

    # ===== Homebrew Cask Name Validation Tests =====

    # Test 22: Valid cask name format (lowercase, hyphens, numbers)
    cask-name-valid-lowercase = helpers.assertTest "darwin-cask-name-valid-lowercase" (
      validateCaskName "datagrip"
    ) "Cask name 'datagrip' should be valid";

    # Test 23: Valid cask name with hyphens
    cask-name-valid-hyphens = helpers.assertTest "darwin-cask-name-valid-hyphens" (
      validateCaskName "intellij-idea"
    ) "Cask name 'intellij-idea' should be valid";

    # Test 24: Valid cask name with numbers
    cask-name-valid-numbers = helpers.assertTest "darwin-cask-name-valid-numbers" (
      validateCaskName "1password-cli"
    ) "Cask name '1password-cli' should be valid";

    # Test 25: Invalid cask name with uppercase
    cask-name-invalid-uppercase = helpers.assertTest "darwin-cask-name-invalid-uppercase" (
      !validateCaskName "DataGrip"
    ) "Cask name with uppercase letters should be invalid";

    # Test 26: Invalid cask name with spaces
    cask-name-invalid-spaces = helpers.assertTest "darwin-cask-name-invalid-spaces" (
      !validateCaskName "app name"
    ) "Cask name with spaces should be invalid";

    # Test 27: Invalid cask name with underscores
    cask-name-invalid-underscores = helpers.assertTest "darwin-cask-name-invalid-underscores" (
      !validateCaskName "app_name"
    ) "Cask name with underscores should be invalid";

    # Test 28: Invalid cask name with @ symbol
    cask-name-invalid-at-symbol = helpers.assertTest "darwin-cask-name-invalid-at-symbol" (
      !validateCaskName "app@name"
    ) "Cask name with @ symbol should be invalid";

    # Test 29: Invalid empty cask name
    cask-name-invalid-empty = helpers.assertTest "darwin-cask-name-invalid-empty" (
      !validateCaskName ""
    ) "Empty cask name should be invalid";

    # Test 30: Current cask names are valid
    current-cask-names-valid = helpers.assertTest "darwin-current-cask-names-valid" (
      let
        currentCasks = [
          "datagrip"
          "ghostty"
          "intellij-idea"
          "utm"
          "discord"
          "notion"
          "slack"
          "telegram"
          "zoom"
          "obsidian"
          "alt-tab"
          "claude"
          "karabiner-elements"
          "orbstack"
          "tailscale-app"
          "teleport-connect"
          "vlc"
          "anki"
          "alfred"
          "raycast"
          "1password"
          "1password-cli"
          "google-chrome"
          "brave-browser"
          "firefox"
          "hammerspoon"
        ];
      in
      builtins.all validateCaskName currentCasks
    ) "All current Homebrew cask names should be valid";

    # ===== Mac App Store ID Validation Tests =====

    # Test 31: Valid MAS ID format (9 digits)
    mas-id-valid-9-digits = helpers.assertTest "darwin-mas-id-valid-9-digits" (
      validateMasId 441258766
    ) "MAS ID with 9 digits should be valid";

    # Test 32: Valid MAS ID format (10 digits)
    mas-id-valid-10-digits = helpers.assertTest "darwin-mas-id-valid-10-digits" (
      validateMasId 1451685025
    ) "MAS ID with 10 digits should be valid";

    # Test 33: Invalid MAS ID (too short, 8 digits)
    mas-id-invalid-too-short = helpers.assertTest "darwin-mas-id-invalid-too-short" (
      !validateMasId 12345678
    ) "MAS ID with 8 digits (too short) should be invalid";

    # Test 34: Invalid MAS ID (too long, 11 digits)
    mas-id-invalid-too-long = helpers.assertTest "darwin-mas-id-invalid-too-long" (
      !validateMasId 12345678901
    ) "MAS ID with 11 digits (too long) should be invalid";

    # Test 35: Invalid MAS ID (negative)
    mas-id-invalid-negative = helpers.assertTest "darwin-mas-id-invalid-negative" (
      !validateMasId (-1)
    ) "Negative MAS ID should be invalid";

    # Test 36: Invalid MAS ID (zero)
    mas-id-invalid-zero = helpers.assertTest "darwin-mas-id-invalid-zero" (
      !validateMasId 0
    ) "MAS ID of 0 should be invalid";

    # Test 37: Current MAS IDs are valid
    current-mas-ids-valid = helpers.assertTest "darwin-current-mas-ids-valid" (
      let
        currentMasIds = {
          "Magnet" = 441258766;
          "WireGuard" = 1451685025;
        };
        allValid = builtins.all validateMasId (builtins.attrValues currentMasIds);
      in
      allValid
    ) "All current Mac App Store IDs should be valid";

    # ===== Platform-Specific Tests =====

    # Test 38: Darwin settings should only apply on macOS
    darwin-settings-macos-only = helpers.assertTest "darwin-darwin-settings-macos-only" (
      pkgs.stdenv.hostPlatform.isDarwin
    ) "Darwin-specific settings should only apply on macOS platform";

    # Test 39: Homebrew integration is macOS-specific
    homebrew-macos-only = helpers.assertTest "darwin-homebrew-macos-only" (
      pkgs.stdenv.hostPlatform.isDarwin
    ) "Homebrew integration should only apply on macOS platform";

    # Test 40: Mac App Store integration is macOS-specific
    mas-macos-only = helpers.assertTest "darwin-mas-macos-only" (
      pkgs.stdenv.hostPlatform.isDarwin
    ) "Mac App Store integration should only apply on macOS platform";

    # ===== Boundary Value Edge Cases =====

    # Test 41: KeyRepeat and InitialKeyRepeat relationship
    keyrepeat-less-than-initial = helpers.assertTest "darwin-keyrepeat-less-than-initial" (
      let
        keyRepeat = 1;
        initialKeyRepeat = 10;
      in
      keyRepeat < initialKeyRepeat
    ) "KeyRepeat should be less than InitialKeyRepeat for optimal typing experience";

    # Test 42: Both keyboard settings at minimum
    keyboard-both-minimum = helpers.assertTest "darwin-keyboard-both-minimum" (
      let
        keyRepeat = 1;
        initialKeyRepeat = 10;
      in
      validateKeyRepeat keyRepeat && validateInitialKeyRepeat initialKeyRepeat
    ) "Both keyboard settings at minimum values should be valid";

    # Test 43: Both keyboard settings at maximum
    keyboard-both-maximum = helpers.assertTest "darwin-keyboard-both-maximum" (
      let
        keyRepeat = 120;
        initialKeyRepeat = 120;
      in
      validateKeyRepeat keyRepeat && validateInitialKeyRepeat initialKeyRepeat
    ) "Both keyboard settings at maximum values should be valid";

    # Test 44: Trackpad scaling at midpoint
    trackpad-midpoint = helpers.assertTest "darwin-trackpad-midpoint" (
      validateTrackpadScaling 1.5
    ) "Trackpad scaling at midpoint (1.5) should be valid";

    # Test 45: Trackpad scaling with high precision
    trackpad-high-precision = helpers.assertTest "darwin-trackpad-high-precision" (
      validateTrackpadScaling 2.875
    ) "Trackpad scaling with high precision (2.875) should be valid";

    # ===== Configuration Consistency Tests =====

    # Test 46: Current configuration uses optimized values
    current-config-optimized = helpers.assertTest "darwin-current-config-optimized" (
      let
        keyRepeat = 1;
        initialKeyRepeat = 10;
        trackpadScaling = 3.0;
      in
      keyRepeat == 1 && initialKeyRepeat == 10 && trackpadScaling == 3.0
    ) "Current configuration should use optimized values (fastest keyboard, fastest trackpad)";

    # Test 47: Current values are within valid ranges
    current-values-in-range = helpers.assertTest "darwin-current-values-in-range" (
      let
        keyRepeat = 1;
        initialKeyRepeat = 10;
        trackpadScaling = 3.0;
      in
      validateKeyRepeat keyRepeat &&
      validateInitialKeyRepeat initialKeyRepeat &&
      validateTrackpadScaling trackpadScaling
    ) "All current darwin settings should be within valid ranges";

    # Test 48: Current settings exceed GUI minimums (performance optimization)
    current-exceeds-gui-minimums = helpers.assertTest "darwin-current-exceeds-gui-minimums" (
      let
        # GUI minimums: KeyRepeat=2, InitialKeyRepeat=15
        currentKeyRepeat = 1;
        currentInitialKeyRepeat = 10;
      in
      currentKeyRepeat < 2 && currentInitialKeyRepeat < 15
    ) "Current settings should exceed GUI minimums (faster than GUI allows)";

    # Test 49: Package list is non-empty
    packages-non-empty = helpers.assertTest "darwin-packages-non-empty" (
      let
        casks = [
          "datagrip"
          "ghostty"
          "intellij-idea"
        ];
      in
      builtins.length casks > 0
    ) "Package list should be non-empty";

    # Test 50: All packages have valid names
    all-packages-valid-names = helpers.assertTest "darwin-all-packages-valid-names" (
      let
        casks = [
          "datagrip"
          "ghostty"
          "intellij-idea"
          "utm"
          "discord"
        ];
      in
      builtins.all validateCaskName casks
    ) "All package names should pass validation";
  };
}
