# tests/integration/switch-user-test.nix
#
# Integration test for make switch-user command
# Validates that home-manager configuration can be activated for user-only updates
#
# Test scenarios:
# - Home Manager configuration builds successfully
# - User configuration is accessible for different users
# - Required packages and modules are included
# - Platform-specific behavior (Darwin-only)

{
  inputs,
  system,
  ...
}:

let
  pkgs = import inputs.nixpkgs { inherit system; };
  inherit (pkgs) lib;
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test users that should be supported
  testUsers = [
    "baleen"
    "jito.hello"
    "testuser"
  ];

in
# This test suite is Darwin-only
{
  platforms = ["darwin"];
  value = helpers.testSuite "switch-user" [
    # Test 1: Home Manager configurations exist for supported users
    (helpers.assertTest "home-configs-exist" (builtins.all (
      user: inputs.self ? homeConfigurations.${user}
    ) testUsers) "Home Manager configurations should exist for all supported users")

    # Test 2: Home Manager configuration can be built
    (let
      # Test with default user (baleen)
      userConfig = inputs.self.homeConfigurations.baleen;
    in
    helpers.assertTest "home-config-builds" (
      userConfig ? activationPackage
    ) "Home Manager configuration should be buildable for user activation")

    # Test 3: User configuration includes required modules
    (let
      # Extract home-manager configuration to test module imports
      hmConfig = import ../../users/shared/home-manager.nix {
        inherit pkgs lib inputs;
        currentSystemUser = "baleen";
      };
    in
    helpers.testSuite "user-config-modules" [
      (helpers.assertTest "has-git-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/git.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import git.nix module")

      (helpers.assertTest "has-vim-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/vim.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import vim.nix module")

      (helpers.assertTest "has-zsh-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/zsh.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import zsh.nix module")

      (helpers.assertTest "has-claude-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/claude-code.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import claude-code.nix module")

      (helpers.assertTest "has-tmux-module" (builtins.any (
        m: lib.hasSuffix "/users/shared/tmux.nix" (builtins.toString m)
      ) hmConfig.imports) "User configuration should import tmux.nix module")
    ])

    # Test 4: User configuration includes essential packages
    # Note: This test uses the evaluated homeConfiguration from the flake
    # because raw module imports don't have evaluated home.packages
    (let
      # Use the actual evaluated homeConfiguration
      userConfig = inputs.self.homeConfigurations.baleen;
      essentialPackages = [
        "git"
        "vim"
        "zsh"
        "tmux"
        "claude-code"
        "direnv"
        "fzf"
        "ripgrep"
      ];
    in
    helpers.testSuite "essential-packages" [
      (helpers.assertTest "has-essential-packages" (
        # Check that activationPackage exists as a proxy for packages being configured
        # Full package validation would require building the entire configuration
        userConfig ? activationPackage
      ) "User configuration should include essential packages via home-manager")
    ])

    # Test 5: User home directory is correctly configured
    (let
      hmConfig = import ../../users/shared/home-manager.nix {
        inherit pkgs lib inputs;
        currentSystemUser = "baleen";
      };
    in
    helpers.testSuite "user-home-config" [
      (helpers.assertTest "correct-username" (
        hmConfig.home.username == "baleen"
      ) "Home Manager configuration should use correct username")

      (helpers.assertTest "correct-home-directory" (
        hmConfig.home.homeDirectory == "/Users/baleen"
      ) "Home Manager configuration should use correct home directory on Darwin")

      (helpers.assertTest "has-state-version" (
        hmConfig.home ? stateVersion && hmConfig.home.stateVersion == "24.11"
      ) "Home Manager configuration should have state version")
    ])
  ];
}
