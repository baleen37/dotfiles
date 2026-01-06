# tests/integration/vim-test.nix
# Vim configuration extraction tests
# Tests that vim config is properly extracted from modules/ to users/shared/vim.nix
{
  lib ? import <nixpkgs/lib>,
  pkgs ? import <nixpkgs> { },
  system ? builtins.currentSystem or "x86_64-linux",
  self ? ./.,
  inputs ? { },
  nixtest ? { },
  ...
}:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Behavioral test: try to import and use vim config
  vimConfigFile = ../../users/shared/vim.nix;
  vimConfigResult = builtins.tryEval (
    import vimConfigFile {
      inherit pkgs lib;
      config = { };
    }
  );

  # Test if vim config can be imported and is usable
  vimConfig = if vimConfigResult.success then vimConfigResult.value else { };
  vimConfigUsable = vimConfigResult.success;

  # Test if vim is enabled (behavioral)
  vimEnabled = vimConfigUsable && vimConfig.programs.vim.enable;

  # Test if vim plugins exist (behavioral)
  hasPlugins = vimConfigUsable && builtins.hasAttr "plugins" vimConfig.programs.vim;

  # Test if vim settings exist (behavioral)
  hasSettings = vimConfigUsable && builtins.hasAttr "settings" vimConfig.programs.vim;

  # Test if vim has extraConfig (for custom key bindings) (behavioral)
  hasExtraConfig = vimConfigUsable && builtins.hasAttr "extraConfig" vimConfig.programs.vim;

  # Test if airline plugin is present (behavioral)
  hasAirlinePlugin =
    vimConfigUsable
    && builtins.any (plugin: plugin.pname or null == "vim-airline") vimConfig.programs.vim.plugins;

  # Test if tmux-navigator plugin is present (behavioral)
  hasTmuxNavigator =
    vimConfigUsable
    && builtins.any (
      plugin: plugin.pname or null == "vim-tmux-navigator"
    ) vimConfig.programs.vim.plugins;

  # Test if airline-themes plugin is present
  hasAirlineThemes =
    vimConfigUsable
    && builtins.any (
      plugin: plugin.pname or null == "vim-airline-themes"
    ) vimConfig.programs.vim.plugins;

  # Test if relative line numbers are configured
  hasRelativeLineNumbers =
    vimConfigUsable
    && builtins.match ".*set relativenumber.*" vimConfig.programs.vim.extraConfig != null;

  # Test if leader key is set to comma
  hasLeaderKeyComma =
    vimConfigUsable
    && builtins.match ".*let mapleader=\",\".*" vimConfig.programs.vim.extraConfig != null;

  # Test if local leader key is set to space
  hasLocalLeaderKeySpace =
    vimConfigUsable
    && builtins.match ".*let maplocalleader=\" \".*" vimConfig.programs.vim.extraConfig != null;

  # Test if clipboard paste binding exists (<Leader>,)
  hasClipboardPasteBinding =
    vimConfigUsable
    && builtins.match ".*nnoremap <Leader>,.*" vimConfig.programs.vim.extraConfig != null;

  # Test if clipboard copy binding exists (<Leader>.)
  hasClipboardCopyBinding =
    vimConfigUsable
    && builtins.match ".*xnoremap <Leader>\\..*" vimConfig.programs.vim.extraConfig != null;

  # Test if window navigation bindings exist (Ctrl+h/j/k/l)
  hasWindowNavigationBindings =
    vimConfigUsable
    && builtins.match ".*nnoremap <C-h>.*" vimConfig.programs.vim.extraConfig != null
    && builtins.match ".*nnoremap <C-j>.*" vimConfig.programs.vim.extraConfig != null
    && builtins.match ".*nnoremap <C-k>.*" vimConfig.programs.vim.extraConfig != null
    && builtins.match ".*nnoremap <C-l>.*" vimConfig.programs.vim.extraConfig != null;

  # Test if buffer navigation bindings exist (Tab/Shift+Tab)
  hasBufferNavigationBindings =
    vimConfigUsable
    && builtins.match ".*nnoremap <tab>.*bnext.*" vimConfig.programs.vim.extraConfig != null
    && builtins.match ".*nnoremap <S-tab>.*bprev.*" vimConfig.programs.vim.extraConfig != null;

  # Test if ignorecase is enabled
  hasIgnoreCaseSetting =
    vimConfigUsable && vimConfig.programs.vim.settings.ignorecase or false;

in
helpers.testSuite "vim" [
  # Test that vim.nix can be imported and is usable (behavioral)
  (helpers.assertTest "vim-config-usable" vimConfigUsable
    "vim.nix should be importable and usable")

  # Test that vim is enabled
  (helpers.assertTest "vim-enabled" vimEnabled
    "vim should be enabled")

  # Test that vim plugins exist
  (helpers.assertTest "vim-plugins-exist" hasPlugins
    "vim plugins should exist")

  # Test that vim settings exist
  (helpers.assertTest "vim-settings-exist" hasSettings
    "vim settings should exist")

  # Test that vim has extraConfig
  (helpers.assertTest "vim-extra-config" hasExtraConfig
    "vim should have extraConfig for custom key bindings")

  # Test that airline plugin is present
  (helpers.assertTest "vim-airline-plugin" hasAirlinePlugin
    "vim airline plugin should be present")

  # Test that airline-themes plugin is present
  (helpers.assertTest "vim-airline-themes-plugin" hasAirlineThemes
    "vim airline-themes plugin should be present")

  # Test that tmux-navigator plugin is present
  (helpers.assertTest "vim-tmux-navigator" hasTmuxNavigator
    "vim tmux-navigator plugin should be present")

  # Test that relative line numbers are configured
  (helpers.assertTest "vim-relative-line-numbers" hasRelativeLineNumbers
    "vim should have relative line numbers enabled")

  # Test that leader key is set to comma
  (helpers.assertTest "vim-leader-key-comma" hasLeaderKeyComma
    "vim leader key should be set to comma")

  # Test that local leader key is set to space
  (helpers.assertTest "vim-local-leader-key-space" hasLocalLeaderKeySpace
    "vim local leader key should be set to space")

  # Test that clipboard paste binding exists
  (helpers.assertTest "vim-clipboard-paste-binding" hasClipboardPasteBinding
    "vim should have <Leader>, binding for paste from clipboard")

  # Test that clipboard copy binding exists
  (helpers.assertTest "vim-clipboard-copy-binding" hasClipboardCopyBinding
    "vim should have <Leader>. binding for copy to clipboard")

  # Test that window navigation bindings exist
  (helpers.assertTest "vim-window-navigation-bindings" hasWindowNavigationBindings
    "vim should have Ctrl+h/j/k/l bindings for window navigation")

  # Test that buffer navigation bindings exist
  (helpers.assertTest "vim-buffer-navigation-bindings" hasBufferNavigationBindings
    "vim should have Tab/Shift+Tab bindings for buffer navigation")

  # Test that ignorecase is enabled
  (helpers.assertTest "vim-ignorecase-enabled" hasIgnoreCaseSetting
    "vim should have ignorecase setting enabled")
]
