{ pkgs }:

with pkgs; let
  # Custom karabiner-elements version 14
  karabiner-elements-14 = karabiner-elements.overrideAttrs (oldAttrs: {
    version = "14.13.0";
    src = fetchurl {
      url = "https://github.com/pqrs-org/Karabiner-Elements/releases/download/v14.13.0/Karabiner-Elements-14.13.0.dmg";
      sha256 = "1g3c7jb0q5ag3ppcpalfylhq1x789nnrm767m2wzjkbz3fi70ql2"; # pragma: allowlist secret
    };
  });
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
    gnumake # GNU make build automation tool
    cmake # Cross-platform build system generator
    home-manager # Nix-based user environment management
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

  # Database tools
  databaseTools = [
    postgresql # Object-relational database system
    sqlite # Lightweight SQL database engine
  ];

  # Productivity and utility applications
  productivityTools = [
    bc # Command-line calculator
    syncthing # Continuous file synchronization
    karabiner-elements-14 # Advanced keyboard customizer for macOS (version 14)
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
++ databaseTools
++ productivityTools
