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
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  testHelpers = helpers;

  # Import nixtest framework assertions
  inherit (nixtest.assertions) assertTrue assertFalse;

  # Path to Hammerspoon configuration
  hammerspoonDir = ../../users/shared/.config/hammerspoon;

  # Basic existence checks
  hammerspoonDirExists = builtins.pathExists hammerspoonDir;
  initLuaExists = builtins.pathExists (hammerspoonDir + "/init.lua");
  configAppsExists = builtins.pathExists (hammerspoonDir + "/configApplications.lua");
  spoonsDirExists = builtins.pathExists (hammerspoonDir + "/Spoons");

  # Directory structure validation
  hammerspoonDirContents = if hammerspoonDirExists then builtins.readDir hammerspoonDir else { };
  hasRequiredFiles =
    builtins.hasAttr "init.lua" hammerspoonDirContents
    && builtins.hasAttr "configApplications.lua" hammerspoonDirContents
    && builtins.hasAttr "Spoons" hammerspoonDirContents;

  # Spoons directory validation
  spoonsContents = if spoonsDirExists then builtins.readDir (hammerspoonDir + "/Spoons") else { };
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
      # Test that Hammerspoon config directory exists
      hammerspoon-dir-exists = nixtest.test "hammerspoon-dir-exists" (assertTrue hammerspoonDirExists);

      # Test that init.lua exists
      init-lua-exists = nixtest.test "init-lua-exists" (assertTrue initLuaExists);

      # Test that configApplications.lua exists
      config-apps-exists = nixtest.test "config-apps-exists" (assertTrue configAppsExists);

      # Test that Spoons directory exists
      spoons-dir-exists = nixtest.test "spoons-dir-exists" (assertTrue spoonsDirExists);

      # Test that all required files exist
      required-files-exist = nixtest.test "required-files-exist" (assertTrue hasRequiredFiles);

      # Test that all expected Spoons exist
      expected-spoons-exist = nixtest.test "expected-spoons-exist" (assertTrue hasExpectedSpoons);

      # Test that directory has expected structure
      directory-structure = nixtest.test "directory-structure" (
        assertTrue (hammerspoonDirExists && initLuaExists && configAppsExists && spoonsDirExists)
      );
    };
  };

in
# Convert test suite to executable derivation
helpers.mkTest "hammerspoon-config" ''

  # Test that Hammerspoon config directory exists
  echo "Test 1: Hammerspoon directory exists..."
  ${
    if hammerspoonDirExists then
      ''echo "✅ PASS: Hammerspoon directory exists"''
    else
      ''echo "❌ FAIL: Hammerspoon directory not found"; exit 1''
  }

  # Test that init.lua exists
  echo "Test 2: init.lua exists..."
  ${
    if initLuaExists then
      ''echo "✅ PASS: init.lua exists"''
    else
      ''echo "❌ FAIL: init.lua not found"; exit 1''
  }

  # Test that configApplications.lua exists
  echo "Test 3: configApplications.lua exists..."
  ${
    if configAppsExists then
      ''echo "✅ PASS: configApplications.lua exists"''
    else
      ''echo "❌ FAIL: configApplications.lua not found"; exit 1''
  }

  # Test that Spoons directory exists
  echo "Test 4: Spoons directory exists..."
  ${
    if spoonsDirExists then
      ''echo "✅ PASS: Spoons directory exists"''
    else
      ''echo "❌ FAIL: Spoons directory not found"; exit 1''
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

  # Test that directory has expected structure
  echo "Test 7: directory structure integrity..."
  ${
    if hammerspoonDirExists && initLuaExists && configAppsExists && spoonsDirExists then
      ''echo "✅ PASS: Directory structure is correct"''
    else
      ''echo "❌ FAIL: Directory structure is incomplete"; exit 1''
  }

  echo "✅ All Hammerspoon configuration tests passed!"
  echo "Configuration integrity verified - all expected files and directories are present"
''
