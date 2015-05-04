#!/bin/bash

cd "$(dirname "${BASH_SOURCE}")";

git pull origin master;

# syncronize config file for initaliztion
rsync  --exclude "README.md" --exclude "bootstrap.sh" --exclude ".git/" -arv . ~;
source ~/.bash_profile;


# install Vundle
git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +BundleInstall +qall #2&> /dev/null
