#!/usr/bin/env bash
set -euo pipefail

echo "Setting up symlinks"
ln -sfv ".zshrc" ~
ln -sfv ".tmux.conf" ~
ln -sfv ".gitconfig" ~
ln -sfv ".gitignore_global" ~
ln -sfv ".aliases" ~
ln -sfv ".vimrc" ~
ln -sfv ".ideavimrc" ~
ln -sfv ".ctags.d" ~
ln -sfv "bin" ~
ln -sfv ".config/nvim" ~/.config/nvim
ln -sfv "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/wiki" ~
