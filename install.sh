#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ohmyzsh
echo "Setting up ohmyzsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Bunch of symlinks
. "$DOTFILES_DIR/setup_dotfiles.sh"

echo "Setting up vim"
. "$DOTFILES_DIR/install-vim.sh"

# Package managers & packages
echo "Setting up package managers"
. "$DOTFILES_DIR/utils/brew.sh"
. "$DOTFILES_DIR/utils/misc.sh"

if [ "$(uname)" == "Darwin" ]; then
  . "$DOTFILES_DIR/utils/osx.sh"
  . "$DOTFILES_DIR/utils/brew-cask.sh"
fi
