#!/bin/sh
# User Input Module for Apply Scripts
# Contains user information collection and validation

# Fetch username from the system
get_username() {
  local username=$(whoami)

  # If the username is 'nixos' or 'root', ask the user for their username
  if [ "$username" = "nixos" ] || [ "$username" = "root" ]; then
    _prompt "${YELLOW}You're running as $username. Please enter your desired username: ${NC}" username
  fi

  export USERNAME="$username"
}

# Get git configuration
get_git_config() {
  if command -v git >/dev/null 2>&1; then
    # Fetch email and name from git config
    export GIT_EMAIL=$(git config --get user.email)
    export GIT_NAME=$(git config --get user.name)

    # If either is empty, prompt for them
    if [ -z "$GIT_EMAIL" ]; then
      _prompt "${YELLOW}Please enter your email: ${NC}" GIT_EMAIL
    fi

    if [ -z "$GIT_NAME" ]; then
      _prompt "${YELLOW}Please enter your name: ${NC}" GIT_NAME
    fi
  else
    # Git not available, ask for info
    _prompt "${YELLOW}Please enter your email: ${NC}" GIT_EMAIL
    _prompt "${YELLOW}Please enter your name: ${NC}" GIT_NAME
  fi
}

# Collect all user information
collect_user_info() {
  get_username
  get_git_config

  # Display collected information
  _print "${GREEN}Collected user information:${NC}"
  _print "  Username: $USERNAME"
  _print "  Email: $GIT_EMAIL"
  _print "  Name: $GIT_NAME"
}
