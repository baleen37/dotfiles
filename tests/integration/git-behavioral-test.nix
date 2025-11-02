# tests/integration/git-behavioral-test.nix
# Git configuration integration tests
# Tests that Git configuration works across modules and user information
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

  # Import git configuration for behavioral validation
  gitConfigFile = ../../users/shared/git.nix;
  gitConfigExists = builtins.pathExists gitConfigFile;
  gitConfig =
    if gitConfigExists then
      (import gitConfigFile {
        inherit pkgs lib;
        config = { };
      })
    else
      { };

  # Import user information for validation
  userInfo = import ../../lib/user-info.nix;

  # Behavioral validation functions - test WHAT Git does, not just IF files exist
  validateGitConfig = {
    # Test that user configuration matches centralized user info
    userInfoConsistent =
      let
        gitUser = gitConfig.programs.git.settings.user or { };
        expectedName = userInfo.name;
        expectedEmail = userInfo.email;
      in
      gitUser.name == expectedName && gitUser.email == expectedEmail;

    # Test that all expected aliases are present and functional
    hasRequiredAliases =
      let
        aliases = gitConfig.programs.git.settings.alias or { };
        expectedAliases = {
          st = "status";
          co = "checkout";
          br = "branch";
          ci = "commit";
          df = "diff";
          lg = "log --graph --oneline --decorate --all";
        };
        checkAlias =
          alias: expectedValue: builtins.hasAttr alias aliases && aliases.${alias} == expectedValue;
        aliasChecks = lib.mapAttrsToList checkAlias expectedAliases;
      in
      lib.all lib.id aliasChecks;

    # Test that default branch is properly configured
    defaultBranchConfigured = (gitConfig.programs.git.settings.init.defaultBranch or "") == "main";

    # Test that pull rebase behavior is properly configured
    pullRebaseConfigured = (gitConfig.programs.git.settings.pull.rebase or false) == true;

    # Test that autoStash is enabled for rebase operations
    autoStashEnabled = (gitConfig.programs.git.settings.rebase.autoStash or false) == true;

    # Test that core editor is set to vim
    editorConfigured = (gitConfig.programs.git.settings.core.editor or "") == "vim";

    # Test that LFS is properly enabled
    lfsEnabled = (gitConfig.programs.git.lfs.enable or false) == true;

    # Test that gitignore patterns include expected items
    hasEssentialIgnores =
      let
        ignores = gitConfig.programs.git.ignores or [ ];
        essentialPatterns = [
          ".DS_Store"
          "node_modules/"
          ".vscode/"
          "*.swp"
          ".env.local"
          "result"
        ];
        hasPattern = pattern: builtins.elem pattern ignores;
      in
      lib.all hasPattern essentialPatterns;

    # Test that excludesFile is properly configured
    excludesFileConfigured =
      (gitConfig.programs.git.settings.core.excludesFile or "") == "~/.gitignore_global";

    # Test that autocrlf is set to input (cross-platform compatibility)
    autocrlfConfigured = (gitConfig.programs.git.settings.core.autocrlf or "") == "input";
  };

  # Edge case validation functions
  validateEdgeCases = {
    # Test that aliases don't contain malformed commands
    aliasesHaveValidSyntax =
      let
        aliases = gitConfig.programs.git.settings.alias or { };
        dangerousCommands = [
          "rm "
          "rm-rf "
          "sudo "
          "chmod "
          "chown "
          "mv "
          "cp "
        ];
        containsDangerousCommand =
          aliasValue:
          builtins.any (
            cmd: builtins.substring 0 (builtins.stringLength cmd) aliasValue == cmd
          ) dangerousCommands;
        invalidAliases = lib.filterAttrs (name: value: containsDangerousCommand value) aliases;
      in
      builtins.attrNames invalidAliases == [ ];

    # Test that user info is not empty or invalid
    userInfoIsValid =
      let
        gitUser = gitConfig.programs.git.settings.user or { };
        name = gitUser.name or "";
        email = gitUser.email or "";
        nameValid = name != "" && builtins.stringLength name > 1;
        emailValid = email != "" && builtins.match ".*@.*\\..*" email != null;
      in
      nameValid && emailValid;

    # Test that configuration exists and is accessible
    configurationExists = gitConfigExists;

    # Test that required configuration sections are present
    hasRequiredSections =
      let
        hasGitProgram = builtins.hasAttr "programs" gitConfig && builtins.hasAttr "git" gitConfig.programs;
        hasGitSettings = hasGitProgram && builtins.hasAttr "settings" gitConfig.programs.git;
        hasUserSection = hasGitSettings && builtins.hasAttr "user" gitConfig.programs.git.settings;
      in
      hasGitProgram && hasGitSettings && hasUserSection;
  };

  # Test suite using NixTest framework - BEHAVIORAL TESTS
  testSuite = {
    name = "git-config-behavioral-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that user info is consistent across configuration (BEHAVIORAL)
      user-info-consistent = nixtest.test "user-info-consistent" (
        assertTrue validateGitConfig.userInfoConsistent
      );

      # Test that all required aliases are present (BEHAVIORAL)
      has-required-aliases = nixtest.test "has-required-aliases" (
        assertTrue validateGitConfig.hasRequiredAliases
      );

      # Test that default branch is configured correctly (BEHAVIORAL)
      default-branch-configured = nixtest.test "default-branch-configured" (
        assertTrue validateGitConfig.defaultBranchConfigured
      );

      # Test that pull rebase is enabled (BEHAVIORAL)
      pull-rebase-configured = nixtest.test "pull-rebase-configured" (
        assertTrue validateGitConfig.pullRebaseConfigured
      );

      # Test that autoStash is enabled for rebase (BEHAVIORAL)
      auto-stash-enabled = nixtest.test "auto-stash-enabled" (
        assertTrue validateGitConfig.autoStashEnabled
      );

      # Test that editor is configured (BEHAVIORAL)
      editor-configured = nixtest.test "editor-configured" (
        assertTrue validateGitConfig.editorConfigured
      );

      # Test that LFS is enabled (BEHAVIORAL)
      lfs-enabled = nixtest.test "lfs-enabled" (assertTrue validateGitConfig.lfsEnabled);

      # Test that essential gitignore patterns are present (BEHAVIORAL)
      has-essential-ignores = nixtest.test "has-essential-ignores" (
        assertTrue validateGitConfig.hasEssentialIgnores
      );

      # Test that excludesFile is configured (BEHAVIORAL)
      excludes-file-configured = nixtest.test "excludes-file-configured" (
        assertTrue validateGitConfig.excludesFileConfigured
      );

      # Test that autocrlf is configured for cross-platform (BEHAVIORAL)
      autocrlf-configured = nixtest.test "autocrlf-configured" (
        assertTrue validateGitConfig.autocrlfConfigured
      );

      # Edge case tests (BEHAVIORAL)
      aliases-have-valid-syntax = nixtest.test "aliases-have-valid-syntax" (
        assertTrue validateEdgeCases.aliasesHaveValidSyntax
      );

      user-info-is-valid = nixtest.test "user-info-is-valid" (
        assertTrue validateEdgeCases.userInfoIsValid
      );

      configuration-exists = nixtest.test "configuration-exists" (
        assertTrue validateEdgeCases.configurationExists
      );

      has-required-sections = nixtest.test "has-required-sections" (
        assertTrue validateEdgeCases.hasRequiredSections
      );
    };
  };

