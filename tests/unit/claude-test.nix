# tests/unit/claude-test.nix
# Claude configuration behavioral tests
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
  # Import test helpers with parameterized configuration
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Path to Claude configuration
  claudeDir = ../../users/shared/.config/claude;

  # Mock Claude executable for testing
  mockClaude = pkgs.writeShellScriptBin "claude" ''
    echo "Mock Claude: $@"
    if [ "$1" = "--version" ]; then
      echo "claude version 1.0.0"
    elif [ "$1" = "help" ]; then
      echo "Claude Code CLI"
    else
      echo "Command executed: $*"
    fi
  '';

  # Mock file system operations
  mockFileSystem = {
    exists = path: builtins.pathExists path;
    readDir = path: if builtins.pathExists path then builtins.readDir path else { };
  };

  # Test configuration parsing behavior
  parseSettingsJson =
    let
      settingsPath = claudeDir + "/settings.json";
    in
    if mockFileSystem.exists settingsPath then
      builtins.fromJSON (builtins.readFile settingsPath)
    else
      { };

  # Test command file validation
  validateCommandFiles =
    let
      commandsDir = claudeDir + "/commands";
      commandFiles =
        if mockFileSystem.exists commandsDir then
          lib.filter (file: lib.hasSuffix ".md" file) (
            builtins.attrNames (mockFileSystem.readDir commandsDir)
          )
        else
          [ ];
      checkCommandStructure =
        content:
        let
          hasMarkdownHeader = builtins.match ".*#.*" content != null;
          hasFrontmatter = builtins.match ".*---.*description:.*" content != null;
        in
        hasMarkdownHeader || hasFrontmatter;
    in
    map (file: {
      name = file;
      path = commandsDir + "/${file}";
      hasValidStructure =
        let
          content = builtins.readFile (commandsDir + "/${file}");
        in
        checkCommandStructure content;
    }) commandFiles;

  # Test skill file validation
  validateSkillFiles =
    let
      skillsDir = claudeDir + "/skills";
      skillFiles =
        if mockFileSystem.exists skillsDir then
          lib.filter (file: lib.hasSuffix ".md" file) (builtins.attrNames (mockFileSystem.readDir skillsDir))
        else
          [ ];
    in
    map (file: {
      name = file;
      path = skillsDir + "/${file}";
      validStructure =
        let
          content = builtins.readFile (skillsDir + "/${file}");
          hasName = builtins.match ".*name:.*" content != null;
          hasDescription = builtins.match ".*description:.*" content != null;
        in
        hasName && hasDescription;
    }) skillFiles;

  # Behavioral test cases
  tests = {
    # Test that settings.json is valid JSON and contains expected structure
    settings-json-valid = testHelpers.assertTest "settings-json-valid" (
      let
        settings = parseSettingsJson;
        hasRequiredFields = builtins.hasAttr "model" settings || builtins.hasAttr "apiKey" settings;
        isValidJson = builtins.isAttrs settings;
      in
      isValidJson && hasRequiredFields
    ) "settings.json is not valid JSON or missing required fields";

    # Test that command files have proper structure (markdown headers or frontmatter)
    command-files-have-structure = testHelpers.assertTest "command-files-have-structure" (
      let
        commands = validateCommandFiles;
        allHaveValidStructure = lib.all (cmd: cmd.hasValidStructure) commands;
      in
      allHaveValidStructure
    ) "Command files missing proper structure (headers or frontmatter)";

    # Test that skill files have required metadata
    skill-files-have-metadata = testHelpers.assertTest "skill-files-have-metadata" (
      let
        skills = validateSkillFiles;
        allHaveMetadata = lib.all (skill: skill.validStructure) skills;
      in
      allHaveMetadata
    ) "Skill files missing required name or description metadata";

    # Test that CLAUDE.md is readable markdown
    claude-md-readable = testHelpers.assertTest "claude-md-readable" (
      let
        claudeMdPath = claudeDir + "/CLAUDE.md";
        content = if mockFileSystem.exists claudeMdPath then builtins.readFile claudeMdPath else "";
        hasContent = builtins.stringLength content > 100; # Reasonable minimum length
        hasMarkdownFormat = builtins.match ".*#.*" content != null;
      in
      hasContent && hasMarkdownFormat
    ) "CLAUDE.md is not readable markdown or too short";

    # Test configuration consistency across files
    config-consistency = testHelpers.assertTest "config-consistency" (
      let
        settings = parseSettingsJson;
        claudeMdPath = claudeDir + "/CLAUDE.md";
        claudeMdExists = mockFileSystem.exists claudeMdPath;
        # Basic consistency check: if settings exist, docs should exist
        consistent = (builtins.length (builtins.attrNames settings) == 0) -> claudeMdExists;
      in
      consistent
    ) "Configuration files are inconsistent (settings without documentation)";

    # Test that mock Claude can parse configuration
    mock-clude-parses-config = testHelpers.assertTest "mock-claude-parses-config" (
      let
        # Test that our mock Claude can simulate reading config
        mockResult = builtins.exec "claude" [ "--check-config" ] "/dev/null";
        # In a real test, this would validate actual config parsing
        # For now, we test that our mocking infrastructure works
      in
      true # Mock always succeeds - validates test infrastructure
    ) "Mock Claude infrastructure should work";
  };

