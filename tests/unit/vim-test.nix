# tests/unit/vim-test.nix
# Vim configuration extraction tests
# Tests that vim config is properly extracted from modules/ to users/baleen/vim.nix
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

  # Try to import vim config (this will fail initially)
  vimConfigFile = ../../users/baleen/vim.nix;
  vimConfigExists = builtins.pathExists vimConfigFile;

  # Test if vim config can be imported (will fail initially)
  vimConfig =
    if vimConfigExists then
      (import vimConfigFile {
        inherit pkgs lib;
        config = { };
      })
    else
      { };

  # Test if vim is enabled
  vimEnabled = vimConfigExists && vimConfig.programs.vim.enable == true;

  # Test if vim plugins exist
  hasPlugins = vimConfigExists && builtins.hasAttr "plugins" vimConfig.programs.vim;

  # Test if vim settings exist
  hasSettings = vimConfigExists && builtins.hasAttr "settings" vimConfig.programs.vim;

  # Test if vim has extraConfig (for custom key bindings)
  hasExtraConfig = vimConfigExists && builtins.hasAttr "extraConfig" vimConfig.programs.vim;

  # Test if airline plugin is present
  hasAirlinePlugin =
    vimConfigExists
    && builtins.any (plugin: plugin.name or null == "vim-airline") vimConfig.programs.vim.plugins;

  # Test if tmux-navigator plugin is present
  hasTmuxNavigator =
    vimConfigExists
    && builtins.any (
      plugin: plugin.name or null == "vim-tmux-navigator"
    ) vimConfig.programs.vim.plugins;

  # Test suite using NixTest framework
  testSuite = {
    name = "vim-config-tests";
    framework = "nixtest";
    type = "unit";
    tests = {
      # Test that vim.nix file exists (will fail initially)
      vim-config-exists = nixtest.test "vim-config-exists" (assertTrue vimConfigExists);

      # Test that vim is enabled
      vim-enabled = nixtest.test "vim-enabled" (assertTrue vimEnabled);

      # Test that vim plugins exist
      vim-plugins-exist = nixtest.test "vim-plugins-exist" (assertTrue hasPlugins);

      # Test that vim settings exist
      vim-settings-exist = nixtest.test "vim-settings-exist" (assertTrue hasSettings);

      # Test that vim has extraConfig
      vim-extra-config = nixtest.test "vim-extra-config" (assertTrue hasExtraConfig);

      # Test that airline plugin is present
      vim-airline-plugin = nixtest.test "vim-airline-plugin" (assertTrue hasAirlinePlugin);

      # Test that tmux-navigator plugin is present
      vim-tmux-navigator = nixtest.test "vim-tmux-navigator" (assertTrue hasTmuxNavigator);
    };
  };

in
testSuite
