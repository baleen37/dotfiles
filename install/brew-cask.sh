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
)

brew install "${apps[@]}" --cask
