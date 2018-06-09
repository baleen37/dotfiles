#!/usr/bin/env bash

echo "Installing dotfiles"

source install/link.sh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# is osx
source install/brew.sh

source install/vim.sh

# disable showing alphabet tooltips if long press keyboard
defaults write -g ApplePressAndHoldEnabled -bool false

# install autoenv
git clone git://github.com/kennethreitz/autoenv.git ~/.autoenv

echo "Done."
