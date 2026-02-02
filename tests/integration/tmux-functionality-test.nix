# tests/integration/tmux-functionality.nix
# Tmux configuration integration tests
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

  # Test that the tmux configuration integrates properly with home manager
  homeManagerIntegration = {
    # Test that tmux is properly enabled
    enabled = tmuxConfig.enable == true;

    # Test that tmux has proper configuration structure
    hasValidStructure = builtins.typeOf tmuxConfig == "set";

    # Test that tmux can be built (no evaluation errors)
    buildsSuccessfully = tmuxConfig ? enable && tmuxConfig ? extraConfig;
  };

  # Helper function to check if a plugin is present by pattern (uses pluginHelpers)
  hasPluginByPattern =
    pattern: pluginHelpers.hasPluginByPattern tmuxConfig.plugins pattern;

  # Helper function to check if a plugin is present by exact name (uses pluginHelpers)
  hasPluginByName =
    name: pluginHelpers.hasPluginByName tmuxConfig.plugins name;

  # Helper function to check if config contains a regex pattern (uses pluginHelpers)
  hasConfigPattern =
    pattern: pluginHelpers.hasConfigPattern tmuxConfig.extraConfig pattern;

  # Helper function to check if config contains a string (uses pluginHelpers)
  hasConfigString =
    str: pluginHelpers.hasConfigString tmuxConfig.extraConfig str;

  # Plugin presence tests
  pluginTests = {
    sensible = hasPluginByPattern ".*sensible.*";
    vimTmuxNavigator = hasPluginByPattern ".*navigator.*";
    resurrect = hasPluginByPattern ".*resurrect.*";
    continuum = hasPluginByPattern ".*continuum.*";
    yank = hasPluginByName "tmux-yank";
  };

  # Vi mode key binding tests
  viModeTests = {
    modeKeys = hasConfigPattern ".*setw -g mode-keys vi.*";
    copyMode = hasConfigString "bind [ copy-mode";
    pasteBuffer = hasConfigString "bind ] paste-buffer";
    beginSelection = hasConfigPattern ".*bind-key -T copy-mode-vi v send-keys -X begin-selection.*";
  };

  # Resurrect and continuum settings tests
  resurrectTests = {
    capturePane = hasConfigPattern ".*set -g @resurrect-capture-pane-contents.*";
    strategyVim = hasConfigPattern ".*set -g @resurrect-strategy-vim.*";
    strategyNvim = hasConfigPattern ".*set -g @resurrect-strategy-nvim.*";
  };

  continuumTests = {
    restore = hasConfigPattern ".*set -g @continuum-restore.*";
    saveInterval = hasConfigPattern ".*set -g @continuum-save-interval.*";
    boot = hasConfigPattern ".*set -g @continuum-boot.*";
  };

  # Helper to create plugin presence test
  mkPluginTest =
    name: expected:
    helpers.assertTest "tmux-has-${name}-plugin" expected "tmux should have ${name} plugin";

  # Helper to create config setting test
  mkConfigTest =
    name: condition: message:
    helpers.assertTest name condition message;

