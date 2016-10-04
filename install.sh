#!/usr/bin/env bash

echo "Installing dotfiles"

source install/link.sh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# is osx
if [ "$(uname)" == "Darwin" ]; then
    source install/brew.sh

    source install/nvim.sh
fi

# install autoenv
git clone git://github.com/kennethreitz/autoenv.git ~/.autoenv

echo "Done."
