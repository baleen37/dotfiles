#!/bin/sh

if test ! $(which brew); then
    echo "Installing brew"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

echo -e "\n\ninstalling homebrew packages..."

brew install git
brew install fzf
brew install macvim --override-system-vim

# managing python package
brew install pyenv
brew install pyenv-virtualenv
brew install autoenv

brew install neovim/neovim/neovim
brew install pidcat
