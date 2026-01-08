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
    lib.hasInfix ("$" + module) starshipSettings.format;

  # Helper to test starship boolean settings
  assertBoolSetting = name: value: expected:
    helpers.assertTest "starship-${name}" (
      value == expected
    ) "Starship ${name} should be ${toString expected}";

  # Helper to test starship string settings
  assertStringSetting = name: value: expected:
    helpers.assertTest "starship-${name}" (
      value == expected
    ) "Starship ${name} should be '${expected}'";

  # Helper to test starship list settings
  assertListSetting = name: value: expected:
    helpers.assertTest "starship-${name}" (
      value == expected
    ) "Starship ${name} should be ${toString expected}";

  # Helper to test format contains modules
  assertFormatHasModule = module:
    helpers.assertTest "starship-format-has-${lib.replaceStrings ["_"] ["-"] module}"
      (formatContains module)
      "Starship format should include ${module} module";

  # Helper to test module is disabled
  assertModuleDisabled = moduleName:
    helpers.assertTest "starship-${lib.replaceStrings ["_"] ["-"] moduleName}-disabled"
      (isModuleDisabled moduleName)
      "Starship ${moduleName} module should be disabled";

in
helpers.testSuite "starship-configuration" (
  [
    # Basic starship configuration
    (assertBoolSetting "enabled" starshipConfig.programs.starship.enable true)
    (assertBoolSetting "zsh-integration" starshipConfig.programs.starship.enableZshIntegration true)
    (assertBoolSetting "add-newline" starshipSettings.add_newline true)
    (assertStringSetting "command-timeout" starshipSettings.command_timeout 1000)
    (assertStringSetting "scan-timeout" starshipSettings.scan_timeout 30)
    (assertStringSetting "right-format" starshipSettings.right_format "$cmd_duration")

    # Format module checks
    (assertFormatHasModule "directory")
    (assertFormatHasModule "git_branch")
    (assertFormatHasModule "git_status")
    (assertFormatHasModule "python")
    (assertFormatHasModule "nix_shell")
    (assertFormatHasModule "character")

    # Directory module settings
    (assertStringSetting "directory-truncation-length" starshipSettings.directory.truncation_length 3)
    (assertBoolSetting "directory-truncate-to-repo" starshipSettings.directory.truncate_to_repo false)
    (assertStringSetting "directory-style" starshipSettings.directory.style "cyan")

    # Git branch module settings
    (assertStringSetting "git-branch-symbol" starshipSettings.git_branch.symbol "")
    (assertStringSetting "git-branch-style" starshipSettings.git_branch.style "bold purple")

    # Git status module settings
    (assertStringSetting "git-status-style" starshipSettings.git_status.style "bold yellow")

    # Command duration module settings
    (assertStringSetting "cmd-duration-min-time" starshipSettings.cmd_duration.min_time 3000)
    (assertStringSetting "cmd-duration-style" starshipSettings.cmd_duration.style "bold yellow")

    # Python module settings
    (assertStringSetting "python-symbol" starshipSettings.python.symbol " ")
    (assertStringSetting "python-style" starshipSettings.python.style "yellow")
    (assertListSetting "python-detect-extensions" starshipSettings.python.detect_extensions [ ])
    (assertListSetting "python-detect-files" starshipSettings.python.detect_files [ ])
    (assertListSetting "python-detect-folders" starshipSettings.python.detect_folders [ ])

    # Nix shell module settings
    (assertStringSetting "nix-shell-symbol" starshipSettings.nix_shell.symbol "nix")
    (assertStringSetting "nix-shell-style" starshipSettings.nix_shell.style "bold blue")

    # Character module settings
    (assertStringSetting "success-symbol" starshipSettings.character.success_symbol "[➜](bold green)")
    (assertStringSetting "error-symbol" starshipSettings.character.error_symbol "[➜](bold red)")
  ]

  # Disabled modules
  ++ (map assertModuleDisabled [
    "username"
    "hostname"
    "time"
    "package"
    "nodejs"
    "rust"
    "golang"
    "php"
    "ruby"
    "java"
    "docker_context"
    "aws"
    "gcloud"
  ])
)
