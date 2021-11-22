#!/usr/bin/env bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

apps=(
    nvim
    git
    zsh
    tmux
    tree
    vim
    wget
    mas
    nvm
    npm
    pyenv
    svn
    fzf
)

brew install "${apps[@]}"

# fzf key binding
$(brew --prefix)/opt/fzf/install

# Remove outdated versions from the cellar.
brew cleanup