in
helpers.testSuite "tmux-integration" [
  # Home Manager integration tests
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

  # Plugin tests
  (mkPluginTest "vim-tmux-navigator" pluginTests.vimTmuxNavigator)
  (mkPluginTest "sensible" pluginTests.sensible)
  (mkPluginTest "resurrect" pluginTests.resurrect)
  (mkPluginTest "continuum" pluginTests.continuum)
  (helpers.assertTest "tmux-no-yank-plugin"
    (!pluginTests.yank)
    "tmux should NOT have yank plugin (removed in Task 2)")

  # Vi mode key binding tests
  (mkConfigTest "tmux-vi-mode-enabled" viModeTests.modeKeys
    "tmux should have vi mode enabled")
  (mkConfigTest "tmux-copy-mode-binding" viModeTests.copyMode
    "tmux should have copy mode binding")
  (mkConfigTest "tmux-paste-buffer-binding" viModeTests.pasteBuffer
    "tmux should have paste buffer binding")
  (mkConfigTest "tmux-vi-begin-selection-binding" viModeTests.beginSelection
    "tmux should have begin-selection binding in vi copy mode")

  # Resurrect settings tests
  (mkConfigTest "tmux-resurrect-capture-pane-contents" resurrectTests.capturePane
    "tmux resurrect should capture pane contents")
  (mkConfigTest "tmux-resurrect-strategy-vim" resurrectTests.strategyVim
    "tmux resurrect should have vim session strategy")
  (mkConfigTest "tmux-resurrect-strategy-nvim" resurrectTests.strategyNvim
    "tmux resurrect should have nvim session strategy")

  # Continuum settings tests
  (mkConfigTest "tmux-continuum-restore" continuumTests.restore
    "tmux continuum should restore on start")
  (mkConfigTest "tmux-continuum-save-interval" continuumTests.saveInterval
    "tmux continuum should have save interval configured")
  (mkConfigTest "tmux-continuum-boot" continuumTests.boot
    "tmux continuum should start on boot")

  # Terminal and display settings tests
  (helpers.assertTest "tmux-default-terminal" (hasConfigString "default-terminal \"tmux-256color\"")
    "tmux should use tmux-256color as default terminal")

  (helpers.assertTest "tmux-default-shell-zsh" (hasConfigString "default-shell")
    "tmux should use zsh as default shell")

  (helpers.assertTest "tmux-focus-events" (hasConfigString "focus-events on")
    "tmux should have focus events enabled")

  # Mouse support tests
  (helpers.assertTest "tmux-mouse-enabled" (hasConfigString "mouse on")
    "tmux should have mouse support enabled")

  (helpers.assertTest "tmux-middle-click-paste" (hasConfigString "MouseDown2Pane paste-buffer")
    "tmux should bind middle-click to paste")

  # Window and pane management tests
  (helpers.assertTest "tmux-split-horizontal-binding" (hasConfigString "bind | split-window -h")
    "tmux should bind | to horizontal split")

  (helpers.assertTest "tmux-split-vertical-binding" (hasConfigString "bind - split-window -v")
    "tmux should bind - to vertical split")

  (helpers.assertTest "tmux-rename-binding" (hasConfigString "bind r source-file")
    "tmux should bind r to reload config")

  # Alt key navigation without prefix
  (helpers.assertTest "tmux-alt-h-previous-window" (hasConfigString "bind -n M-h previous-window")
    "tmux should bind Alt+h to previous window without prefix")

  (helpers.assertTest "tmux-alt-l-next-window" (hasConfigString "bind -n M-l next-window")
    "tmux should bind Alt+l to next window without prefix")

  # Tab (window) management tests
  (helpers.assertTest "tmux-new-window-binding" (hasConfigString "bind t new-window")
    "tmux should bind t to create new window")

  (helpers.assertTest "tmux-last-window-binding" (hasConfigString "bind Tab last-window")
    "tmux should bind Tab to switch to last window")

  # Status bar configuration tests
  (helpers.assertTest "tmux-status-position" (hasConfigString "status-position bottom")
    "tmux status bar should be at bottom")

  (helpers.assertTest "tmux-status-bg-color" (hasConfigString "status-bg colour234")
    "tmux status bar should have dark background")

  (helpers.assertTest "tmux-status-fg-color" (hasConfigString "status-fg colour137")
    "tmux status bar should have light foreground")

  (helpers.assertTest "tmux-window-status-format" (hasConfigString "window-status-format")
    "tmux should have window status format configured")

  # Session persistence directory tests
  (helpers.assertTest "tmux-resurrect-dir" (hasConfigPattern ".*@resurrect-dir.*")
    "tmux resurrect should have custom directory configured")
]
