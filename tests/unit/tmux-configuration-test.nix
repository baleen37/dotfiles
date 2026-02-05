# tests/unit/tmux-configuration-test.nix
# Tmux configuration unit tests for Oh My Tmux style
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

  # Helper to check if config contains a string
  hasConfigString = str: builtins.match ".*${str}.*" tmuxConfig.extraConfig != null;
in
{
  platforms = ["any"];
  value = helpers.testSuite "tmux-standard-configuration" [
    # Core Oh My Tmux configuration
    (helpers.assertTest "tmux-prefix-is-ctrl-a"
      (tmuxConfig.prefix == "C-a")
      "tmux prefix should be Ctrl-a")

    (helpers.assertTest "tmux-escape-time-is-zero"
      (tmuxConfig.escapeTime == 0)
      "tmux escape time should be 0")

    (helpers.assertTest "tmux-has-two-plugins"
      (builtins.length tmuxConfig.plugins == 2)
      "tmux should have 2 plugins (sensible, vim-tmux-navigator)")

    # Oh My Tmux style bindings
    (helpers.assertTest "tmux-split-vertical"
      (hasConfigString "bind | split-window -h")
      "tmux should bind | to vertical split")

    (helpers.assertTest "tmux-vim-pane-navigation"
      (hasConfigString "bind h select-pane -L")
      "tmux should use vim-style pane navigation")

    # OSC52 clipboard (cross-platform)
    (helpers.assertTest "tmux-osc52-enabled"
      (hasConfigString "set -s set-clipboard external")
      "tmux should use OSC52 clipboard")

    (helpers.assertTest "tmux-no-pbcopy"
      (!hasConfigString "pbcopy")
      "tmux should NOT use pbcopy")

    (helpers.assertTest "tmux-no-xclip"
      (!hasConfigString "xclip")
      "tmux should NOT use xclip")
  ];
}
