# Starship Prompt Configuration Test
#
# Tests the Starship prompt configuration in users/shared/starship.nix
# Verifies that the prompt is properly configured with minimal format and required modules.
# This test ensures consistency across all platforms.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  constants = import ../lib/constants.nix { inherit pkgs lib; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };
  starshipHelpers = import ../lib/starship-test-helpers.nix {
    inherit
      pkgs
      lib
      helpers
      constants
      ;
  };

  starshipModule = import ../../users/shared/programs/starship.nix {
    inherit pkgs lib;
    config = mockConfig.mkEmptyConfig // {
      modules.programs.starship.enable = true;
    };
  };
  starshipConfig = starshipModule.config.content;

  requiredModules = [
    "$username"
    "$directory"
    "$git_branch"
    "$git_status"
    "$python"
  ];

in
{
  platforms = [ "any" ];
  value = helpers.testSuite "starship" (
    [
      # Core configuration
      (starshipHelpers.assertStarshipEnabled starshipConfig)
      (starshipHelpers.assertStarshipZshIntegration starshipConfig)
      (starshipHelpers.assertStarshipHasSettings starshipConfig)

      # Format validation - use helper to check all required modules at once
    ]
    ++ starshipHelpers.assertStarshipFormatHasAllModules starshipConfig requiredModules
    ++ [
      # Right format
      (starshipHelpers.assertStarshipRightFormat starshipConfig "$cmd_duration")

      # Timeout configurations
      (starshipHelpers.assertStarshipCommandTimeout starshipConfig constants.starshipCommandTimeout)
      (starshipHelpers.assertStarshipScanTimeout starshipConfig constants.starshipScanTimeout)
      (starshipHelpers.assertStarshipCmdDurationMinTime starshipConfig constants.starshipCmdDurationMinTime)

      # Username
      (helpers.assertTest "starship-format-starts-with-username"
        (lib.hasPrefix "$username$directory" starshipConfig.programs.starship.settings.format)
        "Starship format should start with the username module"
      )
      (helpers.assertTest "starship-format-excludes-nix-shell" (
        !(lib.hasInfix "$nix_shell" starshipConfig.programs.starship.settings.format)
      ) "Starship format should not include the nix_shell module")
      (helpers.assertTest "starship-username-enabled" (
        (starshipConfig.programs.starship.settings.username.disabled or true) == false
      ) "Starship username module should be enabled")
      (helpers.assertTest "starship-username-always-visible" (
        (starshipConfig.programs.starship.settings.username.show_always or false) == true
      ) "Starship username should always be visible")
      (helpers.assertTest "starship-username-format" (
        (starshipConfig.programs.starship.settings.username.format or "") == "[$user]($style) "
      ) "Starship username should have a compact format")

      # Disabled modules
      (starshipHelpers.assertStarshipModuleDisabled starshipConfig "hostname")

      # Directory configuration
      (starshipHelpers.assertStarshipDirectoryTruncation starshipConfig constants.starshipDirectoryTruncationLength)

      # Module symbols
      (starshipHelpers.assertStarshipModuleSymbol starshipConfig "git_branch" "")

      # Character symbols
      (starshipHelpers.assertStarshipCharacterSymbol starshipConfig "success_symbol" "[➜](bold green)")
      (starshipHelpers.assertStarshipCharacterSymbol starshipConfig "error_symbol" "[➜](bold red)")
    ]
  );
}
