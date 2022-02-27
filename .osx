#!/usr/bin/env bash


# Close any open System Preferences panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Preferences" to quit'

#########################################################
# Dock
#########################################################
# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.Dock autohide-delay -float 0 && killall Dock

# Set to Dock icon size
defaults write com.apple.dock "tilesize" -int "36" && killall Dock

defaults write -g ApplePressAndHoldEnabled -bool false

#########################################################
# Keyboard
#########################################################
defaults write -g KeyRepeat -int 3
defaults write -g InitialKeyRepeat -int 15

# Disable press-and-hold for keys in favour of key repeat
defaults write -g ApplePressAndHoldEnabled -bool false


#########################################################
# Trackpad
#########################################################
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad FirstClickThreshold -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad SecondClickThreshold -int 0

#########################################################
# Intellij
#########################################################
defaults write com.jetbrains.intellij ApplePressAndHoldEnabled -bool false
defaults write com.jetbrains.intellij.ce ApplePressAndHoldEnabled -bool false

#########################################################
# iTerm2
#########################################################
# Specify the preferences directory
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/dotfiles/osx"
# Tell iTerm2 to use the custom preferences in the directory
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

#########################################################
# Spotlight
#########################################################
# massively increase virtualized macOS by disabling spotlight.
sudo mdutil -i off -a

