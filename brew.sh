#!/usr/bin/env bash

# Install command-line tools using Homebrew.
if test ! $(which brew); then
    echo "Installing homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed 

# Install `wget` with IRI support.
brew install wget

# Install GnuPG to enable PGP-signing commits.
brew install gnupg


# Install more recent versions of some macOS tools.
brew install vim
brew install nvim
brew install grep
brew install openssh
brew install screen
brew install php
brew install gmp


# font
brew tap homebrew/cask-fonts
brew install font-roboto-mono


# Install some CTF tools; see https://github.com/ctfs/write-ups.
brew install aircrack-ng
brew install bfg
brew install binutils
brew install binwalk
brew install cifer
brew install dex2jar
brew install dns2tcp
brew install fcrackzip
brew install foremost
brew install hashpump
brew install hydra
brew install john
brew install knock
brew install netpbm
brew install nmap
brew install pngcheck
brew install socat
brew install sqlmap
brew install tcpflow
brew install tcpreplay
brew install tcptrace
brew install ucspi-tcp # `tcpserver` etc.
brew install xpdf
brew install xz


# Install other useful binaries.
brew install ack
#brew install exiv2
brew install git
brew install git-lfs
brew install gs
brew install imagemagick
brew install lua
brew install lynx
brew install p7zip
brew install pigz
brew install pv
brew install rename
brew install rlwrap
brew install ssh-copy-id
brew install tree
brew install vbindiff
brew install zopfli
brew install tmux
brew install wget
brew install nvm
brew install npm
brew install pyenv
brew install pyenv-virtualenv
brew install awscli

# fzf key binding
brew install fzf
$(brew --prefix)/opt/fzf/install


# Install cask packages
brew install docker
brew install alt-tab
brew install appcleaner
brew install alfred
brew install dropbox
brew install google-chrome
brew tap homebrew/cask-versions && brew install --cask google-chrome-canary
brew install iterm2
brew install visual-studio-code
brew install 1password
brew install anki
brew install discord
brew install postman
brew install intellij-idea
brew install datagrip
brew install slack
brew install notion --appdir ~/Applications
brew install obsidian
brew install hammerspoon

## jdk
brew tap AdoptOpenJDK/openjdk
brew install --cask adoptopenjdk11
brew install --cask adoptopenjdk17

# Remove outdated versions from the cellar.
brew cleanup
