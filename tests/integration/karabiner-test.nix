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
    isDarwin = true;
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

  # Helper: complex_modifications structure
  profileHasComplexModifications =
    firstProfile != null && builtins.hasAttr "complex_modifications" firstProfile;
  complexModifications =
    if profileHasComplexModifications then firstProfile.complex_modifications else { };
  complexHasRules = profileHasComplexModifications && builtins.hasAttr "rules" complexModifications;
  complexRules = if complexHasRules then complexModifications.rules else [ ];
  hasOneRule = builtins.length complexRules == 1;
  firstRule = if hasOneRule then builtins.elemAt complexRules 0 else null;
  ruleHasManipulators = firstRule != null && builtins.hasAttr "manipulators" firstRule;
  manipulators = if ruleHasManipulators then firstRule.manipulators else [ ];
  hasEightManipulators = builtins.length manipulators == 8;

  # Helper: extract from-key for a manipulator
  manipulatorFromKey =
    m:
    if builtins.hasAttr "from" m && builtins.hasAttr "key_code" m.from then m.from.key_code else null;

  # Helper: extract bundle_identifier for a manipulator
  manipulatorBundleId =
    m:
    let
      to0 = if builtins.hasAttr "to" m && builtins.length m.to > 0 then builtins.elemAt m.to 0 else { };
      sf = if builtins.hasAttr "software_function" to0 then to0.software_function else { };
      oa = if builtins.hasAttr "open_application" sf then sf.open_application else { };
    in
    if builtins.hasAttr "bundle_identifier" oa then oa.bundle_identifier else null;

  # Helper: extract mandatory modifiers
  manipulatorMandatory =
    m:
    if
      builtins.hasAttr "from" m
      && builtins.hasAttr "modifiers" m.from
      && builtins.hasAttr "mandatory" m.from.modifiers
    then
      m.from.modifiers.mandatory
    else
      [ ];

  # Expected mappings (key → bundle_identifier)
  expectedMappings = {
    "i" = "com.mitchellh.ghostty";
    "e" = "com.apple.mail";
    "f" = "com.apple.finder";
    "h" = "com.kapeli.dashdoc";
    "k" = "com.kakao.KakaoTalkMac";
    "n" = "notion.id";
    "o" = "md.obsidian";
    "t" = "com.culturedcode.ThingsMac";
  };

  # Build a key → manipulator lookup
  manipulatorByKey = builtins.listToAttrs (
    builtins.map (m: {
      name = manipulatorFromKey m;
      value = m;
    }) manipulators
  );

  # Validation: every expected key has a manipulator with correct bundle_id and right_command modifier
  allMappingsCorrect =
    hasEightManipulators
    && builtins.all (
      key:
      builtins.hasAttr key manipulatorByKey
      && manipulatorBundleId manipulatorByKey.${key} == expectedMappings.${key}
      && manipulatorMandatory manipulatorByKey.${key} == [ "right_command" ]
    ) (builtins.attrNames expectedMappings);

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

    # complex_modifications 존재 확인
    (helpers.assertTest "karabiner-has-complex-modifications" profileHasComplexModifications
      "karabiner profile should have complex_modifications for Hyper app launchers"
    )

    # rules 배열에 정확히 1개 룰 (Hyper app launchers)
    (helpers.assertTest "karabiner-complex-has-one-rule" hasOneRule
      "karabiner complex_modifications should contain exactly one rule"
    )

    # 8개 manipulator
    (helpers.assertTest "karabiner-complex-has-eight-manipulators" hasEightManipulators
      "karabiner complex rule should contain 8 manipulators (i,e,f,h,k,n,o,t)"
    )

    # 모든 매핑이 키 → bundle_id가 일치하고 right_command modifier 사용
    (helpers.assertTest "karabiner-complex-mappings-correct" allMappingsCorrect
      "all 8 Hyper app launcher manipulators must map (key, right_command) → correct bundle_identifier"
    )
  ];
}
