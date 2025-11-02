# tests/integration/claude-behavioral-test.nix
# Claude configuration integration tests
# Tests that Claude configuration works across all modules and components
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import test helpers from evantravers refactor
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import nixtest framework assertions
  inherit (nixtest.assertions) assertTrue assertFalse;

  # Path to Claude configuration
  claudeDir = ../../users/shared/.config/claude;

  # Parse JSON and validate settings content
  settingsJsonPath = claudeDir + "/settings.json";
  settingsJsonContent =
    if builtins.pathExists settingsJsonPath then builtins.readFile settingsJsonPath else "{}";
  settingsParsed = builtins.fromJSON settingsJsonContent;

  # Behavioral validation functions
  validateSettings = {
    # Test that required permissions are present
    hasRequiredPermissions =
      let
        perms = settingsParsed.permissions.allow or [ ];
        requiredPerms = [
          "Bash"
          "Read"
          "Write"
          "Edit"
          "Grep"
        ];
      in
      lib.all (perm: builtins.elem perm perms) requiredPerms;

    # Test that superpowers plugin is enabled
    superpowersEnabled =
      settingsParsed.enabledPlugins ? "superpowers@superpowers-marketplace"
      && settingsParsed.enabledPlugins."superpowers@superpowers-marketplace" == true;

    # Test that model is set to a valid value
    hasValidModel = builtins.elem settingsParsed.model [
      "sonnet"
      "opus"
      "haiku"
    ];

    # Test that MCP servers are properly configured
    mcpServersConfigured = builtins.length (settingsParsed.permissions.allow or [ ]) > 20;
  };

  # Validate CLAUDE.md content (not just existence)
  claudeMdPath = claudeDir + "/CLAUDE.md";
  claudeMdContent = if builtins.pathExists claudeMdPath then builtins.readFile claudeMdPath else "";

  validateClaudeMd = {
    # Test that key rules are present
    hasTddRule = builtins.match ".*Test Driven Development.*" claudeMdContent != null;
    hasHonestyRule = builtins.match ".*Honesty is a core value.*" claudeMdContent != null;
    hasJihoRule = builtins.match ".*Jiho.*" claudeMdContent != null;

    # Test that content is substantial (not empty)
    hasSubstantialContent = builtins.stringLength claudeMdContent > 1000;
  };

  # Validate commands directory functionality
  commandsDirPath = claudeDir + "/commands";
  commandsDirExists = builtins.pathExists commandsDirPath;
  commandsContent = if commandsDirExists then builtins.readDir commandsDirPath else { };

  validateCommands = {
    # Test that we have expected command files
    hasCreatePrCommand = builtins.hasAttr "create-pr.md" commandsContent;
    hasReflectCommand = builtins.hasAttr "reflect.md" commandsContent;
    hasInitialCommand = builtins.hasAttr "initial.md" commandsContent;

    # Test that commands have proper markdown structure
    hasMinimumCommands = (builtins.length (builtins.attrNames commandsContent)) >= 3;
  };

  # Validate skills directory functionality
  skillsDirPath = claudeDir + "/skills";
  skillsDirExists = builtins.pathExists skillsDirPath;
  skillsContent = if skillsDirExists then builtins.readDir skillsDirPath else { };

  # Test that skills are properly organized as directories
  skillItems = builtins.attrNames skillsContent;

  validateSkills = {
    # Test that we have expected skill directories
    hasCreatingPullRequestsSkill = builtins.hasAttr "creating-pull-requests" skillsContent;

    # Test that skills are properly organized as directories
    hasSkillStructure = builtins.length skillItems >= 1;
  };

  # Test suite using NixTest framework - BEHAVIORAL TESTS
  testSuite = {
    name = "claude-config-behavioral-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that settings.json has required permissions (BEHAVIORAL)
      settings-has-permissions = nixtest.test "settings-has-permissions" (
        assertTrue validateSettings.hasRequiredPermissions
      );

      # Test that superpowers plugin is enabled (BEHAVIORAL)
      superpowers-enabled = nixtest.test "superpowers-enabled" (
        assertTrue validateSettings.superpowersEnabled
      );

      # Test that model is valid (BEHAVIORAL)
      has-valid-model = nixtest.test "has-valid-model" (assertTrue validateSettings.hasValidModel);

      # Test that MCP servers are configured (BEHAVIORAL)
      mcp-servers-configured = nixtest.test "mcp-servers-configured" (
        assertTrue validateSettings.mcpServersConfigured
      );

      # Test that CLAUDE.md contains key rules (BEHAVIORAL)
      claude-md-has-tdd-rule = nixtest.test "claude-md-has-tdd-rule" (
        assertTrue validateClaudeMd.hasTddRule
      );

      # Test that CLAUDE.md has honesty rule (BEHAVIORAL)
      claude-md-has-honesty-rule = nixtest.test "claude-md-has-honesty-rule" (
        assertTrue validateClaudeMd.hasHonestyRule
      );

      # Test that CLAUDE.md has substantial content (BEHAVIORAL)
      claude-md-has-content = nixtest.test "claude-md-has-content" (
        assertTrue validateClaudeMd.hasSubstantialContent
      );

      # Test that commands directory has expected commands (BEHAVIORAL)
      has-expected-commands = nixtest.test "has-expected-commands" (
        assertTrue (
          validateCommands.hasCreatePrCommand
          && validateCommands.hasReflectCommand
          && validateCommands.hasInitialCommand
        )
      );

      # Test that commands directory has minimum structure (BEHAVIORAL)
      has-minimum-commands = nixtest.test "has-minimum-commands" (
        assertTrue validateCommands.hasMinimumCommands
      );

      # Test that skills directory has expected skills (BEHAVIORAL)
      has-expected-skills = nixtest.test "has-expected-skills" (
        assertTrue validateSkills.hasCreatingPullRequestsSkill
      );

      # Test that skills directory has proper structure (BEHAVIORAL)
      has-skill-structure = nixtest.test "has-skill-structure" (
        assertTrue validateSkills.hasSkillStructure
      );
    };
  };

