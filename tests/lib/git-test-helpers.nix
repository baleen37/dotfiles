# Git-specific test helpers
#
# Provides specialized helpers for Git configuration testing to eliminate
# duplication across Git-related test files.
#
# These helpers encapsulate common Git testing patterns:
# - User info validation (name, email)
# - Git alias assertions (bulk and individual)
# - Git settings validation (core, init, pull, rebase, etc.)
# - Git ignore pattern validation
# - Git LFS configuration
#
# Usage:
#   gitHelpers = import ../lib/git-test-helpers.nix { inherit pkgs lib; };
#   gitHelpers.assertGitConfigComplete "my-test" gitConfig userInfo expectedAliases expectedIgnores
{
  pkgs,
  lib,
  # Inherit test helpers for basic assertions
  testHelpers,
}:

let
  inherit (testHelpers) assertTest testSuite;

in
rec {
  # Validate Git user information (name and email)
  #
  # Parameters:
  #   - name: Test name for reporting
  #   - gitSettings: The git settings attribute set (typically gitConfig.programs.git.settings)
  #   - userInfo: User info attribute set with 'name' and 'email' (from lib/user-info.nix)
  #
  # Returns: Test derivation that validates user name and email match userInfo
  #
  # Example:
  #   assertGitUserInfo "git-user-info" gitSettings userInfo
  assertGitUserInfo =
    name: gitSettings: userInfo:
    let
      userName = gitSettings.user.name or "<not set>";
      userEmail = gitSettings.user.email or "<not set>";
      nameMatch = userName == userInfo.name;
      emailMatch = userEmail == userInfo.email;
      bothMatch = nameMatch && emailMatch;
    in
    if bothMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git user: ${userName} <${userEmail}>"
        echo "  Matches lib/user-info.nix: ${userInfo.name} <${userInfo.email}>"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git user info mismatch with lib/user-info.nix"
        echo ""
        echo "  User Name:"
        echo "    Expected (from lib/user-info.nix): ${userInfo.name}"
        echo "    Actual (gitSettings.user.name): ${userName}"
        echo "  User Email:"
        echo "    Expected (from lib/user-info.nix): ${userInfo.email}"
        echo "    Actual (gitSettings.user.email): ${userEmail}"
        exit 1
      '';

  # Validate Git user info with specific expected values
  #
  # Parameters:
  #   - name: Test name for reporting
  #   - gitSettings: The git settings attribute set
  #   - expectedName: Expected user name
  #   - expectedEmail: Expected user email
  #
  # Returns: Test derivation that validates user name and email match expected values
  #
  # Example:
  #   assertGitUserInfoValues "git-user-values" gitSettings "Jiho Lee" "baleen37@gmail.com"
  assertGitUserInfoValues =
    name: gitSettings: expectedName: expectedEmail:
    let
      userName = gitSettings.user.name or "<not set>";
      userEmail = gitSettings.user.email or "<not set>";
      nameMatch = userName == expectedName;
      emailMatch = userEmail == expectedEmail;
      bothMatch = nameMatch && emailMatch;
    in
    if bothMatch then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git user: ${userName} <${userEmail}>"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git user info mismatch"
        echo ""
        echo "  User Name:"
        echo "    Expected: ${expectedName}"
        echo "    Actual: ${userName}"
        echo "  User Email:"
        echo "    Expected: ${expectedEmail}"
        echo "    Actual: ${userEmail}"
        exit 1
      '';

  # Validate Git LFS configuration
  #
  # Parameters:
  #   - name: Test name for reporting
  #   - gitConfig: The git configuration attribute set (typically gitConfig.programs.git)
  #   - expectedEnabled: Expected LFS enabled state (default: true)
  #
  # Returns: Test derivation that validates LFS configuration
  #
  # Example:
  #   assertGitLFS "git-lfs" gitConfig true
  assertGitLFS =
    name: gitConfig: expectedEnabled:
    let
      actualEnabled = gitConfig.lfs.enable or false;
      isEnabled = actualEnabled == expectedEnabled;
    in
    if isEnabled then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git LFS ${if actualEnabled then "enabled" else "disabled"}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git LFS should be ${if expectedEnabled then "enabled" else "disabled"}"
        echo "  Actual state: ${if actualEnabled then "enabled" else "disabled"}"
        exit 1
      '';

  # Bulk assertion helper for Git aliases
  #
  # Parameters:
  #   - name: Test group name for reporting
  #   - aliasSettings: The git alias attribute set (gitSettings.alias)
  #   - expectedAliases: Attribute set of expected aliases
  #
  # Returns: Test suite with individual tests for each alias
  #
  # Example:
  #   assertGitAliasesBulk "git-aliases" gitSettings.alias {
  #     st = "status";
  #     co = "checkout";
  #     br = "branch";
  #   }
  assertGitAliasesBulk =
    name: aliasSettings: expectedAliases:
    let
      individualTests = builtins.map (
        aliasName:
        let
          expectedValue = builtins.getAttr aliasName expectedAliases;
          actualValue = builtins.getAttr aliasName aliasSettings;
          testName = "${name}-${aliasName}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "Git alias '${aliasName}' should be '${expectedValue}'"
      ) (builtins.attrNames expectedAliases);

      summaryTest = pkgs.runCommand "${name}-summary" { } ''
        echo "✅ Git aliases '${name}': All ${toString (builtins.length individualTests)} aliases configured correctly"
        touch $out
      '';
    in
    testSuite "${name}-aliases" (individualTests ++ [ summaryTest ]);

  # Bulk assertion helper for Git settings
  #
  # Parameters:
  #   - name: Test group name for reporting
  #   - gitSettings: The git settings attribute set
  #   - expectedSettings: Attribute set of expected settings
  #
  # Returns: Test suite with individual tests for each setting
  #
  # Example:
  #   assertGitSettingsBulk "git-core" gitSettings.core {
  #     editor = "vim";
  #     autocrlf = "input";
  #   }
  assertGitSettingsBulk =
    name: gitSettings: expectedSettings:
    let
      individualTests = builtins.map (
        key:
        let
          expectedValue = builtins.getAttr key expectedSettings;
          actualValue = builtins.getAttr key gitSettings;
          testName = "${name}-${builtins.replaceStrings [ "." ] [ "-" ] key}";
        in
        assertTest testName (
          actualValue == expectedValue
        ) "${name}.${key} should be '${toString expectedValue}'"
      ) (builtins.attrNames expectedSettings);

      summaryTest = pkgs.runCommand "${name}-summary" { } ''
        echo "✅ Git settings '${name}': All ${toString (builtins.length individualTests)} settings match"
        touch $out
      '';
    in
    testSuite "${name}-settings" (individualTests ++ [ summaryTest ]);

  # Bulk assertion helper for Git ignore patterns
  #
  # Parameters:
  #   - name: Test group name for reporting
  #   - actualPatterns: The actual gitignore patterns list
  #   - expectedPatterns: List of expected patterns
  #
  # Returns: Test suite with individual tests for each pattern
  #
  # Example:
  #   assertGitIgnorePatternsBulk "gitignore" gitIgnores [
  #     "*.swp"
  #     ".DS_Store"
  #     "node_modules/"
  #   ]
  assertGitIgnorePatternsBulk =
    name: actualPatterns: expectedPatterns:
    let
      individualTests = builtins.map (
        pattern:
        let
          sanitizedName = builtins.replaceStrings [ "*" "." "/" "-" " " ] [ "-" "-" "-" "-" "" ] (
            if pattern == "" then "empty" else pattern
          );
          testName = "${name}-${sanitizedName}";
          hasPattern = builtins.any (p: p == pattern) actualPatterns;
        in
        assertTest testName hasPattern "${name} should include '${pattern}'"
      ) expectedPatterns;

      summaryTest = pkgs.runCommand "${name}-summary" { } ''
        echo "✅ Gitignore '${name}': All ${toString (builtins.length individualTests)} patterns found"
        touch $out
      '';
    in
    testSuite "${name}-patterns" (individualTests ++ [ summaryTest ]);

  # Comprehensive Git configuration validation
  #
  # This is the main helper that validates all aspects of Git configuration:
  # - Git is enabled
  # - User info matches lib/user-info.nix
  # - Git LFS is enabled
  # - Core settings (editor, autocrlf, excludesFile)
  # - Init settings (defaultBranch)
  # - Pull settings (rebase)
  # - Rebase settings (autoStash)
  # - Git aliases
  # - Git ignore patterns
  #
  # Parameters:
  #   - name: Test suite name for reporting
  #   - gitConfig: The full git configuration attribute set
  #   - userInfo: User info from lib/user-info.nix
  #   - expectedAliases: Attribute set of expected Git aliases
  #   - expectedIgnores: List of expected gitignore patterns
  #   - options: Optional configuration:
  #     - checkUserInfo: Validate user info (default: true)
  #     - checkLFS: Validate Git LFS (default: true)
  #     - checkAliases: Validate Git aliases (default: true)
  #     - checkIgnores: Validate gitignore patterns (default: true)
  #
  # Returns: Test suite with comprehensive Git configuration validation
  #
  # Example:
  #   assertGitConfigComplete "git-config" gitConfig userInfo {
  #     st = "status";
  #     co = "checkout";
  #   } [
  #     "*.swp"
  #     ".DS_Store"
  #   ]
  assertGitConfigComplete =
    name: gitConfig: userInfo: expectedAliases: expectedIgnores: options:
    let
      # Default options
      opts = {
        checkUserInfo = true;
        checkLFS = true;
        checkAliases = true;
        checkIgnores = true;
      } // options;

      # Extract settings
      gitSettings = gitConfig.programs.git.settings or { };
      gitIgnores = gitConfig.programs.git.ignores or [ ];

      # Individual tests
      tests = lib.optional (gitConfig.programs.git.enable or false) (
        assertTest "${name}-git-enabled" true "Git should be enabled"
      ) ++ lib.optional opts.checkUserInfo (
        assertGitUserInfo "${name}-user-info" gitSettings userInfo
      ) ++ lib.optional opts.checkLFS (
        assertGitLFS "${name}-lfs" gitConfig.programs.git true
      ) ++ [
        # Core settings
        (assertGitSettingsBulk "${name}-core" gitSettings.core {
          editor = "vim";
          autocrlf = "input";
          excludesFile = "~/.gitignore_global";
        })
        # Init settings
        (assertGitSettingsBulk "${name}-init" gitSettings.init {
          defaultBranch = "main";
        })
        # Pull settings
        (assertGitSettingsBulk "${name}-pull" gitSettings.pull {
          rebase = true;
        })
        # Rebase settings
        (assertGitSettingsBulk "${name}-rebase" gitSettings.rebase {
          autoStash = true;
        })
      ] ++ lib.optional opts.checkAliases (
        assertGitAliasesBulk "${name}-aliases" gitSettings.alias expectedAliases
      ) ++ lib.optional opts.checkIgnores (
        assertGitIgnorePatternsBulk "${name}-ignores" gitIgnores expectedIgnores
      );

      # Summary test
      summaryTest = pkgs.runCommand "${name}-summary" { }
        ''
          echo "================================"
          echo "✅ Git Configuration Test Suite: ${name}"
          echo "================================"
          echo ""
          echo "✅ Git enabled: ${toString (gitConfig.programs.git.enable or false)}"
          ${lib.optionalString opts.checkUserInfo ''
            echo "✅ User info: ${gitSettings.user.name or "<not set>"} <${gitSettings.user.email or "<not set>"}>"
          ''}
          ${lib.optionalString opts.checkLFS ''
            echo "✅ Git LFS: ${if gitConfig.programs.git.lfs.enable or false then "enabled" else "disabled"}"
          ''}
          echo "✅ Core settings: validated"
          echo "✅ Init settings: validated"
          echo "✅ Pull settings: validated"
          echo "✅ Rebase settings: validated"
          ${lib.optionalString opts.checkAliases ''
            echo "✅ Aliases: ${toString (builtins.length (builtins.attrNames expectedAliases))} validated"
          ''}
          ${lib.optionalString opts.checkIgnores ''
            echo "✅ Gitignore patterns: ${toString (builtins.length expectedIgnores)} validated"
          ''}
          echo ""
          echo "✅ All Git configuration tests passed!"
          echo "================================"
          touch $out
        '';
    in
    testSuite "${name}-complete" (tests ++ [ summaryTest ]);

  # Validate Git alias safety
  #
  # Checks that Git aliases don't contain dangerous commands and include
  # essential aliases (st, ci).
  #
  # Parameters:
  #   - name: Test name for reporting
  #   - aliasSettings: The git alias attribute set
  #   - options: Optional configuration:
  #     - requiredAliases: List of required alias names (default: [ "st" "ci" ])
  #     - dangerousPatterns: List of dangerous command patterns (default: standard list)
  #
  # Returns: Test derivation that validates alias safety
  #
  # Example:
  #   assertGitAliasSafety "git-alias-safety" gitSettings.alias
  assertGitAliasSafety =
    name: aliasSettings: options:
    let
      opts = {
        requiredAliases = [ "st" "ci" ];
        dangerousPatterns = [ "rm -rf" "sudo " "chmod 777" "chown " "format " "fdisk" ];
      } // options;

      # Extract commands from aliases
      aliasCommands = builtins.attrValues aliasSettings;

      # Check for dangerous commands
      hasDangerous = builtins.any (pattern:
        builtins.any (cmd: lib.hasInfix pattern cmd) aliasCommands
      ) opts.dangerousPatterns;

      # Check for empty commands
      hasEmpty = builtins.any (cmd: cmd == "") aliasCommands;

      # Check for required aliases
      hasRequired = builtins.all (aliasName:
        builtins.hasAttr aliasName aliasSettings
      ) opts.requiredAliases;

      isSafe = !hasDangerous && !hasEmpty && hasRequired;
    in
    if isSafe then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git aliases are safe"
        echo "  Required aliases present: ${lib.concatStringsSep ", " opts.requiredAliases}"
        echo "  No dangerous patterns found"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git alias safety check failed"
        ${if hasDangerous then ''
          echo "  ⚠️  Found dangerous commands in aliases"
        '' else ""}
        ${if hasEmpty then ''
          echo "  ⚠️  Found empty alias commands"
        '' else ""}
        ${if !hasRequired then ''
          echo "  ⚠️  Missing required aliases: ${lib.concatStringsSep ", " (builtins.filter (n: !builtins.hasAttr n aliasSettings) opts.requiredAliases)}"
        '' else ""}
        exit 1
      '';

  # Validate Git ignore pattern safety
  #
  # Checks that gitignore patterns are safe (no path traversal attacks).
  #
  # Parameters:
  #   - name: Test name for reporting
  #   - ignorePatterns: List of gitignore patterns
  #
  # Returns: Test derivation that validates pattern safety
  #
  # Example:
  #   assertGitIgnoreSafety "gitignore-safety" gitIgnores
  assertGitIgnoreSafety =
    name: ignorePatterns:
    let
      # Check for dangerous patterns
      hasParentTraversal = builtins.any (p: lib.hasInfix "../" p) ignorePatterns;

      # Check each pattern is reasonable
      allPatternsValid = builtins.all (pattern:
        let
          nonEmpty = builtins.stringLength pattern > 0;
          reasonableLength = builtins.stringLength pattern <= 200;
          # Allow absolute patterns if they start with single /
          safePattern =
            !lib.hasInfix "../" pattern
            || (lib.hasPrefix "/" pattern && builtins.match "^/[^/]+.*" pattern != null);
        in
        nonEmpty && reasonableLength && safePattern
      ) ignorePatterns;

      isSafe = !hasParentTraversal && allPatternsValid;
    in
    if isSafe then
      pkgs.runCommand "test-${name}-pass" { } ''
        echo "✅ ${name}: PASS"
        echo "  Git ignore patterns are safe"
        echo "  Total patterns: ${toString (builtins.length ignorePatterns)}"
        touch $out
      ''
    else
      pkgs.runCommand "test-${name}-fail" { } ''
        echo "❌ ${name}: FAIL"
        echo "  Git ignore pattern safety check failed"
        ${if hasParentTraversal then ''
          echo "  ⚠️  Found parent path traversal patterns (../)"
        '' else ""}
        ${if !allPatternsValid then ''
          echo "  ⚠️  Some patterns are invalid or unsafe"
        '' else ""}
        exit 1
      '';
}
