#!/usr/bin/env bash

DOTFILES=$HOME/.dotfiles

echo -e "\n\ninstalling to ~/.config"

if [ ! -d $HOME/.config ]; then
    echo "creating ~/.config"
    mkdir -p $HOME/.config
fi


echo -e "\n\ninstalling to ~/.config"
echo "=============================="
if [ ! -d $HOME/.config ]; then
    echo "Creating ~/.config"
    mkdir -p $HOME/.config
fi

for config in $DOTFILES/config/*; do
    target=$HOME/.config/$( basename $config )
    if [ -e $target ]; then
        echo "~${target#$HOME} already exists... Skipping."
    else
        echo "Creating symlink for $config"
        ln -s $config $target
    fi
done

echo -e "\n\nCreating symlinks"
echo "=============================="
SYMLINKS=( "$HOME/.vimrc:$DOTFILES/vimrc" 
				"$HOME/.zshrc:$DOTFILES/zshrc"
				"$HOME/.aliases:$DOTFILES/aliases" )

for file in "${SYMLINKS[@]}" ; do
    KEY=${file%%:*}
    VALUE=${file#*:}
    if [ -e ${KEY} ]; then
        echo "${KEY} already exists... skipping"
    else
        echo "Creating symlink for $KEY"
        ln -s ${VALUE} ${KEY}
    fi
done
