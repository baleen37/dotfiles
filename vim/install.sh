#!/bin/bash

echo "Installing vim files..."

CURRENT_DIR=$(dirname $0)
TARGET_DIR=$HOME

cp $CURRENT_DIR/.vimrc $TARGET_DIR
cp -rp $CURRENT_DIR/.vim $TARGET_DIR

# Pathogen installation
git clone https://github.com/gmarik/Vundle.vim.git $TARGET_DIR/.vim/bundle/Vundle.vim

# for installing vim plugin
vim +PluginInstall +qall
