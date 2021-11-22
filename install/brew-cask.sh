# Install cask packages

apps=(
    docker
    alt-tab
    appcleaner
    alfred
    dropbox
    google-chrome
    iterm2
    visual-studio-code
    1password
    anki
    slack
    discord
    postman
    intellij-idea
)


brew install "${apps[@]}" --cask

mas install 869223134 # kakaotalk
mas install 441258766 # magnet
mas install 1529448980 # reeder 5
mas install 461788075 # movist
mas install 904280696 # things3


# font
brew tap homebrew/cask-fonts
brew install font-roboto-mono
