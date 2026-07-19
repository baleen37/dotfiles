# tests/integration/tmux-functionality.nix
# Tmux configuration integration tests for Oh My Tmux style
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
  seshConfig = tmuxModule.config.content.programs.sesh or { };

  pluginPackage = plugin: plugin.plugin or plugin;
  pluginName = plugin: (pluginPackage plugin).pname or null;
  continuumPlugin = lib.findFirst (
    plugin: pluginName plugin == "tmuxplugin-continuum"
  ) null tmuxConfig.plugins;

  homeConfig = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      ../../users/shared/programs/tmux.nix
      {
        modules.programs.tmux.enable = true;
        programs.fzf.tmux.enableShellIntegration = true;
        home = {
          username = "test";
          homeDirectory = if pkgs.stdenv.isDarwin then "/Users/test" else "/home/test";
          stateVersion = "24.11";
        };
      }
    ];
  };
  generatedTmuxConfig = homeConfig.config.xdg.configFile."tmux/tmux.conf".text;
  generatedTmuxConfigFile = pkgs.writeText "tmux.conf" generatedTmuxConfig;

  # Helper function to check if config contains a string
  hasConfigString = str: pluginHelpers.hasConfigString tmuxConfig.extraConfig str;

  # Helper to create config setting test
  mkConfigTest =
    name: condition: message:
    helpers.assertTest name condition message;

in
{
  # ============================================================================
  # Core configuration - Oh My Tmux style
  # ============================================================================
  tmux-prefix-is-ctrl-a = helpers.assertTest "tmux-prefix-is-ctrl-a" (
    tmuxConfig.prefix == "C-a"
  ) "tmux prefix should be Ctrl-a (Oh My Tmux style)";

  tmux-prefix-send-prefix =
    mkConfigTest "tmux-prefix-send-prefix" (hasConfigString "bind C-a send-prefix")
      "tmux should bind C-a C-a to send prefix to application";

  tmux-prefix-last-window =
    mkConfigTest "tmux-prefix-last-window" (hasConfigString "bind a last-window")
      "tmux should bind a to toggle last window";

  tmux-has-resurrect-plugin =
    helpers.assertTest "tmux-has-resurrect-plugin"
      (pluginHelpers.hasPluginByName tmuxConfig.plugins "tmuxplugin-resurrect")
      "tmux should load tmux-resurrect through Home Manager";

  tmux-has-continuum-plugin = helpers.assertTest "tmux-has-continuum-plugin" (
    continuumPlugin != null
  ) "tmux should load tmux-continuum through Home Manager";

  tmux-has-vim-navigator-plugin =
    helpers.assertTest "tmux-has-vim-navigator-plugin"
      (pluginHelpers.hasPluginByName tmuxConfig.plugins "tmuxplugin-vim-tmux-navigator")
      "tmux should load vim-tmux-navigator through Home Manager";

  tmux-plugin-order = helpers.assertTest "tmux-plugin-order" (
    builtins.map pluginName tmuxConfig.plugins == [
      "tmuxplugin-resurrect"
      "tmuxplugin-continuum"
      "tmuxplugin-vim-tmux-navigator"
    ]
  ) "tmux should load resurrect, continuum, then vim-tmux-navigator";

  tmux-continuum-auto-restore = mkConfigTest "tmux-continuum-auto-restore" (
    pluginHelpers.hasConfigString
    (continuumPlugin.extraConfig or "")
    "set -g @continuum-restore 'on'"
  ) "tmux continuum should restore saved sessions automatically";

  tmux-continuum-config-order = pkgs.runCommand "tmux-continuum-config-order" { } ''
    continuum_line="$(${pkgs.gnugrep}/bin/grep -nF 'tmuxplugin-continuum' ${generatedTmuxConfigFile} | ${pkgs.coreutils}/bin/tail -n 1 | cut -d: -f1)"
    restore_line="$(${pkgs.gnugrep}/bin/grep -nF "set -g @continuum-restore 'on'" ${generatedTmuxConfigFile} | cut -d: -f1)"
    status_right_line="$(${pkgs.gnugrep}/bin/grep -nF "set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M '" ${generatedTmuxConfigFile} | cut -d: -f1)"

    echo "continuum-line=$continuum_line"
    echo "continuum-restore-line=$restore_line"
    echo "status-right-line=$status_right_line"
    test "$(${pkgs.gnugrep}/bin/grep -cF "set -g @continuum-restore 'on'" ${generatedTmuxConfigFile})" -eq 1
    test "$(${pkgs.gnugrep}/bin/grep -cF "set -g status-right " ${generatedTmuxConfigFile})" -eq 1
    test "$restore_line" -lt "$continuum_line"
    test "$status_right_line" -lt "$continuum_line"

    touch "$out"
  '';

  # ============================================================================
  # Key bindings
  # ============================================================================
  tmux-sesh-enabled = helpers.assertTest "tmux-sesh-enabled" (seshConfig.enable or false
  ) "tmux should enable sesh through Home Manager";

  tmux-sesh-key-is-uppercase-t = helpers.assertTest "tmux-sesh-key-is-uppercase-t" (
    (seshConfig.tmuxKey or null) == "T"
  ) "sesh should use prefix+T and preserve tmux prefix+t clock mode";

  tmux-split-vertical =
    mkConfigTest "tmux-split-vertical" (hasConfigString "bind | split-window -h")
      "tmux should bind | to a left/right split with the current pane path";

  tmux-split-horizontal =
    mkConfigTest "tmux-split-horizontal" (hasConfigString "bind - split-window -v")
      "tmux should bind - to a top/bottom split with the current pane path";

  tmux-default-split-bindings-unbound = mkConfigTest "tmux-default-split-bindings-unbound" (
    hasConfigString "unbind '%'" && hasConfigString "unbind '\"'"
  ) "tmux should unbind the default % and double-quote split keys";

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
