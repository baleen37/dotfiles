# Claude Code Test Helpers
#
# Unified test helpers for Claude Code configuration testing.
# Provides reusable functions for testing Claude Code files, markdown structure,
# skill metadata, and Home Manager configuration.
{
  pkgs,
  lib,
  helpers ? import ../lib/test-helpers.nix { inherit pkgs lib; },
}:

rec {
  # Check if a file attribute exists in home.file configuration
  #
  # Parameters:
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check (e.g., ".claude/commands")
  #
  # Returns:
  #   - boolean: true if the file attribute exists
  #
  # Example:
  #   hasFileConfig homeFiles ".claude/commands"
  hasFileConfig = homeFiles: fileAttr: builtins.hasAttr fileAttr homeFiles;

  # Check if a file has force enabled in home.file configuration
  #
  # Parameters:
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check
  #
  # Returns:
  #   - boolean: true if force = true
  #
  # Example:
  #   hasForceEnabled homeFiles ".claude/commands"
  hasForceEnabled = homeFiles: fileAttr:
    if hasFileConfig homeFiles fileAttr then
      homeFiles.${fileAttr}.force or false
    else
      false;

  # Check if a directory is marked as recursive in home.file configuration
  #
  # Parameters:
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check
  #
  # Returns:
  #   - boolean: true if recursive = true
  #
  # Example:
  #   isRecursive homeFiles ".claude/skills"
  isRecursive = homeFiles: fileAttr:
    if hasFileConfig homeFiles fileAttr then
      homeFiles.${fileAttr}.recursive or false
    else
      false;

  # Check if a file is marked as executable in home.file configuration
  #
  # Parameters:
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check
  #
  # Returns:
  #   - boolean: true if executable = true
  #
  # Example:
  #   isExecutable homeFiles ".claude/statusline.sh"
  isExecutable = homeFiles: fileAttr:
    if hasFileConfig homeFiles fileAttr then
      homeFiles.${fileAttr}.executable or false
    else
      false;

  # Check if content has valid markdown structure
  #
  # Parameters:
  #   - content: The markdown content to validate
  #
  # Returns:
  #   - boolean: true if content has markdown structure (heading or YAML frontmatter)
  #
  # Example:
  #   hasMarkdownStructure "# My Document\n\nContent here"
  hasMarkdownStructure = content:
    (builtins.match ".*#.*" content != null) ||
    (builtins.match ".*---.*description:.*" content != null);

  # Check if content has skill metadata (name and description)
  #
  # Parameters:
  #   - content: The skill file content to validate
  #
  # Returns:
  #   - boolean: true if content has both name and description fields
  #
  # Example:
  #   hasSkillMetadata "name: my-skill\ndescription: Does something"
  hasSkillMetadata = content:
    (builtins.match ".*name:.*" content != null) &&
    (builtins.match ".*description:.*" content != null);

  # Assert that a Claude file is configured in home.file
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check
  #
  # Returns:
  #   - derivation: Test derivation that passes if file is configured
  #
  # Example:
  #   assertClaudeFileConfigured "commands-configured" homeFiles ".claude/commands"
  assertClaudeFileConfigured = testName: homeFiles: fileAttr:
    helpers.assertTest "${lib.strings.sanitizeDerivationName testName}-configured" (hasFileConfig homeFiles fileAttr)
      "${fileAttr} should be configured in home.file";

  # Assert that a Claude file has force enabled
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check
  #
  # Returns:
  #   - derivation: Test derivation that passes if force is enabled
  #
  # Example:
  #   assertClaudeFileForceEnabled "commands-force" homeFiles ".claude/commands"
  assertClaudeFileForceEnabled = testName: homeFiles: fileAttr:
    helpers.assertTest "${lib.strings.sanitizeDerivationName testName}-force-enabled" (hasForceEnabled homeFiles fileAttr)
      "${fileAttr} should have force=true to overwrite existing files";

  # Assert that a directory is recursive
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check
  #
  # Returns:
  #   - derivation: Test derivation that passes if directory is recursive
  #
  # Example:
  #   assertClaudeDirRecursive "skills-recursive" homeFiles ".claude/skills"
  assertClaudeDirRecursive = testName: homeFiles: fileAttr:
    helpers.assertTest "${lib.strings.sanitizeDerivationName testName}-recursive" (isRecursive homeFiles fileAttr)
      "${fileAttr} should be recursive to copy all contents";

  # Assert that a file is executable
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #   - fileAttr: The file attribute path to check
  #
  # Returns:
  #   - derivation: Test derivation that passes if file is executable
  #
  # Example:
  #   assertClaudeFileExecutable "statusline-executable" homeFiles ".claude/statusline.sh"
  assertClaudeFileExecutable = testName: homeFiles: fileAttr:
    helpers.assertTest "${lib.strings.sanitizeDerivationName testName}-executable" (isExecutable homeFiles fileAttr)
      "${fileAttr} should be marked as executable";

  # Assert that content has valid markdown structure
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - content: The markdown content to validate
  #   - message: Optional custom failure message
  #
  # Returns:
  #   - derivation: Test derivation that passes if content has markdown structure
  #
  # Example:
  #   assertClaudeMarkdown "claude-md-valid" content
  assertClaudeMarkdown = testName: content: message:
    let
      defaultMessage = "Content should have markdown structure (heading or YAML frontmatter)";
    in
    helpers.assertTest testName (hasMarkdownStructure content)
      (if message == null then defaultMessage else message);

  # Assert that content has skill metadata
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - content: The skill file content to validate
  #
  # Returns:
  #   - derivation: Test derivation that passes if content has skill metadata
  #
  # Example:
  #   assertClaudeSkillMetadata "skill-metadata-valid" content
  assertClaudeSkillMetadata = testName: content:
    helpers.assertTest testName (hasSkillMetadata content)
      "Content should have skill metadata (name and description fields)";

  # Assert that a directory is readable and contains files
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - dirPath: The path to the directory to check
  #
  # Returns:
  #   - list: Two test derivations (readable and has-files)
  #
  # Example:
  #   assertClaudeDirReadableAndHasFiles "commands" sourcePaths.commands
  assertClaudeDirReadableAndHasFiles = testName: dirPath:
    let
      dirReadable = builtins.tryEval (builtins.readDir dirPath);
    in
    [
      (helpers.assertTest "${testName}-dir-readable" dirReadable.success
        "${testName} source directory should be readable")
      (helpers.assertTest "${testName}-dir-has-files"
        (dirReadable.success && builtins.length (builtins.attrNames dirReadable.value) > 0)
        "${testName} source directory should contain files")
    ];

  # Assert that a file is readable and has content
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - filePath: The path to the file to check
  #
  # Returns:
  #   - list: Two test derivations (readable and has-content)
  #
  # Example:
  #   assertClaudeFileReadableAndHasContent "statusline" sourcePaths.statusline
  assertClaudeFileReadableAndHasContent = testName: filePath:
    let
      fileReadable = builtins.tryEval (builtins.readFile filePath);
    in
    [
      (helpers.assertTest "${testName}-readable" fileReadable.success
        "${testName} source file should be readable")
      (helpers.assertTest "${testName}-has-content"
        (fileReadable.success && builtins.stringLength fileReadable.value > 0)
        "${testName} source file should have content")
    ];

  # Assert that activation script exists in Home Manager configuration
  #
  # Parameters:
  #   - testName: The test name for reporting
  #   - activation: The home.activation attribute set from a Home Manager config
  #   - activationName: The name of the activation script to check
  #
  # Returns:
  #   - derivation: Test derivation that passes if activation exists
  #
  # Example:
  #   assertClaudeActivationExists "settings-activation" activation "claudeSettings"
  assertClaudeActivationExists = testName: activation: activationName:
    let
      activationSet = if activation == null then { } else activation;
    in
    helpers.assertTest testName (builtins.hasAttr activationName activationSet)
      "Activation script for ${activationName} should exist";

  # Bulk assertion helper for multiple Claude file configurations
  #
  # Parameters:
  #   - fileAttrs: List of file attribute paths to check
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #
  # Returns:
  #   - list: Test derivations for each file configuration
  #
  # Example:
  #   assertClaudeFilesConfigured [".claude/commands" ".claude/agents"] homeFiles
  assertClaudeFilesConfigured = fileAttrs: homeFiles:
    builtins.map (fileAttr:
      assertClaudeFileConfigured
        (lib.strings.sanitizeDerivationName fileAttr)
        homeFiles
        fileAttr
    ) fileAttrs;

  # Bulk assertion helper for force enabled on multiple files
  #
  # Parameters:
  #   - fileAttrs: List of file attribute paths to check
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #
  # Returns:
  #   - list: Test derivations for each force-enabled check
  #
  # Example:
  #   assertClaudeFilesForceEnabled [".claude/commands" ".claude/agents"] homeFiles
  assertClaudeFilesForceEnabled = fileAttrs: homeFiles:
    builtins.map (fileAttr:
      assertClaudeFileForceEnabled
        (lib.strings.sanitizeDerivationName fileAttr)
        homeFiles
        fileAttr
    ) fileAttrs;

  # Bulk assertion helper for recursive directories
  #
  # Parameters:
  #   - fileAttrs: List of file attribute paths to check
  #   - homeFiles: The home.file attribute set from a Home Manager config
  #
  # Returns:
  #   - list: Test derivations for each recursive check
  #
  # Example:
  #   assertClaudeDirsRecursive [".claude/commands" ".claude/skills"] homeFiles
  assertClaudeDirsRecursive = fileAttrs: homeFiles:
    builtins.map (fileAttr:
      assertClaudeDirRecursive
        (lib.strings.sanitizeDerivationName fileAttr)
        homeFiles
        fileAttr
    ) fileAttrs;
}
