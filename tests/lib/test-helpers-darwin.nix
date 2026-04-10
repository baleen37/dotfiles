# macOS-specific test assertion helpers
#
# Provides assertions for testing nix-darwin system.defaults:
# NSGlobalDomain, Dock, Finder, Trackpad, LoginWindow settings,
# plus bulk helpers for settings, patterns, and aliases.
{
  pkgs,
  lib,
  assertTest,
  testSuite,
}:

{
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
      setting:
      assertTest "ns-global-${builtins.head (
        builtins.split "=" (builtins.elemAt setting 0)
      )}" (
        darwinConfig.system.defaults.NSGlobalDomain.${builtins.elemAt setting 0} == (builtins.elemAt setting 1)
      ) "NSGlobalDomain.${builtins.elemAt setting 0} should be ${toString (builtins.elemAt setting 1)}"
    ) settings;

  # Test a single dock setting
  assertDockSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "dock-${testName}" (
      darwinConfig.system.defaults.dock.${key} == expectedValue
    ) "Dock.${key} should be ${toString expectedValue}";

  # Test multiple dock settings at once
  assertDockSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTest "dock-${builtins.elemAt setting 0}" (
        darwinConfig.system.defaults.dock.${builtins.elemAt setting 1} == (builtins.elemAt setting 2)
      ) "Dock.${builtins.elemAt setting 1} should be ${toString (builtins.elemAt setting 2)}"
    ) settings;

  # Test a single finder setting
  assertFinderSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "finder-${testName}" (
      darwinConfig.system.defaults.finder.${key} == expectedValue
    ) "Finder.${key} should be ${toString expectedValue}";

  # Test multiple finder settings at once
  assertFinderSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTest "finder-${builtins.elemAt setting 0}" (
        darwinConfig.system.defaults.finder.${builtins.elemAt setting 1} == (builtins.elemAt setting 2)
      ) "Finder.${builtins.elemAt setting 1} should be ${toString (builtins.elemAt setting 2)}"
    ) settings;

  # Test a single trackpad setting
  assertTrackpadSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "trackpad-${testName}" (
      darwinConfig.system.defaults.trackpad.${key} == expectedValue
    ) "Trackpad.${key} should be ${toString expectedValue}";

  # Test multiple trackpad settings at once
  assertTrackpadSettings =
    settings: darwinConfig:
    builtins.map (
      setting:
      assertTest "trackpad-${builtins.elemAt setting 0}" (
        darwinConfig.system.defaults.trackpad.${builtins.elemAt setting 1} == (builtins.elemAt setting 2)
      ) "Trackpad.${builtins.elemAt setting 1} should be ${toString (builtins.elemAt setting 2)}"
    ) settings;

  # Test a login window setting
  assertLoginWindowSetting =
    testName: key: expectedValue: darwinConfig:
    assertTest "login-window-${testName}" (
      darwinConfig.system.defaults.loginwindow.${key} == expectedValue
    ) "Login window.${key} should be ${toString expectedValue}";

  # Test multiple key-value pairs in a nested attribute set
  assertSettings =
    name: settings: expectedValues:
    let
      individualTests = builtins.map (
        key:
        let
          expectedValue = builtins.getAttr key expectedValues;
          actualValue = builtins.getAttr key settings;
          testName = "${name}-${builtins.replaceStrings [ "." ] [ "-" ] key}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "${name}.${key} should be '${toString expectedValue}'"
      ) (builtins.attrNames expectedValues);

      summaryTest = pkgs.runCommand "${name}-settings-summary" { } ''
        echo "✅ Settings group '${name}': All ${toString (builtins.length individualTests)} values match"
        touch $out
      '';
    in
    testSuite "${name}-settings" (individualTests ++ [ summaryTest ]);

  # Test that a list contains all expected patterns
  assertPatterns =
    name: actualList: expectedPatterns:
    let
      individualTests = builtins.map (
        pattern:
        let
          sanitizedName = builtins.replaceStrings [ "*" "." "/" "-" " " ] [ "-" "-" "-" "-" "" ] (
            if pattern == "" then "empty" else pattern
          );
          testName = "${name}-${sanitizedName}";
          hasPattern = builtins.any (p: p == pattern) actualList;
        in
        assertTest testName hasPattern "${name} should include '${pattern}'"
      ) expectedPatterns;

      summaryTest = pkgs.runCommand "${name}-patterns-summary" { } ''
        echo "✅ Pattern group '${name}': All ${toString (builtins.length individualTests)} patterns found"
        touch $out
      '';
    in
    testSuite "${name}-patterns" (individualTests ++ [ summaryTest ]);

  # Test multiple git aliases
  assertAliases =
    aliasSettings: expectedAliases:
    let
      individualTests = builtins.map (
        aliasName:
        let
          expectedValue = builtins.getAttr aliasName expectedAliases;
          actualValue = builtins.getAttr aliasName aliasSettings;
          testName = "git-alias-${aliasName}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "Git should have '${aliasName}' alias for '${expectedValue}'"
      ) (builtins.attrNames expectedAliases);

      summaryTest = pkgs.runCommand "git-aliases-summary" { } ''
        echo "✅ Git aliases: All ${toString (builtins.length individualTests)} aliases configured correctly"
        touch $out
      '';
    in
    testSuite "git-aliases" (individualTests ++ [ summaryTest ]);
}
