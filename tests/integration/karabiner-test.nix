# tests/integration/karabiner-test.nix
# Karabiner-Elements configuration integration tests
# Validates the Nix-generated karabiner.json (see users/shared/karabiner.nix)
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import karabiner module (mkIf-wrapped) and unwrap
  karabinerRaw = import ../../users/shared/karabiner.nix {
    inherit pkgs lib;
    isDarwin = true;
    config = {
      home.homeDirectory = "/Users/test";
    };
  };
  karabinerModule =
    if karabinerRaw ? _type && karabinerRaw._type == "if" then karabinerRaw.content else karabinerRaw;

  karabinerConfigUsable = karabinerModule ? home.file.".config/karabiner/karabiner.json";
  karabinerFileConfig =
    if karabinerConfigUsable then
      karabinerModule.home.file.".config/karabiner/karabiner.json"
    else
      null;

  fileHasText = karabinerConfigUsable && builtins.hasAttr "text" karabinerFileConfig;
  fileForceEnabled =
    karabinerConfigUsable
    && builtins.hasAttr "force" karabinerFileConfig
    && karabinerFileConfig.force == true;

  jsonContent = if fileHasText then karabinerFileConfig.text else "{}";
  parsed = builtins.tryEval (builtins.fromJSON jsonContent);
  jsonValid = parsed.success;
  data = if jsonValid then parsed.value else { };

  hasProfiles = jsonValid && builtins.hasAttr "profiles" data && builtins.length data.profiles > 0;
  firstProfile = if hasProfiles then builtins.elemAt data.profiles 0 else null;
  profileSelected = firstProfile != null && firstProfile.selected or false;

  virtualHidAnsi =
    firstProfile != null
    && firstProfile ? virtual_hid_keyboard.keyboard_type_v2
    && firstProfile.virtual_hid_keyboard.keyboard_type_v2 == "ansi";

  rules = firstProfile.complex_modifications.rules or [ ];
  hasOneRule = builtins.length rules == 1;
  manipulators = if hasOneRule then (builtins.elemAt rules 0).manipulators else [ ];

  # Find the trigger manipulator: from.key_code == "right_command"
  triggerCandidates = builtins.filter (m: (m.from.key_code or null) == "right_command") manipulators;
  hasTrigger = builtins.length triggerCandidates == 1;
  trigger = if hasTrigger then builtins.elemAt triggerCandidates 0 else null;

  triggerSetsHyper =
    trigger != null
    && builtins.any (
      e: (e.set_variable.name or null) == "hyper" && (e.set_variable.value or null) == 1
    ) trigger.to;
  triggerEmitsF19 = trigger != null && builtins.any (e: (e.key_code or null) == "f19") trigger.to;
  triggerClearsHyper =
    trigger != null
    && builtins.any (
      e: (e.set_variable.name or null) == "hyper" && (e.set_variable.value or null) == 0
    ) (trigger.to_after_key_up or [ ]);

  # App "open" manipulators: software_function.open_application + frontmost_application_unless
  isAppOpen =
    m:
    let
      to0 = if (m.to or [ ]) != [ ] then builtins.elemAt m.to 0 else { };
    in
    to0 ? software_function.open_application.bundle_identifier;
  appOpens = builtins.filter isAppOpen manipulators;

  # App "hide" manipulators: shell_command osascript with frontmost_application_if
  isAppHide =
    m:
    let
      to0 = if (m.to or [ ]) != [ ] then builtins.elemAt m.to 0 else { };
    in
    (to0 ? shell_command)
    && (builtins.match ".*osascript.*set visible.*to false.*" to0.shell_command != null);
  appHides = builtins.filter isAppHide manipulators;

  appOpenMap = builtins.listToAttrs (
    builtins.map (m: {
      name = m.from.key_code;
      value = (builtins.elemAt m.to 0).software_function.open_application.bundle_identifier;
    }) appOpens
  );

  expectedAppLaunchers = {
    i = "com.mitchellh.ghostty";
    e = "com.apple.mail";
    f = "com.apple.finder";
    h = "com.kapeli.dashdoc";
    k = "com.kakao.KakaoTalkMac";
    n = "notion.id";
    o = "md.obsidian";
    t = "com.culturedcode.ThingsMac";
  };

  appOpensCorrect = builtins.all (k: (appOpenMap.${k} or null) == expectedAppLaunchers.${k}) (
    builtins.attrNames expectedAppLaunchers
  );

  # 8 hide manipulators present, one per app key
  hideKeys = builtins.map (m: m.from.key_code) appHides;
  hideKeysCorrect =
    lib.sort builtins.lessThan hideKeys
    == lib.sort builtins.lessThan (builtins.attrNames expectedAppLaunchers);

  # Every open manipulator must be gated by hyper=1 AND frontmost_application_unless
  hasFrontmostUnless =
    m: builtins.any (c: (c.type or "") == "frontmost_application_unless") (m.conditions or [ ]);
  hasFrontmostIf =
    m: builtins.any (c: (c.type or "") == "frontmost_application_if") (m.conditions or [ ]);
  hasHyperGate =
    m:
    builtins.any (
      c: (c.type or "") == "variable_if" && (c.name or "") == "hyper" && (c.value or null) == 1
    ) (m.conditions or [ ]);

  appOpensGated = builtins.all (m: hasHyperGate m && hasFrontmostUnless m) appOpens;
  appHidesGated = builtins.all (m: hasHyperGate m && hasFrontmostIf m) appHides;

  # Local bindings: to[0].modifiers contains the four mega-mods, no software_function
  megaMods = [
    "left_command"
    "left_control"
    "left_option"
    "left_shift"
  ];
  isLocalBinding =
    m:
    let
      to0 = if (m.to or [ ]) != [ ] then builtins.elemAt m.to 0 else { };
    in
    (to0 ? modifiers) && (to0.modifiers == megaMods);
  localBindings = builtins.filter isLocalBinding manipulators;
  localBindingKeys = builtins.map (m: m.from.key_code) localBindings;
  expectedLocalKeys = [
    "b"
    "comma"
    "l"
    "period"
    "return_or_enter"
    "tab"
    "u"
  ];
  localBindingsPresent = lib.sort builtins.lessThan localBindingKeys == expectedLocalKeys;

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "karabiner" [
    (helpers.assertTest "karabiner-config-usable" karabinerConfigUsable
      "karabiner.nix should expose home.file karabiner.json"
    )
    (helpers.assertTest "karabiner-file-has-text" fileHasText
      "karabiner.json should be defined via text (Nix-generated)"
    )
    (helpers.assertTest "karabiner-force-enabled" fileForceEnabled
      "karabiner.json should have force=true"
    )
    (helpers.assertTest "karabiner-json-valid" jsonValid "generated karabiner.json must be valid JSON")
    (helpers.assertTest "karabiner-has-profiles" hasProfiles
      "config should contain at least one profile"
    )
    (helpers.assertTest "karabiner-profile-selected" profileSelected "first profile must be selected")
    (helpers.assertTest "karabiner-virtual-hid-ansi" virtualHidAnsi
      "virtual_hid_keyboard.keyboard_type_v2 must be 'ansi'"
    )
    (helpers.assertTest "karabiner-single-rule" hasOneRule
      "complex_modifications must have exactly one rule (the Hyper rule)"
    )
    (helpers.assertTest "karabiner-trigger-present" hasTrigger
      "rule must contain exactly one right_command trigger manipulator"
    )
    (helpers.assertTest "karabiner-trigger-sets-hyper" triggerSetsHyper
      "trigger 'to' must set variable hyper=1"
    )
    (helpers.assertTest "karabiner-trigger-emits-f19" triggerEmitsF19
      "trigger 'to' must emit f19 for Hammerspoon modal"
    )
    (helpers.assertTest "karabiner-trigger-clears-hyper" triggerClearsHyper
      "trigger 'to_after_key_up' must set hyper=0"
    )
    (helpers.assertTest "karabiner-app-opens-correct" appOpensCorrect
      "all 8 app open manipulators must map to correct bundle_identifier"
    )
    (helpers.assertTest "karabiner-app-opens-gated" appOpensGated
      "every open manipulator must require hyper=1 AND frontmost_application_unless"
    )
    (helpers.assertTest "karabiner-app-hides-keys" hideKeysCorrect
      "all 8 app keys must have a corresponding hide manipulator"
    )
    (helpers.assertTest "karabiner-app-hides-gated" appHidesGated
      "every hide manipulator must require hyper=1 AND frontmost_application_if"
    )
    (helpers.assertTest "karabiner-local-bindings-present" localBindingsPresent
      "7 expected local-binding keys must emit mega-modifier chord"
    )
  ];
}
