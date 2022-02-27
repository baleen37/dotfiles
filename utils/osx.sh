#/bin/bash


# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.Dock autohide-delay -float 0 && killall Dock

# Set to Dock icon size
defaults write com.apple.dock "tilesize" -int "36" && killall Dock

# Specify the preferences directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/dotfiles/iterm2"

# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

defaults write -g ApplePressAndHoldEnabled -bool false

# Intellij
defaults write com.jetbrains.intellij ApplePressAndHoldEnabled -bool false
defaults write com.jetbrains.intellij.ce ApplePressAndHoldEnabled -bool false