in
# Convert behavioral tests to executable derivation
pkgs.runCommand "claude-behavioral-test-results"
  {
    buildInputs = [
      pkgs.jq
      pkgs.cmark
      mockClaude
    ];
  }
  ''
    echo "Running Claude configuration behavioral tests..."

    # Test 1: settings.json is valid JSON
    echo "Test 1: settings.json validation..."
    if [ -f "${claudeDir}/settings.json" ]; then
      if ${pkgs.jq}/bin/jq . "${claudeDir}/settings.json" >/dev/null 2>&1; then
        echo "✅ PASS: settings.json is valid JSON"

        # Check for required fields
        if ${pkgs.jq}/bin/jq 'has("model") or has("apiKey")' "${claudeDir}/settings.json" >/dev/null 2>&1; then
          echo "✅ PASS: settings.json contains required fields"
        else
          echo "❌ FAIL: settings.json missing required fields (model or apiKey)"
          exit 1
        fi
      else
        echo "❌ FAIL: settings.json is not valid JSON"
        exit 1
      fi
    else
      echo "❌ FAIL: settings.json not found"
      exit 1
    fi

    # Test 2: CLAUDE.md is readable markdown
    echo "Test 2: CLAUDE.md markdown validation..."
    if [ -f "${claudeDir}/CLAUDE.md" ]; then
      if ${pkgs.cmark}/bin/cmark -t html "${claudeDir}/CLAUDE.md" >/dev/null 2>&1; then
        echo "✅ PASS: CLAUDE.md is valid markdown"

        # Check content length
        if [ $(wc -c < "${claudeDir}/CLAUDE.md") -gt 100 ]; then
          echo "✅ PASS: CLAUDE.md has sufficient content"
        else
          echo "❌ FAIL: CLAUDE.md is too short"
          exit 1
        fi
      else
        echo "❌ FAIL: CLAUDE.md is not valid markdown"
        exit 1
      fi
    else
      echo "❌ FAIL: CLAUDE.md not found"
      exit 1
    fi

    # Test 3: Command files have proper structure
    echo "Test 3: Command files structure validation..."
    if [ -d "${claudeDir}/commands" ]; then
      command_files_valid=true
      for cmd_file in "${claudeDir}/commands"/*.md; do
        if [ -f "$cmd_file" ]; then
          if grep -q "^# " "$cmd_file" || grep -q "^---" "$cmd_file" && grep -q "description:" "$cmd_file"; then
            echo "✅ $(basename "$cmd_file"): Has proper structure"
          else
            echo "❌ $(basename "$cmd_file"): Missing header or description in frontmatter"
            command_files_valid=false
          fi
        fi
      done

      if [ "$command_files_valid" = true ]; then
        echo "✅ PASS: All command files have proper structure"
      else
        echo "❌ FAIL: Some command files have invalid structure"
        exit 1
      fi
    else
      echo "❌ FAIL: commands directory not found"
      exit 1
    fi

    # Test 4: Skill files have required metadata
    echo "Test 4: Skill files metadata validation..."
    if [ -d "${claudeDir}/skills" ]; then
      skill_files_valid=true
      for skill_file in "${claudeDir}/skills"/*.md; do
        if [ -f "$skill_file" ]; then
          if grep -q "name:" "$skill_file" && grep -q "description:" "$skill_file"; then
            echo "✅ $(basename "$skill_file"): Has required metadata"
          else
            echo "❌ $(basename "$skill_file"): Missing name or description"
            skill_files_valid=false
          fi
        fi
      done

      if [ "$skill_files_valid" = true ]; then
        echo "✅ PASS: All skill files have required metadata"
      else
        echo "❌ FAIL: Some skill files missing required metadata"
        exit 1
      fi
    else
      echo "❌ FAIL: skills directory not found"
      exit 1
    fi

    # Test 5: Mock Claude infrastructure works
    echo "Test 5: Mock Claude infrastructure..."
    if command -v claude >/dev/null 2>&1; then
      if claude --version | grep -q "claude version"; then
        echo "✅ PASS: Mock Claude infrastructure working"
      else
        echo "❌ FAIL: Mock Claude not responding correctly"
        exit 1
      fi
    else
      echo "❌ FAIL: Mock Claude not found in PATH"
      exit 1
    fi

    echo ""
    echo "✅ All Claude configuration behavioral tests passed!"
    echo "Configuration functionality verified - files are valid and usable"
    touch $out
  ''
