# tests/unit/claude-test.nix
# Claude Code configuration behavioral tests
# Tests that Claude configuration is valid and functional
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
  claudeHelpers = import (self + /tests/lib/claude-test-helpers.nix) { inherit pkgs lib helpers; };

  # Path to Claude configuration
  claudeDir = ../../users/shared/.config/claude;

  # Helper to safely read and parse JSON
  readJson = path:
    let
      contentResult = builtins.tryEval (builtins.readFile path);
    in
    if contentResult.success then
      builtins.tryEval (builtins.fromJSON contentResult.value)
    else
      { success = false; };

  # Individual test assertions using helpers.assertTest
  tests = {
    # Test 1: settings.json can be parsed and contains expected fields
    settings-json-valid = helpers.assertTest "settings-json-valid" (
      let
        settingsPath = claudeDir + "/settings.json";
        jsonResult = readJson settingsPath;
        hasContent = jsonResult.success && (builtins.length (builtins.attrNames jsonResult.value) > 0);
      in
      hasContent
    ) "settings.json is missing or empty";

    # Test 2: CLAUDE.md exists and has meaningful content
    claude-md-content = helpers.assertTest "claude-md-content" (
      let
        claudeMdPath = claudeDir + "/CLAUDE.md";
        readResult = builtins.tryEval (builtins.readFile claudeMdPath);
        hasContent = readResult.success && builtins.stringLength readResult.value > 100;
        hasStructure = if hasContent then claudeHelpers.hasMarkdownStructure readResult.value else false;
      in
      hasContent && hasStructure
    ) "CLAUDE.md is missing, too short, or lacks markdown structure";

    # Test 3: Configuration directory exists
    config-dir-exists = helpers.assertTest "config-dir-exists" (
      builtins.pathExists claudeDir
    ) "Claude configuration directory does not exist";
  };

in
# Aggregate all tests into a test suite
{
  platforms = ["any"];
  value = helpers.testSuite "claude-configuration-tests" (builtins.attrValues tests);
}
