#!/usr/bin/env bash

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

apps=(
    nvim
    git
    tmux
    tree
    vim
    wget
    mas
)

brew install "${apps[@]}"

# Remove outdated versions from the cellar.
brew cleanup
