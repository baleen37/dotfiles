{ pkgs }:

with pkgs; let
  # Core system utilities - essential tools for basic system operations
  coreSystemTools = [
    wget          # HTTP/FTP download utility
    zip           # Archive creation utility
    unzip         # Archive extraction utility
    unrar         # RAR archive extraction
    tree          # Directory structure visualization
  ];

  # Terminal and text processing utilities
  terminalUtilities = [
    htop          # Interactive process viewer
    jq            # JSON processor and query tool
    ripgrep       # Fast text search tool (rg command)
    tmux          # Terminal multiplexer for session management
    fzf           # Fuzzy finder for files and commands
    zsh-powerlevel10k  # Enhanced Zsh prompt theme
  ];

  # Development tools and programming languages
  developmentTools = [
    nodejs_22     # JavaScript runtime (LTS version)
    python3       # Python programming language
    python3Packages.pipx  # Install Python applications in isolated environments
    virtualenv    # Python virtual environment tool
    uv            # Fast Python package installer
    direnv        # Environment variable management per directory
    pre-commit    # Pre-commit hooks framework
    claude-code   # Claude AI development assistant
    gnumake       # GNU make build automation tool
    cmake         # Cross-platform build system generator
    home-manager  # Nix-based user environment management
  ];

  # Cloud and containerization tools
  cloudTools = [
    act           # Run GitHub Actions locally
    gh            # GitHub CLI tool
    docker        # Container platform
  ];

  # Infrastructure as Code (IaC) toolchain
  infrastructureTools = [
    # tfenv              # Terraform version manager (from tfenv-nix flake) - temporarily disabled due to API rate limit
    terraform     # Infrastructure as Code tool
    terraform-ls  # Terraform Language Server for IDE support
    terragrunt    # Terraform wrapper for DRY configurations
    tflint        # Terraform linter for best practices
  ];

  # Media processing tools
  mediaTools = [
    ffmpeg        # Video/audio processing and conversion
    fontconfig    # Font configuration and customization library
  ];

  # Terminal applications
  terminalApps = [
    # Terminal emulators moved to platform-specific configs (e.g., iTerm2 via Darwin casks)
  ];

  # Security and authentication tools
  securityTools = [
    yubikey-agent # YubiKey support for SSH and other applications
    keepassxc     # Cross-platform password manager
  ];

  # Database tools
  databaseTools = [
    postgresql    # Object-relational database system
    sqlite        # Lightweight SQL database engine
  ];

  # Productivity and utility applications
  productivityTools = [
    bc            # Command-line calculator
    google-chrome # Google Chrome web browser
    spotify       # Music streaming application
    syncthing     # Continuous file synchronization
  ];

in
  # Combine all package categories
  coreSystemTools
  ++ terminalUtilities
  ++ developmentTools
  ++ cloudTools
  ++ infrastructureTools
  ++ mediaTools
  ++ terminalApps
  ++ securityTools
  ++ databaseTools
  ++ productivityTools
