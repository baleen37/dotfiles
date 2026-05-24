# tests/integration/hammerspoon-test.nix
# Hammerspoon configuration integrity tests
# Tests that all Hammerspoon config files are present and valid
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
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
  spoonsDirResult = validateDir (hammerspoonDir + "/Spoons");

  initLuaUsable = isFileUsable initLuaResult;
  spoonsDirUsable = isDirUsable spoonsDirResult;

  # Required top-level files and directories
  requiredItems = [
    "init.lua"
    "Spoons"
  ];
  hasRequiredItems = lib.all (item: builtins.hasAttr item hammerspoonDirContents) requiredItems;

  # Expected Spoons validation
  spoonsContents = if spoonsDirUsable then spoonsDirResult.value else { };
  expectedSpoons = [
    "Hyper.spoon"
    "HyperModal.spoon"
    "Pomodoro.spoon"
  ];
  hasExpectedSpoons = lib.all (spoon: builtins.hasAttr spoon spoonsContents) expectedSpoons;

  # Overall structure integrity
  structureValid = hammerspoonDirUsable && initLuaUsable && spoonsDirUsable;

  # Read file contents for validation
  initLuaContent = if initLuaUsable then initLuaResult.value else "";

  # Spoon init.lua files
  pomodoroInit = hammerspoonDir + "/Spoons/Pomodoro.spoon/init.lua";
  hyperInit = hammerspoonDir + "/Spoons/Hyper.spoon/init.lua";

  pomodoroInitResult = validateFile pomodoroInit;
  hyperInitResult = validateFile hyperInit;

  pomodoroInitContent = if pomodoroInitResult.success then pomodoroInitResult.value else "";
  hyperInitContent = if hyperInitResult.success then hyperInitResult.value else "";

in
{
  platforms = [ "darwin" ];
  value = helpers.testSuite "hammerspoon" [
    # ========================================================================
    # Section 1: Directory and File Existence Tests (7 tests)
    # ========================================================================

    # Directory usability tests
    (helpers.assertTest "hammerspoon-dir-usable" hammerspoonDirUsable
      "Hammerspoon directory should be readable and usable"
    )

    # Configuration file content tests
    (helpers.assertTest "init-lua-usable" initLuaUsable "init.lua should be readable and have content")

    # Spoons directory test
    (helpers.assertTest "spoons-dir-usable" spoonsDirUsable
      "Spoons directory should be readable and usable"
    )

    # Structure validation tests
    (helpers.assertTest "required-items-exist" hasRequiredItems
      "All required items should exist (init.lua, Spoons)"
    )

    (helpers.assertTest "expected-spoons-exist" hasExpectedSpoons
      "All expected Spoons should exist (Hyper, HyperModal, Pomodoro)"
    )

    (helpers.assertTest "directory-structure" structureValid
      "Directory structure should be correct and all components usable"
    )

    # ========================================================================
    # Section 2: init.lua Content Validation (10 tests)
    # ========================================================================

    # Spoon loading tests
    (helpers.assertTest "init-loads-hyper" (lib.hasInfix "hs.loadSpoon('Hyper')" initLuaContent)
      "init.lua should load Hyper Spoon"
    )

    (helpers.assertTest "init-loads-hypermodal"
      (lib.hasInfix "hs.loadSpoon('HyperModal')" initLuaContent)
      "init.lua should load HyperModal Spoon"
    )

    (helpers.assertTest "init-loads-pomodoro" (lib.hasInfix "hs.loadSpoon('Pomodoro')" initLuaContent)
      "init.lua should load Pomodoro Spoon"
    )

    # Hyper key binding tests
    (helpers.assertTest "init-hyper-hotkeys" (lib.hasInfix "Hyper:bindHotKeys" initLuaContent)
      "init.lua should bind Hyper hotkeys"
    )

    (helpers.assertTest "init-hyper-modal-binding"
      (lib.hasInfix "Hyper:bind({}, 'm', function()" initLuaContent)
      "init.lua should bind HyperModal toggle"
    )

    (helpers.assertTest "init-pomodoro-binding"
      (lib.hasInfix "Hyper:bind({}, 'p', function()" initLuaContent)
      "init.lua should bind Pomodoro toggle"
    )

    # Local config support test
    (helpers.assertTest "init-local-config-support"
      (lib.hasInfix "require('localConfig')" initLuaContent)
      "init.lua should support local config override"
    )

    # ========================================================================
    # Section 3: Spoon Metadata Validation (4 tests)
    # ========================================================================

    # Pomodoro Spoon tests
    (helpers.assertTest "pomodoro-spoon-metadata"
      (lib.hasInfix "obj.name = \"Pomodoro\"" pomodoroInitContent)
      "Pomodoro Spoon should define name metadata"
    )

    (helpers.assertTest "pomodoro-spoon-structure" (lib.hasInfix "return obj" pomodoroInitContent)
      "Pomodoro Spoon should return obj"
    )

    # Hyper Spoon tests
    (helpers.assertTest "hyper-spoon-metadata" (lib.hasInfix "m.name = \"Hyper\"" hyperInitContent)
      "Hyper Spoon should define name metadata"
    )

    (helpers.assertTest "hyper-spoon-structure" (lib.hasInfix "return m" hyperInitContent)
      "Hyper Spoon should return m"
    )
  ];
}
