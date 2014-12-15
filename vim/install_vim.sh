#!/bin/bash

echo "installing on vim..."

cp .vimrc ~/
cp -rf .vim ~/

git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# for installing vim plugin
vim +PluginClean +qall
vim +PluginInstall +qall
