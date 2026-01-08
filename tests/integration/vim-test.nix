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

  # Helper function to check if a plugin exists by pname
  hasPluginByName =
    pname:
    vimConfigUsable
    && builtins.any (plugin: plugin.pname or null == pname) vimConfig.programs.vim.plugins;

  # Helper function to check if extraConfig contains a pattern
  hasConfigPattern =
    pattern: vimConfigUsable && builtins.match pattern vimConfig.programs.vim.extraConfig != null;

  # Helper function to check multiple config patterns (all must match)
  hasAllConfigPatterns =
    patterns: vimConfigUsable && builtins.all (pattern: hasConfigPattern pattern) patterns;

in
helpers.testSuite "vim" [
  # Test that vim.nix can be imported and is usable (behavioral)
  (helpers.assertTest "vim-config-usable" vimConfigUsable "vim.nix should be importable and usable")

  # Test that vim is enabled
  (helpers.assertTest "vim-enabled" (
    vimConfigUsable && vimConfig.programs.vim.enable
  ) "vim should be enabled")

  # Test that vim plugins exist
  (helpers.assertTest "vim-plugins-exist" (
    vimConfigUsable && builtins.hasAttr "plugins" vimConfig.programs.vim
  ) "vim plugins should exist")

  # Test that vim settings exist
  (helpers.assertTest "vim-settings-exist" (
    vimConfigUsable && builtins.hasAttr "settings" vimConfig.programs.vim
  ) "vim settings should exist")

  # Test that vim has extraConfig
  (helpers.assertTest "vim-extra-config" (
    vimConfigUsable && builtins.hasAttr "extraConfig" vimConfig.programs.vim
  ) "vim should have extraConfig for custom key bindings")

  # Plugin presence tests using helper function
  (helpers.assertTest "vim-airline-plugin" (hasPluginByName "vim-airline")
    "vim airline plugin should be present"
  )

  (helpers.assertTest "vim-airline-themes-plugin" (hasPluginByName "vim-airline-themes")
    "vim airline-themes plugin should be present"
  )

  (helpers.assertTest "vim-tmux-navigator" (hasPluginByName "vim-tmux-navigator")
    "vim tmux-navigator plugin should be present"
  )

  # Config pattern tests using helper function
  (helpers.assertTest "vim-relative-line-numbers" (hasConfigPattern ".*set relativenumber.*")
    "vim should have relative line numbers enabled"
  )

  (helpers.assertTest "vim-leader-key-comma" (hasConfigPattern ".*let mapleader=\",\".*")
    "vim leader key should be set to comma"
  )

  (helpers.assertTest "vim-local-leader-key-space" (hasConfigPattern ".*let maplocalleader=\" \".*")
    "vim local leader key should be set to space"
  )

  (helpers.assertTest "vim-clipboard-paste-binding" (hasConfigPattern ".*nnoremap <Leader>,.*")
    "vim should have <Leader>, binding for paste from clipboard"
  )

  (helpers.assertTest "vim-clipboard-copy-binding" (hasConfigPattern ".*xnoremap <Leader>\\..*")
    "vim should have <Leader>. binding for copy to clipboard"
  )

  # Multiple pattern tests using helper function
  (helpers.assertTest "vim-window-navigation-bindings" (hasAllConfigPatterns [
    ".*nnoremap <C-h>.*"
    ".*nnoremap <C-j>.*"
    ".*nnoremap <C-k>.*"
    ".*nnoremap <C-l>.*"
  ]) "vim should have Ctrl+h/j/k/l bindings for window navigation")

  (helpers.assertTest "vim-buffer-navigation-bindings" (hasAllConfigPatterns [
    ".*nnoremap <tab>.*bnext.*"
    ".*nnoremap <S-tab>.*bprev.*"
  ]) "vim should have Tab/Shift+Tab bindings for buffer navigation")

  # Test that ignorecase is enabled
  (helpers.assertTest "vim-ignorecase-enabled" (
    vimConfigUsable && vimConfig.programs.vim.settings.ignorecase or false
  ) "vim should have ignorecase setting enabled")
]
