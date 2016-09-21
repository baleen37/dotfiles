#!/usr/bin/env bash

echo "Installing dotfiles"

source install/link.sh

# is osx
if [ "$(uname)" == "Darwin" ]; then
    source install/brew.sh

    source install/nvim.sh
fi

echo "Done."
