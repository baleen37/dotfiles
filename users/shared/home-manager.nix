# users/shared/home-manager.nix
#
# Shared Home Manager configuration for all users (baleen, jito.hello, etc.)
# Integrates all extracted tool configurations from modules/shared/ into unified config
#
# Tool configurations imported:
#   - git.nix: Git version control with aliases, LFS, and global gitignore
#   - vim.nix: Vim editor with plugins and keybindings
#   - zsh.nix: Zsh shell with Powerlevel10k theme and CLI shortcuts
#   - tmux.nix: Terminal multiplexer with session persistence
#   - claude-code.nix: Claude Code AI assistant configuration
#
# Packages included:
#   - Core utilities: wget, zip, tree, curl, jq, ripgrep, fzf
#   - Development tools: nodejs, python3, uv, direnv, pre-commit
#   - Nix tools: nixfmt, statix, deadnix
#   - Cloud tools: act, gh, docker
#   - Security: yubikey-agent, keepassxc
#   - SSH tools: autossh, mosh, teleport
#   - Terminal: ghostty, htop, zsh-powerlevel10k
#   - Fonts: noto-fonts-cjk-sans, cascadia-code
#   - Media: ffmpeg
#   - Databases: postgresql, sqlite, redis, mysql80
#

{
  pkgs,
  lib,
  inputs,
  currentSystemUser,
  ...
}:

{
  # Import all extracted tool configurations
  imports = [
    ./git.nix
    ./vim.nix
    ./zsh.nix
    ./tmux.nix
    ./claude-code.nix
    ./hammerspoon.nix
    ./karabiner.nix
    ./ghostty.nix
    ./rectangle.nix
  ];

  # Home Manager configuration
  # Username is dynamically resolved from flake.nix (supports both baleen and jito.hello)
  home = {
    username = currentSystemUser;
    homeDirectory =
      if pkgs.stdenv.isDarwin then "/Users/${currentSystemUser}" else "/home/${currentSystemUser}";
    stateVersion = "24.11";

    # Core system utilities
    packages = with pkgs; [
      # Core system tools
      wget
      curl
      zip
      unzip
      tree

      # Terminal utilities
      htop
      jq
      ripgrep
      fd
      bat
      eza
      fzf

      # Development tools
      nodejs_22
      python3
      python3Packages.pipx
      virtualenv
      uv
      direnv
      pre-commit
      vscode

      # Nix tools
      nixfmt
      statix
      deadnix
      gnumake
      cmake

      # AI/CLI tools
      claude-code
      opencode
      gemini-cli


      # Cloud tools
      act
      gh
      docker
      docker-compose

      # Security tools

      # SSH tools
      mosh
      teleport

      # Terminal apps

      # Fonts
      noto-fonts-cjk-sans
      cascadia-code

      # Media tools
      ffmpeg

      # Database tools
      postgresql
      sqlite
      redis
      mysql80

      # Productivity tools
      bc
    ];
  };

  # XDG directories
  xdg.enable = true;

  # Dotfiles symlinks
  home.file.".p10k.zsh" = {
    source = .config/p10k.zsh;
    force = true;
  };

}
