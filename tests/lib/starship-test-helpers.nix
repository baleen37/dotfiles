# Starship Test Helpers
#
# Provides reusable assertion helpers for testing Starship prompt configuration.
# Reduces duplication across starship-related test files.

{
  pkgs,
  lib,
  helpers,
  constants,
}:

rec {
  # Assert that Starship is enabled
  #
  # Parameters:
  #   config: The starship configuration to test
  #
  # Returns: An assertion that passes if Starship is enabled
  assertStarshipEnabled = config:
    helpers.assertTest "starship-enabled" (
      config.programs.starship.enable == true
    ) "Starship should be enabled";

  # Assert that Starship Zsh integration is enabled
  #
  # Parameters:
  #   config: The starship configuration to test
  #
  # Returns: An assertion that passes if Zsh integration is enabled
  assertStarshipZshIntegration = config:
    helpers.assertTest "starship-zsh-integration" (
      config.programs.starship.enableZshIntegration == true
    ) "Starship should have Zsh integration enabled";

  # Assert that Starship settings are configured
  #
  # Parameters:
  #   config: The starship configuration to test
  #
  # Returns: An assertion that passes if settings exist
  assertStarshipHasSettings = config:
    helpers.assertTest "starship-has-settings" (
      config.programs.starship ? settings
    ) "Starship should have settings configured";

  # Assert that Starship format contains a specific module
  #
  # Parameters:
  #   config: The starship configuration to test
  #   moduleName: The module name to check for (e.g., "$directory", "$git_branch")
  #   testName: Optional custom test name (defaults to "starship-format-has-{module}")
  #
  # Returns: An assertion that passes if the format contains the module
  assertStarshipFormatHasModule = config: moduleName: testName:
    let
      name = if testName == null then "starship-format-has-${lib.removePrefix "$" moduleName}" else testName;
    in
    helpers.assertTest name (
      lib.hasInfix moduleName config.programs.starship.settings.format
    ) "Starship format should include ${moduleName} module";

  # Assert that Starship right format is configured correctly
  #
  # Parameters:
  #   config: The starship configuration to test
  #   expectedFormat: Expected right format (defaults to "$cmd_duration")
  #
  # Returns: An assertion that passes if right format matches
  assertStarshipRightFormat = config: expectedFormat:
    helpers.assertTest "starship-right-format" (
      config.programs.starship.settings.right_format == expectedFormat
    ) "Starship right format should be '${expectedFormat}'";

  # Assert that Starship command timeout is configured
  #
  # Parameters:
  #   config: The starship configuration to test
  #   expectedTimeout: Expected timeout in milliseconds (defaults to constants.starshipCommandTimeout)
  #
  # Returns: An assertion that passes if timeout matches
  assertStarshipCommandTimeout = config: expectedTimeout:
    helpers.assertTest "starship-command-timeout" (
      config.programs.starship.settings.command_timeout == expectedTimeout
    ) "Starship command timeout should be ${toString expectedTimeout}ms";

  # Assert that Starship scan timeout is configured
  #
  # Parameters:
  #   config: The starship configuration to test
  #   expectedTimeout: Expected timeout in seconds (defaults to constants.starshipScanTimeout)
  #
  # Returns: An assertion that passes if scan timeout matches
  assertStarshipScanTimeout = config: expectedTimeout:
    helpers.assertTest "starship-scan-timeout" (
      config.programs.starship.settings.scan_timeout == expectedTimeout
    ) "Starship scan timeout should be ${toString expectedTimeout}";

  # Assert that Starship cmd_duration min_time is configured
  #
  # Parameters:
  #   config: The starship configuration to test
  #   expectedMinTime: Expected min_time in milliseconds (defaults to constants.starshipCmdDurationMinTime)
  #
  # Returns: An assertion that passes if min_time matches
  assertStarshipCmdDurationMinTime = config: expectedMinTime:
    helpers.assertTest "starship-cmd-duration-min-time" (
      config.programs.starship.settings.cmd_duration.min_time == expectedMinTime
    ) "Starship cmd_duration min_time should be ${toString expectedMinTime}ms";

  # Assert that a Starship module is disabled
  #
  # Parameters:
  #   config: The starship configuration to test
  #   moduleName: The module name (e.g., "username", "hostname")
  #
  # Returns: An assertion that passes if the module is disabled
  assertStarshipModuleDisabled = config: moduleName:
    helpers.assertTest "starship-${moduleName}-disabled" (
      config.programs.starship.settings.${moduleName}.disabled == true
    ) "Starship ${moduleName} module should be disabled";

  # Assert that Starship directory truncation is configured
  #
  # Parameters:
  #   config: The starship configuration to test
  #   expectedLength: Expected truncation length (defaults to constants.starshipDirectoryTruncationLength)
  #
  # Returns: An assertion that passes if truncation length matches
  assertStarshipDirectoryTruncation = config: expectedLength:
    helpers.assertTest "starship-directory-truncation" (
      config.programs.starship.settings.directory.truncation_length == expectedLength
    ) "Starship directory truncation_length should be ${toString expectedLength}";

  # Assert that a Starship module symbol is configured
  #
  # Parameters:
  #   config: The starship configuration to test
  #   moduleName: The module name (e.g., "git_branch", "nix_shell")
  #   expectedSymbol: Expected symbol value
  #
  # Returns: An assertion that passes if symbol matches
  assertStarshipModuleSymbol = config: moduleName: expectedSymbol:
    helpers.assertTest "starship-${lib.replaceStrings ["_"] ["-"] moduleName}-symbol" (
      config.programs.starship.settings.${moduleName}.symbol == expectedSymbol
    ) "Starship ${moduleName} symbol should be '${expectedSymbol}'";

  # Assert that Starship character symbol is configured
  #
  # Parameters:
  #   config: The starship configuration to test
  #   symbolType: Either "success_symbol" or "error_symbol"
  #   expectedSymbol: Expected symbol (e.g., "[➜](bold green)")
  #
  # Returns: An assertion that passes if symbol matches
  assertStarshipCharacterSymbol = config: symbolType: expectedSymbol:
    helpers.assertTest "starship-${lib.replaceStrings ["_"] ["-"] symbolType}" (
      config.programs.starship.settings.character.${symbolType} == expectedSymbol
    ) "Starship ${symbolType} should be '${expectedSymbol}'";

  # Comprehensive Starship format validation
  #
  # Parameters:
  #   config: The starship configuration to test
  #   requiredModules: List of required module names (e.g., ["$directory" "$git_branch"])
  #
  # Returns: A list of assertions for all required modules
  assertStarshipFormatHasAllModules = config: requiredModules:
    map (module: assertStarshipFormatHasModule config module null) requiredModules;
}
