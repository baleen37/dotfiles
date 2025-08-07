#!/bin/sh
# UI Utilities Module for Apply Scripts
# Contains color codes and UI helper functions

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Custom print function with OS-specific handling
_print() {
  if [ "$(uname)" = "Darwin" ]; then
    echo -e "$1"
  else
    echo "$1"
  fi
}

# Custom prompt function for user input
_prompt() {
  local message="$1"
  local variable="$2"

  _print "$message"
  read -r $variable
}

# Ask for GitHub star (platform-specific)
ask_for_star() {
  local OS=$(uname)

  _print "${YELLOW}Would you like to support my work by starring my GitHub repo? yes/no [yes]: ${NC}"
  local response
  read -r response
  response=${response:-yes} # Set default response to 'yes' if input is empty

  if echo "$response" | grep -qi "^y"; then
    if [ "$OS" = "Darwin" ]; then
      open "https://github.com/dustinlyons/nixos-config"
    else
      xdg-open "https://github.com/dustinlyons/nixos-config"
    fi
  fi
}
