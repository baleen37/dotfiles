{ pkgs }:

with pkgs; [
  # General packages for development and system management
  wget
  zip

  # Cloud-related tools and SDKs
  docker
  docker-compose

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

  # Terminal applications
  wezterm

  # Python packages
  python3
  virtualenv
]
