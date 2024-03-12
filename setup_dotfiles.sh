#!/usr/bin/env bash
set -euo pipefail
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Setting up symlinks"
ln -sfv "$DOTFILES_DIR/.zshrc" ~
ln -sfv "$DOTFILES_DIR/.tmux.conf" ~
ln -sfv "$DOTFILES_DIR/.gitconfig" ~
ln -sfv "$DOTFILES_DIR/.gitignore_global" ~
ln -sfv "$DOTFILES_DIR/.aliases" ~
ln -sfv "$DOTFILES_DIR/.vimrc" ~
ln -sfv "$DOTFILES_DIR/.ideavimrc" ~
ln -sfv "$DOTFILES_DIR/.ctags.d" ~
ln -sfv "$DOTFILES_DIR/bin" ~
ln -sfv "$DOTFILES_DIR/config/nvim" ~/.config/nvim
ln -sfv "$DOTFILES_DIR/.hammerspoon" ~/.hammerspoon
ln -sfv "~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/wiki" ~
