# users/shared/home-manager.nix
#
# Shared Home Manager configuration for all users (baleen, jito.hello, etc.)
# Integrates all extracted tool configurations from modules/shared/ into unified config
#
# Tool configurations imported:
#   - git.nix: Git version control with aliases, LFS, and global gitignore
#   - vim.nix: Vim editor with plugins and keybindings
#   - zsh.nix: Zsh shell configuration and CLI shortcuts
#   - starship.nix: Starship prompt - fast, minimal, cross-shell prompt
#   - tmux.nix: Terminal multiplexer with session persistence
#   - claude-code.nix: Claude Code AI assistant configuration
#   - opencode.nix: OpenCode AI assistant configuration
#
# Packages included:
#   - Core utilities: wget, zip, tree, curl, jq, ripgrep, fzf
#   - Development tools: nodejs, python3, uv, direnv, pre-commit
#   - LSP servers: gopls, typescript-language-server, clang-tools, pyright
#   - Nix tools: nixfmt, statix, deadnix
#   - Cloud tools: act, gh, docker, awscli2
#   - Security: age, sops
#   - SSH tools: mosh, teleport
#   - Terminal: ghostty, htop, starship
#   - Fonts: noto-fonts-cjk-sans, cascadia-code, d2coding
#   - Media: ffmpeg
#   - Databases: postgresql, sqlite, redis, mysql80
#

{
  pkgs,
  inputs,
  currentSystemUser,
  isDarwin ? pkgs.stdenv.isDarwin,
  ...
}:

{
  # Import all extracted tool configurations
  imports = [
    ./git.nix
    ./vim.nix
    ./zsh.nix
    ./starship.nix
    ./tmux.nix
    ./claude-code.nix
    ./opencode.nix
    ./ghostty.nix
    ./hammerspoon.nix
    ./karabiner.nix
  ];

  # Home Manager configuration
  # Username is dynamically resolved from flake.nix (supports both baleen and jito.hello)
  home = {
    username = currentSystemUser;
    homeDirectory = if isDarwin then "/Users/${currentSystemUser}" else "/home/${currentSystemUser}";
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
      bun
      python3
      python3Packages.pipx
      virtualenv
      uv
      direnv
      pre-commit
      vscode
      postman

      # LSP servers
      lua-language-server
      gopls
      go
      typescript-language-server
      clang-tools
      pyright

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
      awscli2

      # Security tools
      age
      sops

      # SSH tools
      mosh
      teleport
      sshpass

      # Terminal apps

      # Fonts
      noto-fonts-cjk-sans
      cascadia-code
      d2coding

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

}
