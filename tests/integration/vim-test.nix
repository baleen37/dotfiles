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
  pluginHelpers = import ../lib/plugin-test-helpers.nix { inherit pkgs lib; inherit helpers; };

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

  # Helper function to check if a plugin exists by pname (with vimConfigUsable guard)
  hasPluginByName =
    pname:
    vimConfigUsable && pluginHelpers.hasPluginByName vimConfig.programs.vim.plugins pname;

  # Helper function to check if extraConfig contains a pattern (with vimConfigUsable guard)
  hasConfigPattern =
    pattern: vimConfigUsable && pluginHelpers.hasConfigPattern vimConfig.programs.vim.extraConfig pattern;

  # Helper function to check multiple config patterns (all must match)
  hasAllConfigPatterns =
    patterns: vimConfigUsable && pluginHelpers.hasAllConfigPatterns vimConfig.programs.vim.extraConfig patterns;

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

  # Backup and swap directory configuration tests
  (helpers.assertTest "vim-backup-disabled" (hasConfigPattern ".*set nobackup.*")
    "vim should have backup disabled")

  (helpers.assertTest "vim-swap-disabled" (hasConfigPattern ".*set noswapfile.*")
    "vim should have swap files disabled")

  (helpers.assertTest "vim-backupdir-config" (hasConfigPattern ".*set backupdir=.*")
    "vim should have backup directory configured")

  (helpers.assertTest "vim-directory-config" (hasConfigPattern ".*set directory=.*")
    "vim should have swap directory configured")

  # Encoding and terminal settings tests
  (helpers.assertTest "vim-encoding-utf8" (hasConfigPattern ".*set encoding=utf-8.*")
    "vim should use UTF-8 encoding")

  (helpers.assertTest "vim-clipboard-autoselect" (hasConfigPattern ".*set clipboard=autoselect.*")
    "vim should have clipboard autoselect enabled")

  # Display and cursor settings tests
  (helpers.assertTest "vim-cursorline-enabled" (hasConfigPattern ".*set cursorline.*")
    "vim should have cursor line highlighting enabled")

  (helpers.assertTest "vim-autocmd-insert-cursor" (hasAllConfigPatterns [
    ".*autocmd InsertEnter.*"
    ".*autocmd InsertLeave.*"
  ]) "vim should have cursor mode change on insert enter/leave")

  # Key binding edge cases tests
  (helpers.assertTest "vim-display-line-movement" (hasAllConfigPatterns [
    ".*nnoremap j gj.*"
    ".*nnoremap k gk.*"
  ]) "vim should move by display lines when wrapping")

  (helpers.assertTest "vim-yank-line-binding" (hasConfigPattern ".*nnoremap Y y\\$.*")
    "vim should have Y binding to yank to end of line")

  (helpers.assertTest "vim-sudo-write-binding" (hasConfigPattern ".*cmap w!! w !sudo tee.*")
    "vim should have sudo write binding")

  # Status bar and airline theme tests
  (helpers.assertTest "vim-laststatus" (hasConfigPattern ".*set laststatus=2.*")
    "vim should always show status line")

  (helpers.assertTest "vim-airline-theme" (hasConfigPattern ".*g:airline_theme.*")
    "vim should have airline theme configured")

  (helpers.assertTest "vim-airline-powerline-fonts" (hasConfigPattern ".*g:airline_powerline_fonts.*")
    "vim should have powerline fonts enabled for airline")
]
