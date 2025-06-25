{ pkgs }:

with pkgs; [
  # General packages for development and system management
  wget
  zip

  # Cloud-related tools and SDKs
  docker
  docker-compose
  act
  gh

  # Infrastructure as Code
  # tfenv              # Terraform version manager (from tfenv-nix flake) - temporarily disabled due to API rate limit
  terraform          # Infrastructure as Code tool
  terraform-ls       # Terraform Language Server
  terragrunt         # Terraform wrapper for DRY configurations
  tflint             # Terraform linter

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

  #nodejs
  nodejs_22

  # Terminal applications
  wezterm

  # Development tools
  direnv
  claude-code
  pre-commit

  # Python packages
  python3
  python3Packages.pipx
  virtualenv
  uv
]
