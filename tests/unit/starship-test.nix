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

  starshipConfig = import ../../users/shared/starship.nix {
    inherit pkgs lib;
    config = { };
  };

in
{
  platforms = ["any"];
  value = helpers.testSuite "starship" [
    # Test starship is enabled
    (helpers.assertTest "starship-enabled" (
      starshipConfig.programs.starship.enable == true
    ) "Starship should be enabled")

    # Test zsh integration is enabled
    (helpers.assertTest "starship-zsh-integration" (
      starshipConfig.programs.starship.enableZshIntegration == true
    ) "Starship should have Zsh integration enabled")

    # Test basic settings exist
    (helpers.assertTest "starship-has-settings" (
      starshipConfig.programs.starship ? settings
    ) "Starship should have settings configured")

    # Test format contains directory module
    (helpers.assertTest "starship-format-has-directory" (
      lib.hasInfix "$directory" starshipConfig.programs.starship.settings.format
    ) "Starship format should include directory module")

    # Test format contains git_branch module
    (helpers.assertTest "starship-format-has-git-branch" (
      lib.hasInfix "$git_branch" starshipConfig.programs.starship.settings.format
    ) "Starship format should include git_branch module")

    # Test format contains git_status module
    (helpers.assertTest "starship-format-has-git-status" (
      lib.hasInfix "$git_status" starshipConfig.programs.starship.settings.format
    ) "Starship format should include git_status module")

    # Test format contains python module
    (helpers.assertTest "starship-format-has-python" (
      lib.hasInfix "$python" starshipConfig.programs.starship.settings.format
    ) "Starship format should include python module")

    # Test format contains nix_shell module
    (helpers.assertTest "starship-format-has-nix-shell" (
      lib.hasInfix "$nix_shell" starshipConfig.programs.starship.settings.format
    ) "Starship format should include nix_shell module")

    # Test right prompt has cmd_duration
    (helpers.assertTest "starship-right-format-has-cmd-duration" (
      starshipConfig.programs.starship.settings.right_format == "$cmd_duration"
    ) "Starship right format should only have cmd_duration")

    # Test command timeout is configured
    (helpers.assertTest "starship-command-timeout" (
      starshipConfig.programs.starship.settings.command_timeout == 1000
    ) "Starship command timeout should be 1000ms")

    # Test scan timeout is configured
    (helpers.assertTest "starship-scan-timeout" (
      starshipConfig.programs.starship.settings.scan_timeout == 30
    ) "Starship scan timeout should be 30")

    # Test cmd_duration min_time is 3000ms
    (helpers.assertTest "starship-cmd-duration-min-time" (
      starshipConfig.programs.starship.settings.cmd_duration.min_time == 3000
    ) "Starship cmd_duration min_time should be 3000ms")

    # Test username module is disabled
    (helpers.assertTest "starship-username-disabled" (
      starshipConfig.programs.starship.settings.username.disabled == true
    ) "Starship username module should be disabled")

    # Test hostname module is disabled
    (helpers.assertTest "starship-hostname-disabled" (
      starshipConfig.programs.starship.settings.hostname.disabled == true
    ) "Starship hostname module should be disabled")

    # Test directory truncation_length is configured
    (helpers.assertTest "starship-directory-truncation" (
      starshipConfig.programs.starship.settings.directory.truncation_length == 3
    ) "Starship directory truncation_length should be 3")

    # Test git_branch symbol is empty (minimal)
    (helpers.assertTest "starship-git-branch-symbol" (
      starshipConfig.programs.starship.settings.git_branch.symbol == ""
    ) "Starship git_branch symbol should be empty for minimal prompt")

    # Test nix_shell symbol is "nix"
    (helpers.assertTest "starship-nix-shell-symbol" (
      starshipConfig.programs.starship.settings.nix_shell.symbol == "nix"
    ) "Starship nix_shell symbol should be 'nix'")

    # Test character success_symbol
    (helpers.assertTest "starship-success-symbol" (
      starshipConfig.programs.starship.settings.character.success_symbol == "[➜](bold green)"
    ) "Starship success_symbol should be '➜' in bold green")

    # Test character error_symbol
    (helpers.assertTest "starship-error-symbol" (
      starshipConfig.programs.starship.settings.character.error_symbol == "[➜](bold red)"
    ) "Starship error_symbol should be '➜' in bold red")
  ];
}
