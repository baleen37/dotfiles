# Vim Editor Configuration
#
# Extracted from modules/shared/programs/vim.nix
#
# Features:
#   - vim-airline: Status line theme (bubblegum theme, Powerline fonts)
#   - vim-tmux-navigator: Seamless navigation between Tmux panes
#   - yank: Clipboard integration
#
# Key Settings:
#   - Line numbers: Relative line numbers + current line number
#   - Search: Incremental search, ignore case
#   - Tab/Space: 2-space indent, convert tabs to spaces
#   - Backup: No backup files, swap files in ~/.config/vim/swap
#   - Clipboard: autoselect mode
#
# Key Bindings:
#   - Leader: Space
#   - LocalLeader: , (comma)
#   - <Leader>,: Paste from clipboard
#   - <Leader>.: Copy to clipboard
#   - <Leader>q: Close window
#   - Ctrl+h/j/k/l: Navigate split windows
#   - Tab/Shift+Tab: Navigate buffers
#

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.programs.vim;
in
{
  options.modules.programs.vim.enable = lib.mkEnableOption "Vim editor configuration";

  config = lib.mkIf cfg.enable {
    programs.vim = {
      enable = true;

      plugins = with pkgs.vimPlugins; [
        vim-airline
        vim-airline-themes
        vim-tmux-navigator
      ];

      settings = {
        ignorecase = true;
      };

      extraConfig = builtins.readFile ./vim-common.vim;
    };
  };
}
