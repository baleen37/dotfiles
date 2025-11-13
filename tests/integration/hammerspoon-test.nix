# tests/integration/hammerspoon-test.nix
# Hammerspoon configuration integrity tests
# Tests that all Hammerspoon config files are present and valid
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Path to Hammerspoon configuration
  hammerspoonDir = ../../users/shared/.config/hammerspoon;

  # Behavioral validation: can we read and process Hammerspoon config?
  hammerspoonDirResult = builtins.tryEval (builtins.readDir hammerspoonDir);
  hammerspoonDirUsable = hammerspoonDirResult.success;
  hammerspoonDirContents = if hammerspoonDirUsable then hammerspoonDirResult.value else { };

  # Behavioral validation: can we read specific configuration files?
  initLuaResult = builtins.tryEval (builtins.readFile (hammerspoonDir + "/init.lua"));
  configAppsResult = builtins.tryEval (
    builtins.readFile (hammerspoonDir + "/configApplications.lua")
  );
  spoonsDirResult = builtins.tryEval (builtins.readDir (hammerspoonDir + "/Spoons"));

  initLuaUsable = initLuaResult.success && builtins.stringLength initLuaResult.value > 0;
  configAppsUsable = configAppsResult.success && builtins.stringLength configAppsResult.value > 0;
  spoonsDirUsable = spoonsDirResult.success;

  # Behavioral directory structure validation
  hasRequiredFiles =
    hammerspoonDirUsable
    && builtins.hasAttr "init.lua" hammerspoonDirContents
    && builtins.hasAttr "configApplications.lua" hammerspoonDirContents
    && builtins.hasAttr "Spoons" hammerspoonDirContents;

  # Behavioral Spoons directory validation
  spoonsContents = if spoonsDirUsable then spoonsDirResult.value else { };
  expectedSpoons = [
    "Hyper.spoon"
    "Headspace.spoon"
    "HyperModal.spoon"
  ];
  hasExpectedSpoons = lib.all (spoon: builtins.hasAttr spoon spoonsContents) expectedSpoons;

in
helpers.testSuite "hammerspoon" [
  # Test that Hammerspoon config directory is readable and usable
  (helpers.assertTest "hammerspoon-dir-usable" hammerspoonDirUsable
    "Hammerspoon directory should be readable and usable")

  # Test that init.lua is readable and has content
  (helpers.assertTest "init-lua-usable" initLuaUsable
    "init.lua should be readable and have content")

  # Test that configApplications.lua is readable and has content
  (helpers.assertTest "config-apps-usable" configAppsUsable
    "configApplications.lua should be readable and have content")

  # Test that Spoons directory is readable and usable
  (helpers.assertTest "spoons-dir-usable" spoonsDirUsable
    "Spoons directory should be readable and usable")

  # Test that all required files exist
  (helpers.assertTest "required-files-exist" hasRequiredFiles
    "All required files should exist")

  # Test that all expected Spoons exist
  (helpers.assertTest "expected-spoons-exist" hasExpectedSpoons
    "All expected Spoons should exist (Hyper, Headspace, HyperModal)")

  # Test that directory has expected structure (behavioral)
  (helpers.assertTest "directory-structure"
    (hammerspoonDirUsable && initLuaUsable && configAppsUsable && spoonsDirUsable)
    "Directory structure should be correct and usable")
]
