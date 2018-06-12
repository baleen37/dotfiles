#!/usr/bin/env bash

echo "Installing dotfiles"

cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

BASE=$(pwd)
for rc in *rc tmux.conf gitgnore; do
  mkdir -pv bak
  [ -e ~/."$rc" ] && mv -v ~/."$rc" bak/."$rc"
  ln -sfv "$BASE/$rc" ~/."$rc"
done

if [ "$(uname -s)" = 'Darwin' ]; then
  # Homebrew
  [ -z "$(which brew)" ] &&
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  echo "Updating homebrew"
  brew install \
    vim zsh ruby python go ctags

    # disable showing alphabet tooltips if long press keyboard
  defaults write -g ApplePressAndHoldEnabled -bool false
fi

git config --global user.email "baleen37@gmail.com"
git config --global user.name "Jiho Lee"

echo "Done."
