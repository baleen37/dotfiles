# tests/unit/tmux-configuration-test.nix
# Test tmux standard configuration implementation

{ inputs, system, pkgs, lib, self, nixtest ? {} }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  enhancedHelpers = import ../lib/enhanced-assertions.nix { inherit pkgs lib; };

  # Mock config for testing - we'll import the actual tmux configuration
  mockConfig = {
    home = {
      homeDirectory = "/home/test";
    };
  };

  # Read current tmux configuration to check its settings
  tmuxExtraConfig = (import ../../users/shared/tmux.nix {
    inherit pkgs lib;
    config = mockConfig;
  }).programs.tmux.extraConfig;

in
helpers.testSuite "tmux-configuration" [
  # Test that tmux configuration exists and can be parsed
  (enhancedHelpers.assertTestWithDetails "tmux-config-exists"
    (tmuxExtraConfig != null)
    "tmux configuration should exist"
    "exists"
    "exists"
    null
    null)

  # Test that tmux currently has set-clipboard disabled (as expected from current config)
  (enhancedHelpers.assertTestWithDetails "tmux-currently-has-clipboard-disabled"
    (builtins.match ".*set -g set-clipboard off.*" tmuxExtraConfig != null)
    "Current tmux config should have set-clipboard disabled"
    "off"
    "off"
    null
    null)
]