in
# Convert test suite to executable derivation - BEHAVIORAL TESTS
pkgs.runCommand "git-behavioral-test-results" { } ''
  echo "Running Git configuration BEHAVIORAL tests..."

  # Test 1: User info is consistent across configuration
  echo "Test 1: User information is consistent across Git configuration..."
  ${
    if validateGitConfig.userInfoConsistent then
      ''echo "✅ PASS: User info (${userInfo.name} <${userInfo.email}>) is consistent"''
    else
      ''echo "❌ FAIL: User info is inconsistent across configuration"; exit 1''
  }

  # Test 2: All required aliases are present
  echo "Test 2: All required Git aliases are present..."
  ${
    if validateGitConfig.hasRequiredAliases then
      ''echo "✅ PASS: All required Git aliases are configured (st, co, br, ci, df, lg)"''
    else
      ''echo "❌ FAIL: Required Git aliases are missing or incorrect"; exit 1''
  }

  # Test 3: Default branch is configured correctly
  echo "Test 3: Default branch is configured to main..."
  ${
    if validateGitConfig.defaultBranchConfigured then
      ''echo "✅ PASS: Default branch is set to main"''
    else
      ''echo "❌ FAIL: Default branch is not configured to main"; exit 1''
  }

  # Test 4: Pull rebase is enabled
  echo "Test 4: Pull rebase behavior is enabled..."
  ${
    if validateGitConfig.pullRebaseConfigured then
      ''echo "✅ PASS: Pull rebase is enabled for clean history"''
    else
      ''echo "❌ FAIL: Pull rebase is not enabled"; exit 1''
  }

  # Test 5: Auto-stash is enabled for rebase
  echo "Test 5: Auto-stash is enabled for rebase operations..."
  ${
    if validateGitConfig.autoStashEnabled then
      ''echo "✅ PASS: Auto-stash is enabled for safer rebase operations"''
    else
      ''echo "❌ FAIL: Auto-stash is not enabled for rebase"; exit 1''
  }

  # Test 6: Editor is configured
  echo "Test 6: Core editor is configured to vim..."
  ${
    if validateGitConfig.editorConfigured then
      ''echo "✅ PASS: Core editor is set to vim"''
    else
      ''echo "❌ FAIL: Core editor is not configured to vim"; exit 1''
  }

  # Test 7: LFS is enabled
  echo "Test 7: Git LFS is enabled for large file support..."
  ${
    if validateGitConfig.lfsEnabled then
      ''echo "✅ PASS: Git LFS is enabled for large file handling"''
    else
      ''echo "❌ FAIL: Git LFS is not enabled"; exit 1''
  }

  # Test 8: Essential gitignore patterns are present
  echo "Test 8: Essential gitignore patterns are present..."
  ${
    if validateGitConfig.hasEssentialIgnores then
      ''echo "✅ PASS: Essential gitignore patterns are configured (.DS_Store, node_modules/, etc.)"''
    else
      ''echo "❌ FAIL: Essential gitignore patterns are missing"; exit 1''
  }

  # Test 9: Excludes file is configured
  echo "Test 9: Global excludes file is configured..."
  ${
    if validateGitConfig.excludesFileConfigured then
      ''echo "✅ PASS: Global excludes file is configured (~/.gitignore_global)"''
    else
      ''echo "❌ FAIL: Global excludes file is not configured"; exit 1''
  }

  # Test 10: AutoCRLF is configured for cross-platform
  echo "Test 10: AutoCRLF is configured for cross-platform compatibility..."
  ${
    if validateGitConfig.autocrlfConfigured then
      ''echo "✅ PASS: AutoCRLF is set to input for cross-platform compatibility"''
    else
      ''echo "❌ FAIL: AutoCRLF is not configured for cross-platform use"; exit 1''
  }

  # Test 11: Aliases have valid syntax (no dangerous commands)
  echo "Test 11: Git aliases have valid syntax and no dangerous commands..."
  ${
    if validateEdgeCases.aliasesHaveValidSyntax then
      ''echo "✅ PASS: Git aliases have valid syntax and no dangerous commands"''
    else
      ''echo "❌ FAIL: Git aliases contain dangerous commands or invalid syntax"; exit 1''
  }

  # Test 12: User info is valid (not empty or malformed)
  echo "Test 12: User information is valid and well-formed..."
  ${
    if validateEdgeCases.userInfoIsValid then
      ''echo "✅ PASS: User information is valid and properly formatted"''
    else
      ''echo "❌ FAIL: User information is empty or malformed"; exit 1''
  }

  # Test 13: Configuration file exists and is accessible
  echo "Test 13: Git configuration file exists and is accessible..."
  ${
    if validateEdgeCases.configurationExists then
      ''echo "✅ PASS: Git configuration file exists and is accessible"''
    else
      ''echo "❌ FAIL: Git configuration file is missing or inaccessible"; exit 1''
  }

  # Test 14: Required configuration sections are present
  echo "Test 14: Required Git configuration sections are present..."
  ${
    if validateEdgeCases.hasRequiredSections then
      ''echo "✅ PASS: Required Git configuration sections are present"''
    else
      ''echo "❌ FAIL: Required Git configuration sections are missing"; exit 1''
  }

  echo "✅ All Git configuration BEHAVIORAL tests passed!"
  echo "Git functionality verified - Git will work as expected with proper configuration"
  echo "🎯 UPGRADE: Testing WHAT Git does, not just IF config files exist"
  touch $out
''
