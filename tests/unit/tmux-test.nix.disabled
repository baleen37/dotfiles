# tests/unit/tmux-test.nix
# Tmux configuration extraction tests
# Tests that tmux config is properly extracted from modules/ to users/shared/tmux.nix
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  nixtest ? { },
  self ? ./.,
  inputs ? { },
}:

let
  # Import nixtest framework assertions
  inherit (nixtest.assertions) assertTrue assertFalse;

  # Try to import tmux config (this will fail initially)
  tmuxConfigFile = ../../users/shared/tmux.nix;
  tmuxConfigExists = builtins.pathExists tmuxConfigFile;

  # Test if tmux config can be imported (will fail initially)
  tmuxConfig =
    if tmuxConfigExists then
      (import tmuxConfigFile {
        inherit pkgs lib;
        config = { };
      })
    else
      { };

  # Test if tmux is enabled
  tmuxEnabled = tmuxConfigExists && tmuxConfig.programs.tmux.enable;

  # Test if tmux has plugins
  hasPlugins = tmuxConfigExists && builtins.hasAttr "plugins" tmuxConfig.programs.tmux;

  # Test if tmux has extraConfig
  hasExtraConfig = tmuxConfigExists && builtins.hasAttr "extraConfig" tmuxConfig.programs.tmux;

  # Test if tmux has sensible plugin
  hasSensiblePlugin =
    tmuxConfigExists
    && builtins.any (plugin: plugin.name or null == "sensible") tmuxConfig.programs.tmux.plugins;

  # Test if tmux has vim-tmux-navigator plugin
  hasVimNavigatorPlugin =
    tmuxConfigExists
    && builtins.any (
      plugin: plugin.name or null == "vim-tmux-navigator"
    ) tmuxConfig.programs.tmux.plugins;

  # Test if tmux has yank plugin
  hasYankPlugin =
    tmuxConfigExists
    && builtins.any (plugin: plugin.name or null == "yank") tmuxConfig.programs.tmux.plugins;

  # Test if tmux has resurrect plugin
  hasResurrectPlugin =
    tmuxConfigExists
    && builtins.any (plugin: plugin.name or null == "resurrect") tmuxConfig.programs.tmux.plugins;

  # Test if tmux has continuum plugin
  hasContinuumPlugin =
    tmuxConfigExists
    && builtins.any (plugin: plugin.name or null == "continuum") tmuxConfig.programs.tmux.plugins;

  # Test if escape time is set to 0 (performance optimization)
  hasOptimizedEscapeTime = tmuxConfigExists && tmuxConfig.programs.tmux.escapeTime == 0;

  # Test if history limit is set to 50000 (performance optimization)
  hasOptimizedHistoryLimit = tmuxConfigExists && tmuxConfig.programs.tmux.historyLimit == 50000;

  # Test suite using NixTest framework
  testSuite = {
    name = "tmux-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that tmux.nix file exists (will fail initially)
      tmux-config-exists = nixtest.test "tmux-config-exists" (assertTrue tmuxConfigExists);

      # Test that tmux is enabled
      tmux-enabled = nixtest.test "tmux-enabled" (assertTrue tmuxEnabled);

      # Test that tmux has plugins
      tmux-plugins-exist = nixtest.test "tmux-plugins-exist" (assertTrue hasPlugins);

      # Test that tmux has extraConfig
      tmux-extra-config = nixtest.test "tmux-extra-config" (assertTrue hasExtraConfig);

      # Test that tmux has sensible plugin
      tmux-sensible-plugin = nixtest.test "tmux-sensible-plugin" (assertTrue hasSensiblePlugin);

      # Test that tmux has vim-tmux-navigator plugin
      tmux-vim-navigator = nixtest.test "tmux-vim-navigator" (assertTrue hasVimNavigatorPlugin);

      # Test that tmux has yank plugin
      tmux-yank-plugin = nixtest.test "tmux-yank-plugin" (assertTrue hasYankPlugin);

      # Test that tmux has resurrect plugin
      tmux-resurrect-plugin = nixtest.test "tmux-resurrect-plugin" (assertTrue hasResurrectPlugin);

      # Test that tmux has continuum plugin
      tmux-continuum-plugin = nixtest.test "tmux-continuum-plugin" (assertTrue hasContinuumPlugin);

      # Test that escape time is optimized
      tmux-optimized-escape = nixtest.test "tmux-optimized-escape" (assertTrue hasOptimizedEscapeTime);

      # Test that history limit is optimized
      tmux-optimized-history = nixtest.test "tmux-optimized-history" (
        assertTrue hasOptimizedHistoryLimit
      );
    };
  };

in
testSuite
