# Starship Prompt Configuration Test
#
# Tests the Starship prompt configuration in users/shared/starship.nix
# Verifies that the prompt is properly configured with minimal format and required modules.
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ./.,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  constants = import ../lib/constants.nix { inherit pkgs lib; };
  mockConfig = import ../lib/mock-config.nix { inherit pkgs lib; };
  starshipHelpers = import ../lib/starship-test-helpers.nix {
    inherit pkgs lib helpers constants;
  };

  starshipConfig = import ../../users/shared/starship.nix {
    inherit pkgs lib;
    config = mockConfig.mkEmptyConfig;
  };

  requiredModules = ["$directory" "$git_branch" "$git_status" "$python" "$nix_shell"];

in
{
  platforms = ["any"];
  value = helpers.testSuite "starship" ([
    # Core configuration
    (starshipHelpers.assertStarshipEnabled starshipConfig)
    (starshipHelpers.assertStarshipZshIntegration starshipConfig)
    (starshipHelpers.assertStarshipHasSettings starshipConfig)

    # Format validation - use helper to check all required modules at once
  ] ++ starshipHelpers.assertStarshipFormatHasAllModules starshipConfig requiredModules ++ [
    # Right format
    (starshipHelpers.assertStarshipRightFormat starshipConfig "$cmd_duration")

    # Timeout configurations
    (starshipHelpers.assertStarshipCommandTimeout starshipConfig constants.starshipCommandTimeout)
    (starshipHelpers.assertStarshipScanTimeout starshipConfig constants.starshipScanTimeout)
    (starshipHelpers.assertStarshipCmdDurationMinTime starshipConfig constants.starshipCmdDurationMinTime)

    # Disabled modules
    (starshipHelpers.assertStarshipModuleDisabled starshipConfig "username")
    (starshipHelpers.assertStarshipModuleDisabled starshipConfig "hostname")

    # Directory configuration
    (starshipHelpers.assertStarshipDirectoryTruncation starshipConfig constants.starshipDirectoryTruncationLength)

    # Module symbols
    (starshipHelpers.assertStarshipModuleSymbol starshipConfig "git_branch" "")
    (starshipHelpers.assertStarshipModuleSymbol starshipConfig "nix_shell" "nix")

    # Character symbols
    (starshipHelpers.assertStarshipCharacterSymbol starshipConfig "success_symbol" "[➜](bold green)")
    (starshipHelpers.assertStarshipCharacterSymbol starshipConfig "error_symbol" "[➜](bold red)")
  ]);
}
