#!/usr/bin/env bash

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Install more recent versions of some macOS tools.
brew install vim --with-override-system-vi
# nvim
brew install nvim 

# zsh
brew install zsh 

# tmux
brew install tmux


brew install --cask docker 
brew install --cask alt-tab
brew install --cask iterm2
brew install --cask appcleaner
brew install --cask karabiner-elements

# Remove outdated versions from the cellar.
brew cleanup
