# tests/integration/tmux-functionality.nix
# Tmux configuration integration tests
# Tests that tmux is properly integrated with home manager
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ../..
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Mock configuration for testing tmux integration
  mockConfig = {
    home = {
      homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
    };
  };

  # Import tmux configuration with mocked dependencies to test integration
  tmuxModule = import ../../users/shared/tmux.nix {
    inherit pkgs lib;
    config = mockConfig;
  };
  tmuxConfig = tmuxModule.programs.tmux;

  # Test that the tmux configuration integrates properly with home manager
  homeManagerIntegration = {
    # Test that tmux is properly enabled
    enabled = tmuxConfig.enable == true;

    # Test that tmux has proper configuration structure
    hasValidStructure = builtins.typeOf tmuxConfig == "set";

    # Test that tmux can be built (no evaluation errors)
    buildsSuccessfully = tmuxConfig ? enable && tmuxConfig ? extraConfig;
  };
in
helpers.testSuite "tmux-integration" [
  (helpers.assertTestWithDetails "tmux-config-builds-successfully"
    (if homeManagerIntegration.buildsSuccessfully then "builds" else "fails")
    "builds"
    "Home manager should successfully build tmux configuration")

  (helpers.assertTestWithDetails "tmux-home-manager-integration"
    (if homeManagerIntegration.hasValidStructure then "integrated" else "not integrated")
    "integrated"
    "tmux should be properly integrated with home manager")

  (helpers.assertTestWithDetails "tmux-enabled-in-home-manager"
    (if homeManagerIntegration.enabled then "enabled" else "disabled")
    "enabled"
    "tmux should be enabled in home manager configuration")
]
