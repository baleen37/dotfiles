#!/usr/bin/env bash

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install more recent versions of some macOS tools.
brew install vim --with-override-system-vi

# zsh
brew install zsh 

# tmux
brew install tmux

# nvim
brew install nvim 


# docker
brew install docker 

# alt-tab
brew install alt-tab

# iterms2
brew install iterm2


# Remove outdated versions from the cellar.
brew cleanup
