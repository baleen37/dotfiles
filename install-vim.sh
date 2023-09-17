#!/usr/bin/env bash
set -euo pipefail

cd $(dirname $BASH_SOURCE)
BASE=$(pwd)
# Works on both Mac and GNU/Linux.
BASE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


# This detection only works for mac and linux.
if [ "$(uname)" == "Darwin" ]; then
  echo "Setting up $HOME/.bashrc"
  echo "source $DIR/_bashrc" >> $HOME/.bash_profile
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
  echo "Seeting up $HOME/.bash_profile"
  echo "source $DIR/_bashrc" >> $HOME/.bashrc
fi

export GIT_SSL_NO_VERIFY=true
mkdir -p ~/.vim/autoload
curl --insecure -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim

# vimrc
echo "Setting up $HOME/.vimrc"
mv -v ~/.vimrc ~/.vimrc.old 2> /dev/null
ln -sf $BASE/.vimrc ~/.vimrc

# nvim
echo "Setting up $HOME/.config/nvim/init.vim"
mkdir -p ~/.config/nvim/autoload
ln -sf $BASE/.vimrc ~/.config/nvim/init.vim
ln -sf ~/.vim/autoload/plug.vim ~/.config/nvim/autoload/

vim +PlugInstall +qall

