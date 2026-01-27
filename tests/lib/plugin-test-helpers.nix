# Plugin Test Helpers
#
# Reusable helper functions for testing plugin configurations and settings.
# Designed to eliminate code duplication across plugin-based test files.
#
# Usage:
#   let
#     helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
#     pluginHelpers = import ../lib/plugin-test-helpers.nix { inherit pkgs lib; };
#   in
#   # Use pluginHelpers.hasPluginByName, pluginHelpers.hasConfigPattern, etc.
{
  pkgs,
  lib,
  helpers ? import ./test-helpers.nix { inherit pkgs lib; },
}:

rec {
  # Check if a plugin exists by exact name in a plugin list
  #
  # Parameters:
  #   - plugins: List of plugins (each plugin should have a 'pname' attribute)
  #   - pname: Exact plugin name to search for
  #
  # Returns:
  #   - true if plugin found, false otherwise
  #
  # Example:
  #   hasPluginByName vimConfig.programs.vim.plugins "vim-airline"
  hasPluginByName =
    plugins: pname:
    builtins.any (plugin: plugin.pname or null == pname) plugins;

  # Check if a plugin exists by regex pattern
  #
  # Parameters:
  #   - plugins: List of plugins (each plugin should have a 'pname' attribute)
  #   - pattern: Regex pattern to match against plugin names
  #
  # Returns:
  #   - true if plugin pattern matches, false otherwise
  #
  # Example:
  #   hasPluginByPattern vimConfig.programs.vim.plugins ".*airline.*"
  hasPluginByPattern =
    plugins: pattern:
    builtins.any (plugin: builtins.match pattern (plugin.pname or "") != null) plugins;

  # Check if configuration contains a regex pattern
  #
  # Parameters:
  #   - config: Configuration string to search in
  #   - pattern: Regex pattern to match
  #
  # Returns:
  #   - true if pattern matches, false otherwise
  #
  # Example:
  #   hasConfigPattern vimConfig.programs.vim.extraConfig ".*set relativenumber.*"
  hasConfigPattern =
    config: pattern:
    builtins.match pattern config != null;

  # Check if configuration contains a substring
  #
  # Parameters:
  #   - config: Configuration string to search in
  #   - str: Substring to search for
  #
  # Returns:
  #   - true if substring found, false otherwise
  #
  # Example:
  #   hasConfigString tmuxConfig.extraConfig "setw -g mode-keys vi"
  hasConfigString =
    config: str:
    lib.hasInfix str config;

  # Check if all configuration patterns are present
  #
  # Parameters:
  #   - config: Configuration string to search in
  #   - patterns: List of regex patterns to match
  #
  # Returns:
  #   - true if all patterns match, false otherwise
  #
  # Example:
  #   hasAllConfigPatterns vimConfig.programs.vim.extraConfig [
  #     ".*set relativenumber.*"
  #     ".*set number.*"
  #   ]
  hasAllConfigPatterns =
    config: patterns:
    builtins.all (pattern: hasConfigPattern config pattern) patterns;

  # Check if all configuration strings are present
  #
  # Parameters:
  #   - config: Configuration string to search in
  #   - strings: List of substrings to search for
  #
  # Returns:
  #   - true if all substrings found, false otherwise
  #
  # Example:
  #   hasAllConfigStrings tmuxConfig.extraConfig [
  #     "setw -g mode-keys vi"
  #     "bind [ copy-mode"
  #   ]
  hasAllConfigStrings =
    config: strings:
    builtins.all (str: hasConfigString config str) strings;

  # Create a test assertion for plugin presence by name
  #
  # Parameters:
  #   - testName: Name for the test
  #   - plugins: List of plugins to search in
  #   - pname: Exact plugin name to search for
  #   - message: Optional failure message (default: auto-generated)
  #
  # Returns:
  #   - Test derivation using helpers.assertTest
  #
  # Example:
  #   assertPluginByName "vim-airline" vimConfig.programs.vim.plugins "vim-airline"
  assertPluginByName =
    testName: plugins: pname: message:
    let
      msg = if message == null then "Plugin '${pname}' should be present" else message;
    in
    helpers.assertTest testName (
      hasPluginByName plugins pname
    ) msg;

  # Create a test assertion for plugin presence by pattern
  #
  # Parameters:
  #   - testName: Name for the test
  #   - plugins: List of plugins to search in
  #   - pattern: Regex pattern to match
  #   - message: Optional failure message (default: auto-generated)
  #
  # Returns:
  #   - Test derivation using helpers.assertTest
  #
  # Example:
  #   assertPluginByPattern "tmux-navigator" tmuxConfig.plugins ".*navigator.*"
  assertPluginByPattern =
    testName: plugins: pattern: message:
    let
      msg = if message == null then "Plugin matching pattern '${pattern}' should be present" else message;
    in
    helpers.assertTest testName (
      hasPluginByPattern plugins pattern
    ) msg;

  # Create a test assertion for configuration pattern
  #
  # Parameters:
  #   - testName: Name for the test
  #   - config: Configuration string to search in
  #   - pattern: Regex pattern to match
  #   - message: Optional failure message (default: auto-generated)
  #
  # Returns:
  #   - Test derivation using helpers.assertTest
  #
  # Example:
  #   assertConfigPattern "vim-relative-numbers" vimConfig.programs.vim.extraConfig ".*set relativenumber.*"
  assertConfigPattern =
    testName: config: pattern: message:
    let
      msg = if message == null then "Configuration should contain pattern '${pattern}'" else message;
    in
    helpers.assertTest testName (
      hasConfigPattern config pattern
    ) msg;

  # Create a test assertion for configuration string
  #
  # Parameters:
  #   - testName: Name for the test
  #   - config: Configuration string to search in
  #   - str: Substring to search for
  #   - message: Optional failure message (default: auto-generated)
  #
  # Returns:
  #   - Test derivation using helpers.assertTest
  #
  # Example:
  #   assertConfigString "tmux-vi-mode" tmuxConfig.extraConfig "setw -g mode-keys vi"
  assertConfigString =
    testName: config: str: message:
    let
      msg = if message == null then "Configuration should contain string '${str}'" else message;
    in
    helpers.assertTest testName (
      hasConfigString config str
    ) msg;

  # Validate a list of plugins are all present
  #
  # Parameters:
  #   - testName: Name for the test suite
  #   - plugins: List of plugins to search in
  #   - expectedPlugins: List of expected plugin names
  #
  # Returns:
  #   - Test suite with individual assertions for each plugin
  #
  # Example:
  #   assertPluginList "vim-core-plugins" vimConfig.programs.vim.plugins [
  #     "vim-airline"
  #     "vim-airline-themes"
  #     "vim-tmux-navigator"
  #   ]
  assertPluginList =
    testName: plugins: expectedPlugins:
    let
      # Create individual tests for each plugin
      individualTests = builtins.map (
        pname: assertPluginByName "${testName}-${pname}" plugins pname
      ) expectedPlugins;

      # Summary test
      summaryTest = pkgs.runCommand "${testName}-summary" { } ''
        echo "✅ Plugin list '${testName}': All ${toString (builtins.length expectedPlugins)} plugins present"
        touch $out
      '';
    in
    helpers.testSuite "${testName}-plugin-list" (individualTests ++ [ summaryTest ]);

  # Validate plugin settings match expected values
  #
  # Parameters:
  #   - testName: Name for the test suite
  #   - pluginConfig: Plugin configuration attribute set
  #   - expectedSettings: Attribute set of expected settings
  #
  # Returns:
  #   - Test suite with individual assertions for each setting
  #
  # Example:
  #   assertPluginSettings "tmux-resurrect" resurrectConfig {
  #     capturePaneContents = "yes";
  #     strategyVim = "vim";
  #   }
  assertPluginSettings =
    testName: pluginConfig: expectedSettings:
    let
      # Create individual tests for each setting
      individualTests = builtins.map (
        key:
        let
          expectedValue = builtins.getAttr key expectedSettings;
          actualValue = builtins.getAttr key pluginConfig;
          testName = "${testName}-${key}";
        in
        helpers.assertTest testName (
          actualValue == expectedValue
        ) "Plugin setting '${key}' should be '${toString expectedValue}'"
      ) (builtins.attrNames expectedSettings);

      # Summary test
      summaryTest = pkgs.runCommand "${testName}-settings-summary" { } ''
        echo "✅ Plugin settings '${testName}': All ${toString (builtins.length individualTests)} settings match"
        touch $out
      '';
    in
    helpers.testSuite "${testName}-settings" (individualTests ++ [ summaryTest ]);

  # Create a test for plugin presence with negation (plugin should NOT be present)
  #
  # Parameters:
  #   - testName: Name for the test
  #   - plugins: List of plugins to search in
  #   - pname: Plugin name that should NOT be present
  #   - message: Optional failure message (default: auto-generated)
  #
  # Returns:
  #   - Test derivation using helpers.assertTest
  #
  # Example:
  #   assertPluginNotPresent "tmux-yank" tmuxConfig.plugins "tmux-yank"
  assertPluginNotPresent =
    testName: plugins: pname: message:
    let
      msg = if message == null then "Plugin '${pname}' should NOT be present" else message;
    in
    helpers.assertTest testName (
      !(hasPluginByName plugins pname)
    ) msg;

  # Create a configuration test helper that makes testing config patterns easier
  #
  # Parameters:
  #   - namePrefix: Prefix for test names
  #   - config: Configuration string to search in
  #
  # Returns:
  #   - Attribute set with test creation functions
  #
  # Example:
  #   let
  #     vimConfigTests = mkConfigTester "vim" vimConfig.programs.vim.extraConfig;
  #   in
  #   [
  #     (vimConfigTests.hasPattern "relative-numbers" ".*set relativenumber.*")
  #     (vimConfigTests.hasString "leader-key" "let mapleader")
  #   ]
  mkConfigTester =
    namePrefix: config:
    {
      hasPattern =
        testName: pattern:
        assertConfigPattern "${namePrefix}-${testName}" config pattern;

      hasString =
        testName: str:
        assertConfigString "${namePrefix}-${testName}" config str;

      hasAllPatterns =
        testName: patterns:
        helpers.assertTest "${namePrefix}-${testName}" (
          hasAllConfigPatterns config patterns
        ) "Configuration should contain all patterns";

      hasAllStrings =
        testName: strings:
        helpers.assertTest "${namePrefix}-${testName}" (
          hasAllConfigStrings config strings
        ) "Configuration should contain all strings";
    };

  # Create a plugin test helper that makes testing plugins easier
  #
  # Parameters:
  #   - namePrefix: Prefix for test names
  #   - plugins: List of plugins to test
  #
  # Returns:
  #   - Attribute set with test creation functions
  #
  # Example:
  #   let
  #     vimPluginTests = mkPluginTester "vim" vimConfig.programs.vim.plugins;
  #   in
  #   [
  #     (vimPluginTests.hasPlugin "airline" "vim-airline")
  #     (vimPluginTests.hasPluginPattern "themes" ".*theme.*")
  #   ]
  mkPluginTester =
    namePrefix: plugins:
    {
      hasPlugin =
        pname: assertPluginByName "${namePrefix}-${pname}" plugins pname;

      hasPluginPattern =
        pattern: assertPluginByPattern "${namePrefix}-pattern-${pattern}" plugins pattern;

      notPresent =
        pname: assertPluginNotPresent "${namePrefix}-no-${pname}" plugins pname;
    };
}
