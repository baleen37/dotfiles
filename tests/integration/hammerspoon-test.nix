# tests/unit/hammerspoon-test.nix
# Hammerspoon configuration integrity tests
# Tests that all Hammerspoon config files are present and valid
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import test helpers
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import nixtest framework assertions
  inherit (nixtest.assertions) assertTrue assertFalse;

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

  # Test suite using NixTest framework
  testSuite = {
    name = "hammerspoon-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that Hammerspoon config directory is readable and usable
      hammerspoon-dir-usable = nixtest.test "hammerspoon-dir-usable" (assertTrue hammerspoonDirUsable);

      # Test that init.lua is readable and has content
      init-lua-usable = nixtest.test "init-lua-usable" (assertTrue initLuaUsable);

      # Test that configApplications.lua is readable and has content
      config-apps-usable = nixtest.test "config-apps-usable" (assertTrue configAppsUsable);

      # Test that Spoons directory is readable and usable
      spoons-dir-usable = nixtest.test "spoons-dir-usable" (assertTrue spoonsDirUsable);

      # Test that all required files exist
      required-files-exist = nixtest.test "required-files-exist" (assertTrue hasRequiredFiles);

      # Test that all expected Spoons exist
      expected-spoons-exist = nixtest.test "expected-spoons-exist" (assertTrue hasExpectedSpoons);

      # Test that directory has expected structure (behavioral)
      directory-structure = nixtest.test "directory-structure" (
        assertTrue (hammerspoonDirUsable && initLuaUsable && configAppsUsable && spoonsDirUsable)
      );
    };
  };

in
# Convert test suite to executable derivation
pkgs.runCommand "hammerspoon-test-results" { } ''
  echo "Running Hammerspoon configuration tests..."

  # Test that Hammerspoon config directory is readable and usable
  echo "Test 1: Hammerspoon directory is readable..."
  ${
    if hammerspoonDirUsable then
      ''echo "✅ PASS: Hammerspoon directory is readable and usable"''
    else
      ''echo "❌ FAIL: Hammerspoon directory is not readable or not usable"; exit 1''
  }

  # Test that init.lua is readable and has content
  echo "Test 2: init.lua is readable with content..."
  ${
    if initLuaUsable then
      ''echo "✅ PASS: init.lua is readable and has content"''
    else
      ''echo "❌ FAIL: init.lua is not readable or empty"; exit 1''
  }

  # Test that configApplications.lua is readable and has content
  echo "Test 3: configApplications.lua is readable with content..."
  ${
    if configAppsUsable then
      ''echo "✅ PASS: configApplications.lua is readable and has content"''
    else
      ''echo "❌ FAIL: configApplications.lua is not readable or empty"; exit 1''
  }

  # Test that Spoons directory is readable and usable
  echo "Test 4: Spoons directory is readable..."
  ${
    if spoonsDirUsable then
      ''echo "✅ PASS: Spoons directory is readable and usable"''
    else
      ''echo "❌ FAIL: Spoons directory is not readable or not usable"; exit 1''
  }

  # Test that all required files exist
  echo "Test 5: required files exist..."
  ${
    if hasRequiredFiles then
      ''echo "✅ PASS: All required files exist"''
    else
      ''echo "❌ FAIL: Missing required files"; exit 1''
  }

  # Test that all expected Spoons exist
  echo "Test 6: expected Spoons exist..."
  ${
    if hasExpectedSpoons then
      ''echo "✅ PASS: All expected Spoons exist (Hyper, Headspace, HyperModal)"''
    else
      ''echo "❌ FAIL: Missing expected Spoons"; exit 1''
  }

  # Test that directory has expected structure (behavioral)
  echo "Test 7: directory structure integrity..."
  ${
    if hammerspoonDirUsable && initLuaUsable && configAppsUsable && spoonsDirUsable then
      ''echo "✅ PASS: Directory structure is correct and usable"''
    else
      ''echo "❌ FAIL: Directory structure is incomplete or not usable"; exit 1''
  }

  echo "✅ All Hammerspoon configuration tests passed!"
  echo "Configuration integrity verified - all expected files and directories are present"
  touch $out
''
