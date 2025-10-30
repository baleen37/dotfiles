# users/shared/home-manager.nix
#
# Shared Home Manager configuration for all users (baleen, jito, etc.)
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
#   - Nix tools: nixfmt, statix, deadnix, home-manager
#   - Cloud tools: act, gh, docker
#   - Security: yubikey-agent, keepassxc
#   - SSH tools: autossh, mosh, teleport
#   - Terminal: wezterm, htop, zsh-powerlevel10k
#   - Fonts: noto-fonts-cjk-sans, jetbrains-mono
#   - Media: ffmpeg
#   - Databases: postgresql, sqlite, redis, mysql80
#
# VERSION: 1.0.0 (Task 7 - Home Manager Integration)
# LAST UPDATED: 2025-10-26

{
  pkgs,
  lib,
  inputs,
  config,
  isWSL ? false,
  ...
}:

{
  # Import all extracted tool configurations
  imports = [
    ../baleen/git.nix
    ../baleen/vim.nix
    ../baleen/zsh.nix
    ../baleen/tmux.nix
    ../baleen/claude-code.nix
    ../baleen/hammerspoon.nix
    ../baleen/karabiner.nix
  ];

  # Home Manager configuration
  # Username and homeDirectory are set by the calling mkSystem function
  home = {
    stateVersion = "24.11";

    # Core system utilities
    packages =
      with pkgs;
      [
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
        home-manager
        gnumake
        cmake

        # AI/CLI tools
        claude-code
        opencode
        gemini-cli

        # Cloud tools
        act
        gh

        # Security tools
        yubikey-agent
        keepassxc

        # SSH tools
        autossh
        mosh
        teleport

        # Terminal apps
        wezterm

        # Fonts
        noto-fonts-cjk-sans
        jetbrains-mono

        # Media tools
        ffmpeg

        # Database tools
        postgresql
        sqlite
        redis
        mysql80

        # Productivity tools
        bc

        # Linux-specific packages (only on NixOS/Linux, not macOS)
      ]
      ++ lib.optionals (!pkgs.stdenv.isDarwin) [
        systemd
        util-linux
        file
        iotop
      ];
  };

  # XDG directories
  xdg.enable = true;

  # Linux-specific environment variables (only on NixOS/Linux, not macOS)
  home.sessionVariables = lib.mkIf (!pkgs.stdenv.isDarwin) {
    # Linux-specific environment settings
    XDG_CURRENT_DESKTOP = "none";
    XDG_SESSION_TYPE = "tty";
  };

  # Dotfiles symlinks
  home.file.".p10k.zsh" = {
    source = ../../config/p10k.zsh;
    force = true;
  };

  # Programs
  programs.home-manager.enable = true;
}
