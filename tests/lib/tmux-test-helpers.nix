# Tmux Test Helpers
#
# Provides reusable helper functions for testing Tmux configuration.
# Extracted from tmux-functionality-test.nix to eliminate duplication.

{
  pkgs,
  lib,
  helpers ? import ./test-helpers.nix { inherit pkgs lib; },
  pluginHelpers ? import ./plugin-test-helpers.nix { inherit pkgs lib; inherit helpers; },
}:

rec {
  # Create a plugin presence test
  #
  # Parameters:
  #   - name: Plugin name for test identification
  #   - expected: Boolean indicating if plugin should be present
  #
  # Returns:
  #   - Test derivation using helpers.assertTest
  #
  # Example:
  #   mkPluginTest "vim-tmux-navigator" true
  mkPluginTest =
    name: expected:
    helpers.assertTest "tmux-has-${name}-plugin" expected "tmux should have ${name} plugin";

  # Create a config setting test
  #
  # Parameters:
  #   - name: Test name
  #   - condition: Boolean condition to test
  #   - message: Failure message
  #
  # Returns:
  #   - Test derivation using helpers.assertTest
  #
  # Example:
  #   mkConfigTest "tmux-vi-mode-enabled" true "tmux should have vi mode enabled"
  mkConfigTest =
    name: condition: message:
    helpers.assertTest name condition message;

  # Assert that tmux is enabled
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration (config.programs.tmux)
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertTmuxEnabled tmuxConfig
  assertTmuxEnabled = tmuxConfig:
    helpers.assertTest "tmux-enabled" tmuxConfig.enable "tmux should be enabled";

  # Assert that tmux has plugins configured
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - minCount: Minimum expected plugin count (optional, defaults to 1)
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertTmuxHasPlugins tmuxConfig 4
  assertTmuxHasPlugins = tmuxConfig: minCount:
    helpers.assertTest "tmux-has-plugins" (
      tmuxConfig.plugins != null && builtins.length tmuxConfig.plugins >= minCount
    ) "tmux should have at least ${toString minCount} plugin(s)";

  # Assert exact plugin count
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - expectedCount: Expected number of plugins
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertTmuxPluginCount tmuxConfig 4
  assertTmuxPluginCount = tmuxConfig: expectedCount:
    helpers.assertTest "tmux-plugin-count" (
      builtins.length tmuxConfig.plugins == expectedCount
    ) "tmux should have exactly ${toString expectedCount} plugins";

  # Assert clipboard synchronization is enabled
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertClipboardSync tmuxConfig
  assertClipboardSync = tmuxConfig:
    helpers.assertTestWithDetails "tmux-clipboard-synchronization"
      "on"
      (if builtins.match ".*set -g set-clipboard on.*" tmuxConfig.extraConfig != null then "on" else "off")
      "tmux should enable automatic clipboard synchronization";

  # Assert vi mode is enabled
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertViModeEnabled tmuxConfig
  assertViModeEnabled = tmuxConfig:
    mkConfigTest "tmux-vi-mode-enabled"
      (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*setw -g mode-keys vi.*")
      "tmux should have vi mode enabled";

  # Assert copy mode bindings are present
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertCopyModeBindings tmuxConfig
  assertCopyModeBindings = tmuxConfig:
    mkConfigTest "tmux-copy-mode-bindings"
      (pluginHelpers.hasConfigString tmuxConfig.extraConfig "bind [ copy-mode" &&
       pluginHelpers.hasConfigString tmuxConfig.extraConfig "bind ] paste-buffer")
      "tmux should have copy mode bindings";

  # Assert vi-style selection binding
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertViSelectionBinding tmuxConfig
  assertViSelectionBinding = tmuxConfig:
    mkConfigTest "tmux-vi-selection-binding"
      (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*bind-key -T copy-mode-vi v send-keys -X begin-selection.*")
      "tmux should have vi-style begin-selection binding";

  # Assert mouse paste support
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertMousePasteSupport tmuxConfig
  assertMousePasteSupport = tmuxConfig:
    mkConfigTest "tmux-mouse-paste"
      (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*bind-key -n MouseDown2Pane paste-buffer.*")
      "tmux should support middle-click paste";

  # Assert platform-specific clipboard integration
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertClipboardIntegration tmuxConfig
  assertClipboardIntegration = tmuxConfig:
    mkConfigTest "tmux-clipboard-integration"
      (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*copy-pipe-and-cancel.*pbcopy.*" ||
       pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*copy-pipe-and-cancel.*xclip.*")
      "tmux should have copy-pipe-and-cancel with platform-specific clipboard integration";

  # Assert resurrect settings
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - capturePaneContents: Expected value for @resurrect-capture-pane-contents (optional)
  #   - strategyVim: Expected value for @resurrect-strategy-vim (optional)
  #   - strategyNvim: Expected value for @resurrect-strategy-nvim (optional)
  #
  # Returns:
  #   - List of test derivations
  #
  # Example:
  #   assertResurrectSettings tmuxConfig "yes" "vim" "nvim"
  assertResurrectSettings = tmuxConfig: capturePaneContents: strategyVim: strategyNvim:
    [
      (mkConfigTest "tmux-resurrect-capture-pane"
        (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g @resurrect-capture-pane-contents.*")
        "tmux resurrect should capture pane contents")
      (mkConfigTest "tmux-resurrect-strategy-vim"
        (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g @resurrect-strategy-vim.*")
        "tmux resurrect should have vim session strategy")
      (mkConfigTest "tmux-resurrect-strategy-nvim"
        (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g @resurrect-strategy-nvim.*")
        "tmux resurrect should have nvim session strategy")
    ];

  # Assert continuum settings
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - restore: Expected value for @continuum-restore (optional)
  #   - saveInterval: Expected value for @continuum-save-interval (optional)
  #   - boot: Expected value for @continuum-boot (optional)
  #
  # Returns:
  #   - List of test derivations
  #
  # Example:
  #   assertContinuumSettings tmuxConfig "on" "15" "on"
  assertContinuumSettings = tmuxConfig: restore: saveInterval: boot:
    [
      (mkConfigTest "tmux-continuum-restore"
        (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g @continuum-restore.*")
        "tmux continuum should restore on start")
      (mkConfigTest "tmux-continuum-save-interval"
        (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g @continuum-save-interval.*")
        "tmux continuum should have save interval configured")
      (mkConfigTest "tmux-continuum-boot"
        (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g @continuum-boot.*")
        "tmux continuum should start on boot")
    ];

  # Assert tmux history limit
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - expectedLimit: Expected history limit
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertHistoryLimit tmuxConfig 50000
  assertHistoryLimit = tmuxConfig: expectedLimit:
    mkConfigTest "tmux-history-limit"
      (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g history-limit ${toString expectedLimit}.*")
      "tmux should have history limit set to ${toString expectedLimit}";

  # Assert tmux display time
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - expectedTime: Expected display time in milliseconds
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertDisplayTime tmuxConfig 2000
  assertDisplayTime = tmuxConfig: expectedTime:
    mkConfigTest "tmux-display-time"
      (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g display-time ${toString expectedTime}.*")
      "tmux should have display time set to ${toString expectedTime}ms";

  # Assert tmux repeat time
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - expectedTime: Expected repeat time in milliseconds
  #
  # Returns:
  #   - Test derivation
  #
  # Example:
  #   assertRepeatTime tmuxConfig 500
  assertRepeatTime = tmuxConfig: expectedTime:
    mkConfigTest "tmux-repeat-time"
      (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig ".*set -g repeat-time ${toString expectedTime}.*")
      "tmux should have repeat time set to ${toString expectedTime}ms";

  # Create comprehensive tmux test suite
  #
  # Parameters:
  #   - tmuxConfig: The tmux configuration
  #   - pluginTests: List of plugin test specifications
  #   - configTests: List of config test specifications
  #
  # Returns:
  #   - Test suite with all specified tests
  #
  # Example:
  #   assertTmuxConfig tmuxConfig [
  #     { name = "sensible"; present = true; }
  #     { name = "yank"; present = false; }
  #   ] [
  #     { name = "vi-mode"; pattern = ".*setw -g mode-keys vi.*"; }
  #     { name = "clipboard"; pattern = ".*set -g set-clipboard on.*"; }
  #   ]
  assertTmuxConfig = tmuxConfig: pluginTests: configTests:
    let
      # Create plugin tests
      pluginTestDerivations = builtins.map (
        test:
        if test.present then
          mkPluginTest test.name true
        else
          helpers.assertTest "tmux-no-${test.name}-plugin" (
            !(pluginHelpers.hasPluginByName tmuxConfig.plugins test.name)
          ) "tmux should NOT have ${test.name} plugin"
      ) pluginTests;

      # Create config tests
      configTestDerivations = builtins.map (
        test: mkConfigTest "tmux-${test.name}"
          (pluginHelpers.hasConfigPattern tmuxConfig.extraConfig test.pattern)
          test.message
      ) configTests;

      # Summary test
      summaryTest = pkgs.runCommand "tmux-config-summary" { } ''
        echo "✅ Tmux configuration: All tests passed"
        echo "  Plugin tests: ${toString (builtins.length pluginTestDerivations)}"
        echo "  Config tests: ${toString (builtins.length configTestDerivations)}"
        touch $out
      '';
    in
    helpers.testSuite "tmux-configuration" (
      pluginTestDerivations ++ configTestDerivations ++ [ summaryTest ]
    );
}
