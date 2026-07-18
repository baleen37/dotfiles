# tests/integration/tmux-functionality.nix
# Tmux configuration integration tests
# Tests that tmux is properly integrated with home manager
{
  inputs,
  system,
  pkgs ? import inputs.nixpkgs { inherit system; },
  lib ? pkgs.lib,
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  pluginHelpers = import ../lib/plugin-test-helpers.nix {
    inherit pkgs lib;
    inherit helpers;
  };

  # Mock configuration for testing tmux integration
  mockConfig = {
    modules.programs.tmux.enable = true;
    home = {
      homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
    };
  };

  # Import tmux module and extract the config body via .content
  # (lib.mkIf true {...}).content unwraps the conditional when enable=true
  tmuxModule = import ../../users/shared/programs/tmux.nix {
    inherit pkgs lib;
    config = mockConfig;
  };
  tmuxConfig = tmuxModule.config.content.programs.tmux;

  # Helper function to check if config contains a string
  hasConfigString = str: pluginHelpers.hasConfigString tmuxConfig.extraConfig str;

  # Helper to create config setting test
  mkConfigTest =
    name: condition: message:
    helpers.assertTest name condition message;

in
{
  # ============================================================================
  # Core configuration
  # ============================================================================
  tmux-prefix-is-ctrl-a = helpers.assertTest "tmux-prefix-is-ctrl-a" (
    tmuxConfig.prefix == "C-a"
  ) "tmux prefix should be Ctrl-a (screen-style)";

  tmux-prefix-send-prefix =
    mkConfigTest "tmux-prefix-send-prefix" (hasConfigString "bind C-a send-prefix")
      "tmux should bind C-a C-a to send prefix to application";

  tmux-prefix-last-window =
    mkConfigTest "tmux-prefix-last-window" (hasConfigString "bind a last-window")
      "tmux should bind a to toggle last window";

  tmux-has-vim-navigator-plugin = helpers.assertTest "tmux-has-vim-navigator-plugin" (lib.any
    (p: lib.hasInfix "vim-tmux-navigator" (p.pname or p.plugin.pname or ""))
    tmuxConfig.plugins
  ) "tmux should load vim-tmux-navigator (pairs with the vim plugin for C-h/j/k/l navigation)";

  # ============================================================================
  # Key bindings
  # ============================================================================
  tmux-split-vertical =
    mkConfigTest "tmux-split-vertical" (hasConfigString "bind % split-window -h")
      "tmux should keep the default % vertical split with current pane path";

  tmux-split-horizontal =
    mkConfigTest "tmux-split-horizontal" (hasConfigString "bind '\"' split-window -v")
      "tmux should keep the default \" horizontal split with current pane path";

  tmux-vim-pane-navigation =
    mkConfigTest "tmux-vim-pane-navigation" (hasConfigString "bind h select-pane -L")
      "tmux should use vim-style pane navigation (hjkl)";

  tmux-set-titles =
    mkConfigTest "tmux-set-titles" (hasConfigString "set -g set-titles on")
      "tmux should propagate session/window to the terminal title (Ghostty tab identification)";

  tmux-mosh-truecolor =
    mkConfigTest "tmux-mosh-truecolor"
      (hasConfigString "set -as terminal-features ',xterm-256color:RGB'")
      "tmux should preserve truecolor when mosh presents xterm-256color";

  # ============================================================================
  # OSC52 clipboard integration (cross-platform, works over SSH)
  # ============================================================================
  tmux-osc52-clipboard =
    mkConfigTest "tmux-osc52-clipboard" (hasConfigString "set -s set-clipboard on")
      "tmux should use OSC52 for cross-platform clipboard (on: also accepts inner-app yanks)";

  tmux-osc52-copy-bindings =
    mkConfigTest "tmux-osc52-copy-bindings"
      (hasConfigString "bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel")
      "tmux should bind y/Enter to copy with OSC52";

  # ============================================================================
  # Negative tests - ensure old settings are NOT present
  # ============================================================================
  tmux-no-pbcopy = helpers.assertTest "tmux-no-pbcopy" (
    !hasConfigString "pbcopy"
  ) "tmux should NOT use pbcopy (OSC52 instead)";

  tmux-no-xclip = helpers.assertTest "tmux-no-xclip" (
    !hasConfigString "xclip"
  ) "tmux should NOT use xclip (OSC52 instead)";
}
