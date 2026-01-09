# tests/integration/hammerspoon-test.nix
# Hammerspoon configuration integrity tests
# Tests that all Hammerspoon config files are present and valid
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

  # Path to Hammerspoon configuration
  hammerspoonDir = ../../users/shared/.config/hammerspoon;

  # Helper to validate file readability and content
  # Returns: { success = bool; value = content; }
  validateFile = filePath: builtins.tryEval (builtins.readFile filePath);

  # Helper to validate directory readability
  # Returns: { success = bool; value = dirContents; }
  validateDir = dirPath: builtins.tryEval (builtins.readDir dirPath);

  # Behavioral validation: check if file/dir is usable (readable and has content)
  isFileUsable = fileResult: fileResult.success && builtins.stringLength fileResult.value > 0;
  isDirUsable = dirResult: dirResult.success;

  # Core validation results
  hammerspoonDirResult = validateDir hammerspoonDir;
  hammerspoonDirUsable = isDirUsable hammerspoonDirResult;
  hammerspoonDirContents = if hammerspoonDirUsable then hammerspoonDirResult.value else { };

  # Validate required configuration files
  initLuaResult = validateFile (hammerspoonDir + "/init.lua");
  configAppsResult = validateFile (hammerspoonDir + "/configApplications.lua");
  spoonsDirResult = validateDir (hammerspoonDir + "/Spoons");

  initLuaUsable = isFileUsable initLuaResult;
  configAppsUsable = isFileUsable configAppsResult;
  spoonsDirUsable = isDirUsable spoonsDirResult;

  # Required top-level files and directories
  requiredItems = [ "init.lua" "configApplications.lua" "Spoons" ];
  hasRequiredItems = lib.all (item: builtins.hasAttr item hammerspoonDirContents) requiredItems;

  # Expected Spoons validation
  spoonsContents = if spoonsDirUsable then spoonsDirResult.value else { };
  expectedSpoons = [
    "Hyper.spoon"
    "Headspace.spoon"
    "HyperModal.spoon"
  ];
  hasExpectedSpoons = lib.all (spoon: builtins.hasAttr spoon spoonsContents) expectedSpoons;

  # Overall structure integrity
  structureValid = hammerspoonDirUsable && initLuaUsable && configAppsUsable && spoonsDirUsable;

in
{
  platforms = ["darwin"];
  value = helpers.testSuite "hammerspoon" [
    # Directory usability tests
  (helpers.assertTest "hammerspoon-dir-usable" hammerspoonDirUsable
    "Hammerspoon directory should be readable and usable")

  # Configuration file content tests
  (helpers.assertTest "init-lua-usable" initLuaUsable
    "init.lua should be readable and have content")

  (helpers.assertTest "config-apps-usable" configAppsUsable
    "configApplications.lua should be readable and have content")

  # Spoons directory test
  (helpers.assertTest "spoons-dir-usable" spoonsDirUsable
    "Spoons directory should be readable and usable")

  # Structure validation tests
  (helpers.assertTest "required-items-exist" hasRequiredItems
    "All required items should exist (init.lua, configApplications.lua, Spoons)")

  (helpers.assertTest "expected-spoons-exist" hasExpectedSpoons
    "All expected Spoons should exist (Hyper, Headspace, HyperModal)")

  (helpers.assertTest "directory-structure" structureValid
    "Directory structure should be correct and all components usable")
  ];
}
