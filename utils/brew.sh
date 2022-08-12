#!/usr/bin/env bash

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

apps=(
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
    nvim
    yarn
    tfenv
    awscli
    ripgrep
)

brew install "${apps[@]}"

# fzf key binding
$(brew --prefix)/opt/fzf/install

# universal-ctags
brew tap universal-ctags/universal-ctags
brew install --HEAD universal-ctags

# nvm
nvm install 14
nvm install 16

# ruby
brew install rbenv ruby-build
rbenv install $(rbenv install -l | grep -v - | tail -1) # install ruby latest

# Create
gem install gem-ctags
gem ctags

# Remove outdated versions from the cellar.
brew cleanup
