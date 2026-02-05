# tests/integration/tmux-functionality.nix
# Tmux configuration integration tests for Oh My Tmux style
# Tests that tmux is properly integrated with home manager
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  self ? ../..,
  nixtest ? { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  pluginHelpers = import ../lib/plugin-test-helpers.nix { inherit pkgs lib; inherit helpers; };

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

  # Helper function to check if config contains a string
  hasConfigString =
    str: pluginHelpers.hasConfigString tmuxConfig.extraConfig str;

  # Helper to create config setting test
  mkConfigTest =
    name: condition: message:
    helpers.assertTest name condition message;

in
helpers.testSuite "tmux-integration" [
  # ============================================================================
  # Core configuration - Oh My Tmux style
  # ============================================================================
  (helpers.assertTest "tmux-prefix-is-ctrl-a"
    (tmuxConfig.prefix == "C-a")
    "tmux prefix should be Ctrl-a (Oh My Tmux style)")

  (mkConfigTest "tmux-prefix-send-prefix"
    (hasConfigString "bind C-a send-prefix")
    "tmux should bind C-a C-a to send prefix to application")

  (mkConfigTest "tmux-prefix-last-window"
    (hasConfigString "bind a last-window")
    "tmux should bind a to toggle last window")

  (helpers.assertTest "tmux-has-two-plugins"
    (builtins.length tmuxConfig.plugins == 2)
    "tmux should have 2 plugins: sensible, vim-tmux-navigator")

  # ============================================================================
  # Oh My Tmux style key bindings
  # ============================================================================
  (mkConfigTest "tmux-split-vertical"
    (hasConfigString "bind | split-window -h")
    "tmux should bind | to vertical split")

  (mkConfigTest "tmux-split-horizontal"
    (hasConfigString "bind - split-window -v")
    "tmux should bind - to horizontal split")

  (mkConfigTest "tmux-vim-pane-navigation"
    (hasConfigString "bind h select-pane -L")
    "tmux should use vim-style pane navigation (hjkl)")

  # ============================================================================
  # OSC52 clipboard integration (cross-platform, works over SSH)
  # ============================================================================
  (mkConfigTest "tmux-osc52-clipboard"
    (hasConfigString "set -s set-clipboard external")
    "tmux should use OSC52 for cross-platform clipboard")

  (mkConfigTest "tmux-osc52-copy-bindings"
    (hasConfigString "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel")
    "tmux should bind y/Enter to copy with OSC52")

  # ============================================================================
  # Negative tests - ensure old settings are NOT present
  # ============================================================================
  (helpers.assertTest "tmux-no-pbcopy"
    (!hasConfigString "pbcopy")
    "tmux should NOT use pbcopy (OSC52 instead)")

  (helpers.assertTest "tmux-no-xclip"
    (!hasConfigString "xclip")
    "tmux should NOT use xclip (OSC52 instead)")
]
