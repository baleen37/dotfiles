# tests/integration/karabiner-test.nix
# Karabiner-Elements configuration integration tests
# Tests that Karabiner keyboard customization is properly configured via Home Manager
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  nixtest ? { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Mock configuration for testing karabiner integration
  mockConfig = {
    home = {
      homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
    };
  };

  # Import karabiner configuration with mocked dependencies
  karabinerModule = import ../../users/shared/karabiner.nix {
    inherit pkgs lib;
    config = mockConfig;
  };

  # Test that karabiner config can be imported and is usable
  karabinerConfigUsable = karabinerModule ? home.file.".config/karabiner/karabiner.json";

  # Get the karabiner file configuration
  karabinerFileConfig =
    if karabinerConfigUsable then
      karabinerModule.home.file.".config/karabiner/karabiner.json"
    else
      null;

  # Read the source karabiner.json file
  karabinerJsonPath = ../../users/shared/.config/karabiner/karabiner.json;
  karabinerJsonReadResult = builtins.tryEval (builtins.readFile karabinerJsonPath);
  karabinerJsonContent =
    if karabinerJsonReadResult.success then karabinerJsonReadResult.value else "{}";

  # Parse JSON to validate structure
  karabinerParsed = builtins.tryEval (builtins.fromJSON karabinerJsonContent);
  karabinerJsonValid = karabinerParsed.success;

  # Get parsed content
  karabinerData = if karabinerJsonValid then karabinerParsed.value else { };

  # Helper to check if profiles array exists and has at least one profile
  hasProfiles =
    karabinerJsonValid
    && builtins.hasAttr "profiles" karabinerData
    && builtins.length karabinerData.profiles > 0;

  # Get first profile
  firstProfile = if hasProfiles then builtins.elemAt karabinerData.profiles 0 else null;

  # Helper to check profile structure
  profileHasName = firstProfile != null && builtins.hasAttr "name" firstProfile;
  profileHasSelected = firstProfile != null && builtins.hasAttr "selected" firstProfile;
  profileHasSimpleModifications =
    firstProfile != null && builtins.hasAttr "simple_modifications" firstProfile;

  # Helper to check virtual_hid_keyboard structure
  profileHasVirtualHid = firstProfile != null && builtins.hasAttr "virtual_hid_keyboard" firstProfile;
  virtualHidHasKeyboardType =
    profileHasVirtualHid && builtins.hasAttr "keyboard_type_v2" firstProfile.virtual_hid_keyboard;

  # Helper to check simple_modifications structure
  simpleModifications =
    if profileHasSimpleModifications then firstProfile.simple_modifications else [ ];
  hasSimpleModifications = builtins.length simpleModifications > 0;

  # Check first modification structure
  firstModification = if hasSimpleModifications then builtins.elemAt simpleModifications 0 else null;
  modificationHasFrom = firstModification != null && builtins.hasAttr "from" firstModification;
  modificationHasTo = firstModification != null && builtins.hasAttr "to" firstModification;
  modificationFromHasKeyCode =
    modificationHasFrom && builtins.hasAttr "key_code" firstModification.from;
  modificationToArray = modificationHasTo && builtins.typeOf firstModification.to == "list";

  # Helper to check Home Manager file configuration
  homeManagerFileConfigured = karabinerConfigUsable && karabinerFileConfig != null;
  fileHasSource = homeManagerFileConfigured && builtins.hasAttr "source" karabinerFileConfig;
  fileHasForce = homeManagerFileConfigured && builtins.hasAttr "force" karabinerFileConfig;
  fileForceEnabled = fileHasForce && karabinerFileConfig.force == true;

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "karabiner" [
    # Test that karabiner.nix can be imported and is usable
    (helpers.assertTest "karabiner-config-usable" karabinerConfigUsable
      "karabiner.nix should be importable and usable"
    )

    # Test that Home Manager file configuration exists
    (helpers.assertTest "karabiner-home-manager-file" homeManagerFileConfigured
      "karabiner should be configured via Home Manager home.file"
    )

    # Test that file has source attribute
    (helpers.assertTest "karabiner-file-has-source" fileHasSource
      "karabiner.json should have a source file reference"
    )

    # Test that force is enabled (important for Karabiner to pick up changes)
    (helpers.assertTest "karabiner-force-enabled" fileForceEnabled
      "karabiner.json should have force=true to ensure Karabiner picks up changes"
    )

    # Test that karabiner.json is valid JSON
    (helpers.assertTest "karabiner-json-valid" karabinerJsonValid "karabiner.json should be valid JSON")

    # Test that profiles array exists
    (helpers.assertTest "karabiner-has-profiles" hasProfiles
      "karabiner.json should have at least one profile"
    )

    # Test profile structure - has name
    (helpers.assertTest "karabiner-profile-has-name" profileHasName
      "karabiner profile should have a name attribute"
    )

    # Test profile structure - has selected
    (helpers.assertTest "karabiner-profile-has-selected" profileHasSelected
      "karabiner profile should have a selected attribute"
    )

    # Test profile structure - has simple_modifications
    (helpers.assertTest "karabiner-profile-has-simple-modifications" profileHasSimpleModifications
      "karabiner profile should have simple_modifications array"
    )

    # Test that simple_modifications is not empty
    (helpers.assertTest "karabiner-has-modifications" hasSimpleModifications
      "karabiner should have at least one key modification"
    )

    # Test modification structure - has from
    (helpers.assertTest "karabiner-modification-has-from" modificationHasFrom
      "karabiner modification should have 'from' attribute"
    )

    # Test modification structure - has to
    (helpers.assertTest "karabiner-modification-has-to" modificationHasTo
      "karabiner modification should have 'to' attribute"
    )

    # Test modification structure - from has key_code
    (helpers.assertTest "karabiner-modification-from-has-keycode" modificationFromHasKeyCode
      "karabiner modification 'from' should have 'key_code' attribute"
    )

    # Test modification structure - to is array
    (helpers.assertTest "karabiner-modification-to-is-array" modificationToArray
      "karabiner modification 'to' should be an array"
    )

    # Test virtual_hid_keyboard exists
    (helpers.assertTest "karabiner-has-virtual-hid" profileHasVirtualHid
      "karabiner profile should have virtual_hid_keyboard configuration"
    )

    # Test virtual_hid_keyboard has keyboard_type_v2
    (helpers.assertTest "karabiner-virtual-hid-has-keyboard-type" virtualHidHasKeyboardType
      "karabiner virtual_hid_keyboard should have keyboard_type_v2 attribute"
    )

    # Test specific modification: right_command -> f19
    (helpers.assertTest "karabiner-right-command-remap" (
      hasSimpleModifications
      && firstModification != null
      && modificationHasFrom
      && modificationFromHasKeyCode
      && firstModification.from.key_code == "right_command"
    ) "karabiner should remap right_command key")

    # Test that 'to' mapping exists for the modification
    (helpers.assertTest "karabiner-modification-to-has-keycode" (
      hasSimpleModifications
      && firstModification != null
      && modificationHasTo
      && modificationToArray
      && builtins.length firstModification.to > 0
      && builtins.hasAttr "key_code" (builtins.elemAt firstModification.to 0)
    ) "karabiner modification 'to' array should contain key_code mapping")

    # Test keyboard_type_v2 is set to ansi
    (helpers.assertTest "karabiner-keyboard-type-ansi" (
      virtualHidHasKeyboardType
      && firstProfile != null
      && firstProfile.virtual_hid_keyboard.keyboard_type_v2 == "ansi"
    ) "karabiner keyboard_type_v2 should be set to ansi")
  ];
}
