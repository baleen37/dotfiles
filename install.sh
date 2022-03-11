#/bin/bash

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Bunch of symlinks
ln -sfv "$DOTFILES_DIR/.zshrc" ~
ln -sfv "$DOTFILES_DIR/.tmux.conf" ~
ln -sfv "$DOTFILES_DIR/.gitconfig" ~
ln -sfv "$DOTFILES_DIR/.gitignore_global" ~
ln -sfv "$DOTFILES_DIR/.aliases" ~
ln -sfv "$DOTFILES_DIR/.vimrc" ~
ln -sfv "$DOTFILES_DIR/.ideavimrc" ~
ln -sfv "$DOTFILES_DIR/.config/nvim/init.vim" ~/.config/nvim

# Package managers & packages
. "$DOTFILES_DIR/utils/brew.sh"
. "$DOTFILES_DIR/utils/misc.sh"
. "$DOTFILES_DIR/utils/osx.sh"

if [ "$(uname)" == "Darwin" ]; then
  . "$DOTFILES_DIR/utils/brew-cask.sh"
fi
