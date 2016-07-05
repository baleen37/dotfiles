#!/bin/bash

#install mac vim
brew install macvim --override-system-vim

git clone https://github.com/Valloric/YouCompleteMe.git ~/.vim/bundle/YouCompleteMe
cd ~/.vim/bundle/YouCompleteMe
git submodule update --init --recursive
./install.sh --clang-completer --tern-completer

# Add git config vim path
git config --global core.editor `which vim`
