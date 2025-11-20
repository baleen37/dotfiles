{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  nixtest ? { },
  self ? ../..
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Mock config for testing tmux configuration
  mockConfig = {
    home.homeDirectory = "/home/test";
  };

  # Import tmux configuration with mocked dependencies
  tmuxModule = import ../../users/shared/tmux.nix {
    inherit pkgs lib;
    config = mockConfig;
  };
  tmuxConfig = tmuxModule.programs.tmux;
in
helpers.testSuite "tmux-standard-configuration" [
  # Task 2: Remove Yank Plugin Dependency
  # Test that tmux has plugins configured
  (helpers.assertTest "tmux-has-plugins"
    (tmuxConfig.plugins != null && builtins.length tmuxConfig.plugins > 0)
    "tmux should have plugins configured")

  # Test the correct number of plugins after yank removal
  (helpers.assertTest "tmux-has-four-plugins-after-removal"
    (builtins.length tmuxConfig.plugins == 4)
    "tmux should have 4 plugins after yank removal")
]
