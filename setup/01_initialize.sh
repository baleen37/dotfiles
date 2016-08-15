#!/bin/bash

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

\curl -sSL https://get.rvm.io | bash -s stable --ruby

ruby -e "$(wget -O- https://raw.github.com/Homebrew/linuxbrew/go/install)"

brew update
brew install tmux
brew install swfitlint

# powerful reverse search bash
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install
