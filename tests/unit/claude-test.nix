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

    # Test 3: Command files have valid structure
    commands-have-structure = helpers.assertTest "commands-have-structure" (
      let
        commandsDir = claudeDir + "/commands";
        readResult = builtins.tryEval (builtins.readDir commandsDir);
      in
      if readResult.success then
        let
          mdFiles = lib.filterAttrs (name: type: lib.hasSuffix ".md" name) readResult.value;
          fileNames = lib.attrNames mdFiles;

          validateFile = fileName:
            let
              filePath = commandsDir + "/${fileName}";
              contentResult = builtins.tryEval (builtins.readFile filePath);
            in
            contentResult.success && claudeHelpers.hasMarkdownStructure contentResult.value;

          validFiles = builtins.filter validateFile fileNames;
        in
        builtins.length validFiles > 0
      else
        false
    ) "No valid command files found or commands directory missing";

    # Test 4: Skill files have required metadata
    skills-have-metadata = helpers.assertTest "skills-have-metadata" (
      let
        skillsDir = claudeDir + "/skills";
        readResult = builtins.tryEval (builtins.readDir skillsDir);
      in
      if readResult.success then
        let
          # Skills can be directories (with SKILL.md) or markdown files
          allEntries = readResult.value;

          validateSkillEntry = entryName: entryType:
            let
              entryPath = skillsDir + "/${entryName}";
            in
            if entryType == "directory" then
              let
                skillMdPath = entryPath + "/SKILL.md";
                contentResult = builtins.tryEval (builtins.readFile skillMdPath);
              in
              contentResult.success && claudeHelpers.hasSkillMetadata contentResult.value
            else if lib.hasSuffix ".md" entryName then
              let
                contentResult = builtins.tryEval (builtins.readFile entryPath);
              in
              contentResult.success && claudeHelpers.hasSkillMetadata contentResult.value
            else
              false;

          validEntries = lib.attrNames (
            lib.filterAttrs validateSkillEntry allEntries
          );
        in
        builtins.length validEntries > 0
      else
        false
    ) "No valid skill files found or skills directory missing";

    # Test 5: Configuration directory exists
    config-dir-exists = helpers.assertTest "config-dir-exists" (
      builtins.pathExists claudeDir
    ) "Claude configuration directory does not exist";

    # Test 6: Commands directory exists (if configured)
    commands-dir-exists = helpers.assertTest "commands-dir-exists" (
      builtins.pathExists (claudeDir + "/commands")
    ) "Commands directory does not exist";

    # Test 7: Skills directory exists (if configured)
    skills-dir-exists = helpers.assertTest "skills-dir-exists" (
      builtins.pathExists (claudeDir + "/skills")
    ) "Skills directory does not exist";

    # Test 8: Hooks directory exists (if configured)
    hooks-dir-exists = helpers.assertTest "hooks-dir-exists" (
      builtins.pathExists (claudeDir + "/hooks")
    ) "Hooks directory does not exist";

    # Test 9: Agents directory exists (if configured)
    agents-dir-exists = helpers.assertTest "agents-dir-exists" (
      builtins.pathExists (claudeDir + "/agents")
    ) "Agents directory does not exist";
  };

in
# Aggregate all tests into a test suite
{
  platforms = ["any"];
  value = helpers.testSuite "claude-configuration-tests" (builtins.attrValues tests);
}
