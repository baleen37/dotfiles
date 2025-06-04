{ pkgs }:

with pkgs; [
  # General packages for development and system management
  wget
  zip

  # Cloud-related tools and SDKs
  docker
  docker-compose
  act

  # Password management
  _1password-cli

  # Media-related packages
  ffmpeg

  # Text and terminal utilities
  htop
  jq
  ripgrep
  tree
  tmux
  unrar
  unzip
  zsh-powerlevel10k
  fzf

  # Terminal applications
  wezterm

  # Python packages
  python3
  virtualenv
]
