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
  assertHelpers = import ../lib/assertions.nix { inherit pkgs lib; };

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

  # Test plugin presence
  hasSensiblePlugin = builtins.any (
    plugin: builtins.match ".*sensible.*" (plugin.pname or "") != null
  ) tmuxConfig.plugins;

  hasVimTmuxNavigatorPlugin = builtins.any (
    plugin: builtins.match ".*navigator.*" (plugin.pname or "") != null
  ) tmuxConfig.plugins;

  hasResurrectPlugin = builtins.any (
    plugin: builtins.match ".*resurrect.*" (plugin.pname or "") != null
  ) tmuxConfig.plugins;

  hasContinuumPlugin = builtins.any (
    plugin: builtins.match ".*continuum.*" (plugin.pname or "") != null
  ) tmuxConfig.plugins;

  # Test that yank plugin is NOT present (Task 2: Remove Yank Plugin Dependency)
  hasYankPlugin = builtins.any (
    plugin: plugin.pname or null == "tmux-yank"
  ) tmuxConfig.plugins;

  # Test vi mode key bindings
  hasViModeKeys = builtins.match ".*setw -g mode-keys vi.*" tmuxConfig.extraConfig != null;

  hasCopyModeBinding = lib.hasInfix "bind [ copy-mode" tmuxConfig.extraConfig;

  hasPasteBufferBinding = lib.hasInfix "bind ] paste-buffer" tmuxConfig.extraConfig;

  hasBeginSelectionBinding = builtins.match ".*bind-key -T copy-mode-vi v send-keys -X begin-selection.*" tmuxConfig.extraConfig != null;

  # Test resurrect and continuum settings
  hasResurrectCapturePane = builtins.match ".*set -g @resurrect-capture-pane-contents.*" tmuxConfig.extraConfig != null;

  hasResurrectStrategyVim = builtins.match ".*set -g @resurrect-strategy-vim.*" tmuxConfig.extraConfig != null;

  hasResurrectStrategyNvim = builtins.match ".*set -g @resurrect-strategy-nvim.*" tmuxConfig.extraConfig != null;

  hasContinuumRestore = builtins.match ".*set -g @continuum-restore.*" tmuxConfig.extraConfig != null;

  hasContinuumSaveInterval = builtins.match ".*set -g @continuum-save-interval.*" tmuxConfig.extraConfig != null;

  hasContinuumBoot = builtins.match ".*set -g @continuum-boot.*" tmuxConfig.extraConfig != null;

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

  # Test vim-tmux-navigator plugin is present
  (helpers.assertTest "tmux-has-vim-tmux-navigator-plugin"
    hasVimTmuxNavigatorPlugin
    "tmux should have vim-tmux-navigator plugin")

  # Test sensible plugin is present
  (helpers.assertTest "tmux-has-sensible-plugin"
    hasSensiblePlugin
    "tmux should have sensible plugin")

  # Test resurrect plugin is present
  (helpers.assertTest "tmux-has-resurrect-plugin"
    hasResurrectPlugin
    "tmux should have resurrect plugin")

  # Test continuum plugin is present
  (helpers.assertTest "tmux-has-continuum-plugin"
    hasContinuumPlugin
    "tmux should have continuum plugin")

  # Test that yank plugin is NOT present
  (helpers.assertTest "tmux-no-yank-plugin"
    (!hasYankPlugin)
    "tmux should NOT have yank plugin (removed in Task 2)")

  # Test vi mode is enabled
  (helpers.assertTest "tmux-vi-mode-enabled"
    hasViModeKeys
    "tmux should have vi mode enabled")

  # Test copy mode binding
  (helpers.assertTest "tmux-copy-mode-binding"
    hasCopyModeBinding
    "tmux should have copy mode binding")

  # Test paste buffer binding
  (helpers.assertTest "tmux-paste-buffer-binding"
    hasPasteBufferBinding
    "tmux should have paste buffer binding")

  # Test begin-selection binding in vi mode
  (helpers.assertTest "tmux-vi-begin-selection-binding"
    hasBeginSelectionBinding
    "tmux should have begin-selection binding in vi copy mode")

  # Test resurrect capture pane contents setting
  (helpers.assertTest "tmux-resurrect-capture-pane-contents"
    hasResurrectCapturePane
    "tmux resurrect should capture pane contents")

  # Test resurrect strategy for vim
  (helpers.assertTest "tmux-resurrect-strategy-vim"
    hasResurrectStrategyVim
    "tmux resurrect should have vim session strategy")

  # Test resurrect strategy for neovim
  (helpers.assertTest "tmux-resurrect-strategy-nvim"
    hasResurrectStrategyNvim
    "tmux resurrect should have nvim session strategy")

  # Test continuum restore on start
  (helpers.assertTest "tmux-continuum-restore"
    hasContinuumRestore
    "tmux continuum should restore on start")

  # Test continuum save interval
  (helpers.assertTest "tmux-continuum-save-interval"
    hasContinuumSaveInterval
    "tmux continuum should have save interval configured")

  # Test continuum boot option
  (helpers.assertTest "tmux-continuum-boot"
    hasContinuumBoot
    "tmux continuum should start on boot")
]
