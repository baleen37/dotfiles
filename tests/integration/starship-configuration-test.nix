# Starship Configuration Integration Test
#
# Tests the Starship prompt configuration in users/shared/starship.nix
# Verifies minimal format, required modules, and disabled modules.
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  ...
} @ args:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Import starship configuration
  starshipConfig = import ../../users/shared/starship.nix {
    inherit pkgs lib;
    config = { };
  };

  # Extract starship settings
  starshipSettings = starshipConfig.programs.starship.settings;

  # Test helper to check if module is disabled
  isModuleDisabled = moduleName:
    starshipSettings.${moduleName}.disabled or false == true;

  # Test helper to check if format contains module
  formatContains = module:
    lib.hasInfix ("${" + module + "}") starshipSettings.format;

in
helpers.testSuite "starship-configuration" [
  # Test starship is enabled
  (helpers.assertTest "starship-enabled" (
    starshipConfig.programs.starship.enable == true
  ) "Starship should be enabled")

  # Test zsh integration is enabled
  (helpers.assertTest "starship-zsh-integration" (
    starshipConfig.programs.starship.enableZshIntegration == true
  ) "Starship should have Zsh integration enabled")

  # Test add_newline is configured
  (helpers.assertTest "starship-add-newline" (
    starshipSettings.add_newline == true
  ) "Starship should add newline between prompts")

  # Test command_timeout is configured
  (helpers.assertTest "starship-command-timeout" (
    starshipSettings.command_timeout == 1000
  ) "Starship command timeout should be 1000ms")

  # Test scan_timeout is configured
  (helpers.assertTest "starship-scan-timeout" (
    starshipSettings.scan_timeout == 30
  ) "Starship scan timeout should be 30")

  # Test format contains directory module
  (helpers.assertTest "starship-format-has-directory" (
    formatContains "directory"
  ) "Starship format should include directory module")

  # Test format contains git_branch module
  (helpers.assertTest "starship-format-has-git-branch" (
    formatContains "git_branch"
  ) "Starship format should include git_branch module")

  # Test format contains git_status module
  (helpers.assertTest "starship-format-has-git-status" (
    formatContains "git_status"
  ) "Starship format should include git_status module")

  # Test format contains python module
  (helpers.assertTest "starship-format-has-python" (
    formatContains "python"
  ) "Starship format should include python module")

  # Test format contains nix_shell module
  (helpers.assertTest "starship-format-has-nix-shell" (
    formatContains "nix_shell"
  ) "Starship format should include nix_shell module")

  # Test format contains character module
  (helpers.assertTest "starship-format-has-character" (
    formatContains "character"
  ) "Starship format should include character module")

  # Test right prompt has cmd_duration
  (helpers.assertTest "starship-right-format-has-cmd-duration" (
    starshipSettings.right_format == "$cmd_duration"
  ) "Starship right format should only have cmd_duration")

  # Test directory module configuration
  (helpers.assertTest "starship-directory-truncation-length" (
    starshipSettings.directory.truncation_length == 3
  ) "Starship directory truncation_length should be 3")

  # Test directory truncate_to_repo is disabled
  (helpers.assertTest "starship-directory-truncate-to-repo" (
    starshipSettings.directory.truncate_to_repo == false
  ) "Starship directory should not truncate to repo")

  # Test directory style is cyan
  (helpers.assertTest "starship-directory-style" (
    starshipSettings.directory.style == "cyan"
  ) "Starship directory style should be cyan")

  # Test git_branch symbol is empty (minimal)
  (helpers.assertTest "starship-git-branch-symbol" (
    starshipSettings.git_branch.symbol == ""
  ) "Starship git_branch symbol should be empty for minimal prompt")

  # Test git_branch style is bold purple
  (helpers.assertTest "starship-git-branch-style" (
    starshipSettings.git_branch.style == "bold purple"
  ) "Starship git_branch style should be bold purple")

  # Test git_status style is bold yellow
  (helpers.assertTest "starship-git-status-style" (
    starshipSettings.git_status.style == "bold yellow"
  ) "Starship git_status style should be bold yellow")

  # Test cmd_duration min_time is 3000ms
  (helpers.assertTest "starship-cmd-duration-min-time" (
    starshipSettings.cmd_duration.min_time == 3000
  ) "Starship cmd_duration min_time should be 3000ms")

  # Test cmd_duration style is bold yellow
  (helpers.assertTest "starship-cmd-duration-style" (
    starshipSettings.cmd_duration.style == "bold yellow"
  ) "Starship cmd_duration style should be bold yellow")

  # Test python symbol is space
  (helpers.assertTest "starship-python-symbol" (
    starshipSettings.python.symbol == " "
  ) "Starship python symbol should be space")

  # Test python style is yellow
  (helpers.assertTest "starship-python-style" (
    starshipSettings.python.style == "yellow"
  ) "Starship python style should be yellow")

  # Test python detect_extensions is empty
  (helpers.assertTest "starship-python-detect-extensions-empty" (
    starshipSettings.python.detect_extensions == [ ]
  ) "Starship python detect_extensions should be empty")

  # Test python detect_files is empty
  (helpers.assertTest "starship-python-detect-files-empty" (
    starshipSettings.python.detect_files == [ ]
  ) "Starship python detect_files should be empty")

  # Test python detect_folders is empty
  (helpers.assertTest "starship-python-detect-folders-empty" (
    starshipSettings.python.detect_folders == [ ]
  ) "Starship python detect_folders should be empty")

  # Test nix_shell symbol is "nix"
  (helpers.assertTest "starship-nix-shell-symbol" (
    starshipSettings.nix_shell.symbol == "nix"
  ) "Starship nix_shell symbol should be 'nix'")

  # Test nix_shell style is bold blue
  (helpers.assertTest "starship-nix-shell-style" (
    starshipSettings.nix_shell.style == "bold blue"
  ) "Starship nix_shell style should be bold blue")

  # Test character success_symbol
  (helpers.assertTest "starship-success-symbol" (
    starshipSettings.character.success_symbol == "[➜](bold green)"
  ) "Starship success_symbol should be '➜' in bold green")

  # Test character error_symbol
  (helpers.assertTest "starship-error-symbol" (
    starshipSettings.character.error_symbol == "[➜](bold red)"
  ) "Starship error_symbol should be '➜' in bold red")

  # Test username module is disabled
  (helpers.assertTest "starship-username-disabled" (
    isModuleDisabled "username"
  ) "Starship username module should be disabled")

  # Test hostname module is disabled
  (helpers.assertTest "starship-hostname-disabled" (
    isModuleDisabled "hostname"
  ) "Starship hostname module should be disabled")

  # Test time module is disabled
  (helpers.assertTest "starship-time-disabled" (
    isModuleDisabled "time"
  ) "Starship time module should be disabled")

  # Test package module is disabled
  (helpers.assertTest "starship-package-disabled" (
    isModuleDisabled "package"
  ) "Starship package module should be disabled")

  # Test nodejs module is disabled
  (helpers.assertTest "starship-nodejs-disabled" (
    isModuleDisabled "nodejs"
  ) "Starship nodejs module should be disabled")

  # Test rust module is disabled
  (helpers.assertTest "starship-rust-disabled" (
    isModuleDisabled "rust"
  ) "Starship rust module should be disabled")

  # Test golang module is disabled
  (helpers.assertTest "starship-golang-disabled" (
    isModuleDisabled "golang"
  ) "Starship golang module should be disabled")

  # Test php module is disabled
  (helpers.assertTest "starship-php-disabled" (
    isModuleDisabled "php"
  ) "Starship php module should be disabled")

  # Test ruby module is disabled
  (helpers.assertTest "starship-ruby-disabled" (
    isModuleDisabled "ruby"
  ) "Starship ruby module should be disabled")

  # Test java module is disabled
  (helpers.assertTest "starship-java-disabled" (
    isModuleDisabled "java"
  ) "Starship java module should be disabled")

  # Test docker_context module is disabled
  (helpers.assertTest "starship-docker-context-disabled" (
    isModuleDisabled "docker_context"
  ) "Starship docker_context module should be disabled")

  # Test aws module is disabled
  (helpers.assertTest "starship-aws-disabled" (
    isModuleDisabled "aws"
  ) "Starship aws module should be disabled")

  # Test gcloud module is disabled
  (helpers.assertTest "starship-gcloud-disabled" (
    isModuleDisabled "gcloud"
  ) "Starship gcloud module should be disabled")
]
