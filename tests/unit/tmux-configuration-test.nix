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

  # Task 3: Enable Standard Clipboard Synchronization
  (helpers.assertTestWithDetails "tmux-enables-clipboard-synchronization"
    "on"
    (if builtins.match ".*set -g set-clipboard on.*" tmuxConfig.extraConfig != null then "on" else "off")
    "tmux should enable automatic clipboard synchronization")

  # Task 4: Add Standard Copy Mode Key Bindings
  (helpers.assertTest "tmux-has-standard-copy-bindings"
    (builtins.substring 0 1000 tmuxConfig.extraConfig != "" &&
     builtins.stringLength tmuxConfig.extraConfig > 500 &&
     builtins.match ".*copy-mode.*" tmuxConfig.extraConfig != null &&
     builtins.match ".*paste-buffer.*" tmuxConfig.extraConfig != null &&
     builtins.match ".*begin-selection.*" tmuxConfig.extraConfig != null)
    "tmux should have standard copy mode key bindings")

  # Task 5: Add Mouse Support for Paste
  (enhancedHelpers.assertTestWithDetails "tmux-has-mouse-paste-support"
    (builtins.match ".*bind-key -n MouseDown2Pane paste-buffer.*" tmuxConfig.extraConfig != null)
    "tmux should support middle-click paste"
    "enabled"
    (if builtins.match ".*bind-key -n MouseDown2Pane paste-buffer.*" tmuxConfig.extraConfig != null then "enabled" else "disabled")
    null
    null)

  # Task 6: Implement Cross-Platform Clipboard Integration
  (enhancedHelpers.assertTestWithDetails "tmux-has-copy-pipe-and-cancel-integration"
    (builtins.match ".*copy-pipe-and-cancel.*pbcopy.*" tmuxConfig.extraConfig != null ||
     builtins.match ".*copy-pipe-and-cancel.*xclip.*" tmuxConfig.extraConfig != null)
    "tmux should have copy-pipe-and-cancel with platform-specific clipboard integration"
    "copy-pipe-and-cancel present"
    (if builtins.match ".*copy-pipe-and-cancel.*pbcopy.*" tmuxConfig.extraConfig != null then "macOS copy-pipe-and-cancel with pbcopy present"
     else if builtins.match ".*copy-pipe-and-cancel.*xclip.*" tmuxConfig.extraConfig != null then "Linux copy-pipe-and-cancel with xclip present"
     else "no copy-pipe-and-cancel integration")
    null
    null)
]
