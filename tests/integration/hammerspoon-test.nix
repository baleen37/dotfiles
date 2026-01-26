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
    "Pomodoro.spoon"
    "FocusTracker.spoon"
  ];
  hasExpectedSpoons = lib.all (spoon: builtins.hasAttr spoon spoonsContents) expectedSpoons;

  # Overall structure integrity
  structureValid = hammerspoonDirUsable && initLuaUsable && configAppsUsable && spoonsDirUsable;

  # Read file contents for validation
  initLuaContent = if initLuaUsable then initLuaResult.value else "";
  configAppsContent = if configAppsUsable then configAppsResult.value else "";

  # Spoon init.lua files
  pomodoroInit = hammerspoonDir + "/Spoons/Pomodoro.spoon/init.lua";
  focustrackerInit = hammerspoonDir + "/Spoons/FocusTracker.spoon/init.lua";
  hyperInit = hammerspoonDir + "/Spoons/Hyper.spoon/init.lua";

  pomodoroInitResult = validateFile pomodoroInit;
  focustrackerInitResult = validateFile focustrackerInit;
  hyperInitResult = validateFile hyperInit;

  pomodoroInitContent = if pomodoroInitResult.success then pomodoroInitResult.value else "";
  focustrackerInitContent = if focustrackerInitResult.success then focustrackerInitResult.value else "";
  hyperInitContent = if hyperInitResult.success then hyperInitResult.value else "";

in
{
  platforms = ["darwin"];
  value = helpers.testSuite "hammerspoon" [
    # ========================================================================
    # Section 1: Directory and File Existence Tests (7 tests)
    # ========================================================================

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
      "All expected Spoons should exist (Hyper, Headspace, HyperModal, Pomodoro, FocusTracker)")

    (helpers.assertTest "directory-structure" structureValid
      "Directory structure should be correct and all components usable")

    # ========================================================================
    # Section 2: init.lua Content Validation (10 tests)
    # ========================================================================

    # Spoon loading tests
    (helpers.assertTest "init-loads-hyper"
      (lib.hasInfix "hs.loadSpoon('Hyper')" initLuaContent)
      "init.lua should load Hyper Spoon")

    (helpers.assertTest "init-loads-hypermodal"
      (lib.hasInfix "hs.loadSpoon('HyperModal')" initLuaContent)
      "init.lua should load HyperModal Spoon")

    (helpers.assertTest "init-loads-pomodoro"
      (lib.hasInfix "hs.loadSpoon('Pomodoro')" initLuaContent)
      "init.lua should load Pomodoro Spoon")

    # Config object tests
    (helpers.assertTest "init-creates-config-object"
      (lib.hasInfix "Config = {}" initLuaContent)
      "init.lua should create Config object")

    (helpers.assertTest "init-requires-config-apps"
      (lib.hasInfix "Config.applications = require('configApplications')" initLuaContent)
      "init.lua should require configApplications")

    # Hyper key binding tests
    (helpers.assertTest "init-hyper-hotkeys"
      (lib.hasInfix "Hyper:bindHotKeys" initLuaContent)
      "init.lua should bind Hyper hotkeys")

    (helpers.assertTest "init-hyper-modal-binding"
      (lib.hasInfix "Hyper:bind({}, 'm', function()" initLuaContent)
      "init.lua should bind HyperModal toggle")

    (helpers.assertTest "init-pomodoro-binding"
      (lib.hasInfix "Hyper:bind({}, 'p', function()" initLuaContent)
      "init.lua should bind Pomodoro toggle")

    # App iteration test
    (helpers.assertTest "init-app-iteration"
      (lib.hasInfix "hs.fnutils.each(Config.applications" initLuaContent)
      "init.lua should iterate over applications")

    # Local config support test
    (helpers.assertTest "init-local-config-support"
      (lib.hasInfix "require('localConfig')" initLuaContent)
      "init.lua should support local config override")

    # ========================================================================
    # Section 3: configApplications.lua Content Validation (6 tests)
    # ========================================================================

    # Table structure test
    (helpers.assertTest "config-apps-returns-table"
      (lib.hasInfix "return {" configAppsContent)
      "configApplications.lua should return a table")

    # Core app configuration tests (representative apps)
    (helpers.assertTest "config-apps-has-ghostty"
      (lib.hasInfix "com.mitchellh.ghostty" configAppsContent)
      "configApplications should include Ghostty terminal")

    (helpers.assertTest "config-apps-has-things"
      (lib.hasInfix "com.culturedcode.ThingsMac" configAppsContent)
      "configApplications should include Things app")

    (helpers.assertTest "config-apps-has-obsidian"
      (lib.hasInfix "md.obsidian" configAppsContent)
      "configApplications should include Obsidian")

    (helpers.assertTest "config-apps-has-finder"
      (lib.hasInfix "com.apple.finder" configAppsContent)
      "configApplications should include Finder")

    # Required field tests
    (helpers.assertTest "config-apps-has-bundleid-field"
      (lib.hasInfix "bundleID" configAppsContent)
      "configApplications should define bundleID fields")

    (helpers.assertTest "config-apps-has-hyperkey-field"
      (lib.hasInfix "hyperKey" configAppsContent)
      "configApplications should define hyperKey bindings")

    # ========================================================================
    # Section 4: Spoon Metadata Validation (6 tests)
    # ========================================================================

    # Pomodoro Spoon tests
    (helpers.assertTest "pomodoro-spoon-metadata"
      (lib.hasInfix "obj.name = \"Pomodoro\"" pomodoroInitContent)
      "Pomodoro Spoon should define name metadata")

    (helpers.assertTest "pomodoro-spoon-structure"
      (lib.hasInfix "return obj" pomodoroInitContent)
      "Pomodoro Spoon should return obj")

    # FocusTracker Spoon tests
    (helpers.assertTest "focustracker-spoon-metadata"
      (lib.hasInfix "obj.name = \"FocusTracker\"" focustrackerInitContent)
      "FocusTracker Spoon should define name metadata")

    (helpers.assertTest "focustracker-spoon-structure"
      (lib.hasInfix "return obj" focustrackerInitContent)
      "FocusTracker Spoon should return obj")

    # Hyper Spoon tests
    (helpers.assertTest "hyper-spoon-metadata"
      (lib.hasInfix "m.name = \"Hyper\"" hyperInitContent)
      "Hyper Spoon should define name metadata")

    (helpers.assertTest "hyper-spoon-structure"
      (lib.hasInfix "return m" hyperInitContent)
      "Hyper Spoon should return m")
  ];
}
