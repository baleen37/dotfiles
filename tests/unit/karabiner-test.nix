# tests/unit/karabiner-test.nix
# Karabiner-Elements Keyboard Customization Configuration Tests
# Tests that Karabiner configuration is properly set up (macOS-only)
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import Karabiner configuration
  karabinerConfig = import ../../users/shared/karabiner.nix {
    inherit pkgs lib;
    config = {};
  };

  # Path to Karabiner config directory
  karabinerConfigDir = ../../users/shared/.config/karabiner;

  # Helper to safely read and parse JSON
  readJson = path:
    let
      contentResult = builtins.tryEval (builtins.readFile path);
    in
    if contentResult.success then
      builtins.tryEval (builtins.fromJSON contentResult.value)
    else
      { success = false; value = {}; };

  # Read Karabiner JSON config
  karabinerJson = readJson (karabinerConfigDir + "/karabiner.json");

  # Helper to extract first profile from karabiner JSON
  getFirstProfile = karabinerJson:
    if karabinerJson.success then
      let profiles = karabinerJson.value.profiles or [];
      in if builtins.length profiles > 0 then
        builtins.head profiles
      else
        null
    else
      null;

  # Helper to check if right_command maps to f19
  hasRightCommandToF19 = profile:
    if profile == null then
      false
    else
      let mods = profile.simple_modifications or [];
      in builtins.any (mod:
        mod.from.key_code or "" == "right_command" &&
        builtins.length mod.to == 1 &&
        (builtins.head mod.to).key_code or "" == "f19"
      ) mods;

in
{
  platforms = ["darwin"];
  value = helpers.testSuite "karabiner" [
    # Test 1: home.file .config/karabiner/karabiner.json is configured
    (helpers.assertTest "karabiner-config-file-symlinked" (
      karabinerConfig.home.file ? ".config/karabiner/karabiner.json"
    ) "home.file .config/karabiner/karabiner.json should be configured")

    # Test 2: Karabiner config source directory exists
    (helpers.assertTest "karabiner-config-source-exists" (
      builtins.pathExists karabinerConfigDir
    ) "Karabiner config source directory should exist")

    # Test 3: Karabiner JSON config file is valid JSON
    (helpers.assertTest "karabiner-json-valid" (
      karabinerJson.success
    ) "Karabiner karabiner.json should be valid JSON")

    # Test 4: Karabiner JSON has profiles array
    (helpers.assertTest "karabiner-has-profiles" (
      karabinerJson.success && karabinerJson.value ? profiles
    ) "Karabiner config should have profiles array")

    # Test 5: Karabiner JSON has at least one profile
    (helpers.assertTest "karabiner-has-profile" (
      karabinerJson.success &&
      builtins.length (karabinerJson.value.profiles or []) > 0
    ) "Karabiner config should have at least one profile")

    # Test 6: Config file uses force = true
    (helpers.assertTest "karabiner-config-force" (
      karabinerConfig.home.file.".config/karabiner/karabiner.json".force or false
    ) "Karabiner config should use force = true")

    # Test 7: First profile has name
    (helpers.assertTest "karabiner-profile-has-name" (
      let firstProfile = getFirstProfile karabinerJson;
      in firstProfile != null && firstProfile ? name
    ) "Karabiner first profile should have a name")

    # Test 8: First profile has simple_modifications
    (helpers.assertTest "karabiner-profile-has-modifications" (
      let firstProfile = getFirstProfile karabinerJson;
      in firstProfile != null && firstProfile ? simple_modifications
    ) "Karabiner first profile should have simple_modifications")

    # Test 9: simple_modifications maps right_command to f19
    (helpers.assertTest "karabiner-right-command-to-f19" (
      let firstProfile = getFirstProfile karabinerJson;
      in hasRightCommandToF19 firstProfile
    ) "Karabiner should map right_command to f19")

    # Test 10: First profile has virtual_hid_keyboard settings
    (helpers.assertTest "karabiner-has-virtual-hid" (
      let firstProfile = getFirstProfile karabinerJson;
      in firstProfile != null && firstProfile ? virtual_hid_keyboard
    ) "Karabiner first profile should have virtual_hid_keyboard settings")

    # Test 11: virtual_hid_keyboard has keyboard_type_v2
    (helpers.assertTest "karabiner-has-keyboard-type" (
      let firstProfile = getFirstProfile karabinerJson;
          vHid = if firstProfile != null then firstProfile.virtual_hid_keyboard or {} else {};
      in vHid ? keyboard_type_v2
    ) "Karabiner virtual_hid_keyboard should have keyboard_type_v2")

    # Test 12: keyboard_type_v2 is set to ansi
    (helpers.assertTest "karabiner-keyboard-type-ansi" (
      let firstProfile = getFirstProfile karabinerJson;
          vHid = if firstProfile != null then firstProfile.virtual_hid_keyboard or {} else {};
      in vHid.keyboard_type_v2 or "" == "ansi"
    ) "Karabiner keyboard_type_v2 should be 'ansi'")
  ];
}
