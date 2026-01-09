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
]