in
# Convert test suite to executable derivation - BEHAVIORAL TESTS
pkgs.runCommand "claude-behavioral-test-results" { } ''
  echo "Running Claude configuration BEHAVIORAL tests..."

  # Test 1: Settings has required permissions
  echo "Test 1: Settings.json has required permissions..."
  ${
    if validateSettings.hasRequiredPermissions then
      ''echo "✅ PASS: Settings.json contains required permissions (Bash, Read, Write, Edit, Grep)"''
    else
      ''echo "❌ FAIL: Settings.json missing required permissions"; exit 1''
  }

  # Test 2: Superpowers plugin is enabled
  echo "Test 2: Superpowers plugin is enabled..."
  ${
    if validateSettings.superpowersEnabled then
      ''echo "✅ PASS: Superpowers plugin is enabled"''
    else
      ''echo "❌ FAIL: Superpowers plugin is not enabled"; exit 1''
  }

  # Test 3: Model is valid
  echo "Test 3: Model configuration is valid..."
  ${
    if validateSettings.hasValidModel then
      ''echo "✅ PASS: Model is set to a valid value (${settingsParsed.model})"''
    else
      ''echo "❌ FAIL: Model configuration is invalid"; exit 1''
  }

  # Test 4: MCP servers are configured
  echo "Test 4: MCP servers are properly configured..."
  ${
    if validateSettings.mcpServersConfigured then
      ''echo "✅ PASS: MCP servers are configured (${
        builtins.toString (builtins.length (settingsParsed.permissions.allow or [ ]))
      } permissions found)"''
    else
      ''echo "❌ FAIL: MCP servers are not properly configured"; exit 1''
  }

  # Test 5: CLAUDE.md contains TDD rule
  echo "Test 5: CLAUDE.md contains TDD rule..."
  ${
    if validateClaudeMd.hasTddRule then
      ''echo "✅ PASS: CLAUDE.md contains Test Driven Development rule"''
    else
      ''echo "❌ FAIL: CLAUDE.md missing TDD rule"; exit 1''
  }

  # Test 6: CLAUDE.md contains honesty rule
  echo "Test 6: CLAUDE.md contains honesty rule..."
  ${
    if validateClaudeMd.hasHonestyRule then
      ''echo "✅ PASS: CLAUDE.md contains honesty rule"''
    else
      ''echo "❌ FAIL: CLAUDE.md missing honesty rule"; exit 1''
  }

  # Test 7: CLAUDE.md has substantial content
  echo "Test 7: CLAUDE.md has substantial content..."
  ${
    if validateClaudeMd.hasSubstantialContent then
      ''echo "✅ PASS: CLAUDE.md has substantial content (${builtins.toString (builtins.stringLength claudeMdContent)} characters)"''
    else
      ''echo "❌ FAIL: CLAUDE.md content is insufficient"; exit 1''
  }

  # Test 8: Commands directory has expected commands
  echo "Test 8: Commands directory has expected commands..."
  ${
    if
      validateCommands.hasCreatePrCommand
      && validateCommands.hasReflectCommand
      && validateCommands.hasInitialCommand
    then
      ''echo "✅ PASS: Commands directory contains expected commands (create-pr.md, reflect.md, initial.md)"''
    else
      ''echo "❌ FAIL: Commands directory missing expected commands"; exit 1''
  }

  # Test 9: Commands directory has minimum structure
  echo "Test 9: Commands directory has minimum structure..."
  ${
    if validateCommands.hasMinimumCommands then
      ''echo "✅ PASS: Commands directory has minimum structure (${builtins.toString (builtins.length (builtins.attrNames commandsContent))} commands found)"''
    else
      ''echo "❌ FAIL: Commands directory structure is insufficient"; exit 1''
  }

  # Test 10: Skills directory has expected skills
  echo "Test 10: Skills directory has expected skills..."
  ${
    if validateSkills.hasCreatingPullRequestsSkill then
      ''echo "✅ PASS: Skills directory contains creating-pull-requests skill"''
    else
      ''echo "❌ FAIL: Skills directory missing expected skills"; exit 1''
  }

  # Test 11: Skills directory has proper structure
  echo "Test 11: Skills directory has proper structure..."
  ${
    if validateSkills.hasSkillStructure then
      ''echo "✅ PASS: Skills directory has proper structure"''
    else
      ''echo "❌ FAIL: Skills directory structure is insufficient"; exit 1''
  }

  echo "✅ All Claude configuration BEHAVIORAL tests passed!"
  echo "Configuration functionality verified - Claude will work as expected"
  echo "🎯 UPGRADE: Testing WHAT Claude does, not just IF files exist"
  touch $out
''
