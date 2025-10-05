# Shared Package Definitions
#
# 모든 플랫폼(macOS, NixOS)에서 공통으로 설치되는 패키지 목록을 정의합니다.
# 카테고리별로 분류된 패키지들을 조합하여 최종 패키지 리스트를 반환합니다.
#
# 구조:
#   - 코어 시스템 도구: wget, zip, tree 등 기본 유틸리티
#   - 터미널 도구: htop, jq, ripgrep, tmux 등 CLI 도구
#   - 개발 도구: nodejs, python, direnv 등 개발 환경
#   - 클라우드 도구: docker, gh, act 등 DevOps 도구
#   - 미디어 도구: ffmpeg, 폰트 패키지
#   - 보안 도구: yubikey-agent, keepassxc
#   - 데이터베이스: postgresql, redis, mysql 등
#
# 사용:
#   modules/shared/home-manager.nix에서 import하여 home.packages로 설치

{ pkgs }:

with pkgs;
let
  # Core system utilities - essential tools for basic system operations
  coreSystemTools = [
    wget # HTTP/FTP download utility
    zip # Archive creation utility
    unzip # Archive extraction utility
    tree # Directory structure visualization
  ];

  # Terminal and text processing utilities
  terminalUtilities = [
    htop # Interactive process viewer
    jq # JSON processor and query tool
    ripgrep # Fast text search tool (rg command)
    tmux # Terminal multiplexer for session management
    fzf # Fuzzy finder for files and commands
    zsh-powerlevel10k # Enhanced Zsh prompt theme
  ];

  # Development tools and programming languages
  developmentTools = [
    nodejs_22 # JavaScript runtime (LTS version)
    python3 # Python programming language
    python3Packages.pipx # Install Python applications in isolated environments
    virtualenv # Python virtual environment tool
    uv # Fast Python package installer
    (pkgs.writeShellScriptBin "claude-monitor" ''
      ${uv}/bin/uv tool run claude-monitor "$@"
    '') # Claude monitor tool wrapper
    direnv # Environment variable management per directory
    pre-commit # Pre-commit hooks framework
    gemini-cli # Command-line interface for Gemini
    claude-code # AI code generation tool
    nixfmt # Official formatter for Nix code
    gnumake # GNU make build automation tool
    cmake # Cross-platform build system generator
    home-manager # Nix-based user environment management
    bats # Bash Automated Testing System for shell script testing
    (pkgs.buildGoModule {
      pname = "claude-hooks";
      version = "0.1.0";
      src = ../../config/claude/hooks-go;
      vendorHash = null; # No external dependencies
    }) # Claude Code hooks for git commit validation and message cleaning
  ];

  # Cloud and containerization tools
  cloudTools = [
    act # Run GitHub Actions locally
    gh # GitHub CLI tool
    docker # Container platform
  ];

  # Infrastructure as Code (IaC) toolchain
  infrastructureTools = [
  ];

  # Media processing tools
  mediaTools = [
    ffmpeg # Video/audio processing and conversion
    fontconfig # Font configuration and customization library
  ];

  # Font packages
  fontTools = [
    noto-fonts-cjk-sans # Noto Sans CJK fonts for Korean, Japanese, Chinese
    jetbrains-mono # JetBrains Mono programming font
  ];

  # Terminal applications
  terminalApps = [
    wezterm # Modern GPU-accelerated terminal emulator
  ];

  # Security and authentication tools
  securityTools = [
    yubikey-agent # YubiKey support for SSH and other applications
    keepassxc # Cross-platform password manager
  ];

  # SSH connection tools
  sshTools = [
    autossh # Automatically restart SSH sessions and tunnels
    mosh # Mobile shell for better SSH connections over unreliable networks
    teleport # Secure access for infrastructure
  ];

  # Database tools
  databaseTools = [
    postgresql # Object-relational database system
    sqlite # Lightweight SQL database engine
    redis # Redis command-line client and tools
    mysql80 # MySQL client and command-line utilities
  ];

  # Productivity and utility applications
  productivityTools = [
    bc # Command-line calculator
    syncthing # Continuous file synchronization
  ];

in
# Combine all package categories
coreSystemTools
++ terminalUtilities
++ developmentTools
++ cloudTools
++ infrastructureTools
++ mediaTools
++ fontTools
++ terminalApps
++ securityTools
++ sshTools
++ databaseTools
++ productivityTools
