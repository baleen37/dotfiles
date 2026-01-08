# Mock Configuration Helpers
#
# Provides reusable mock configuration generators for testing.
# Eliminates duplication of mock config creation across test files.

{
  pkgs,
  lib,
}:

rec {
  # Create an empty mock configuration
  #
  # Returns: Minimal configuration with no settings
  #
  # Example:
  #   mkEmptyConfig
  mkEmptyConfig = {
    home = {
      username = "testuser";
      homeDirectory = "/home/testuser";
    };
  };

  # Create a mock configuration with only home directory
  #
  # Parameters:
  #   - homeDirectory: The home directory path (defaults to platform-specific)
  #
  # Returns: Configuration with home directory set
  #
  # Example:
  #   mkHomeConfig "/Users/test"
  mkHomeConfig = homeDirectory:
    {
      home = {
        username = "testuser";
        inherit homeDirectory;
      };
    };

  # Create a mock configuration for Darwin (macOS)
  #
  # Parameters:
  #   - username: The username (defaults to "testuser")
  #
  # Returns: Configuration with Darwin-specific home directory
  #
  # Example:
  #   mkDarwinHomeConfig "testuser"
  mkDarwinHomeConfig = username:
    {
      home = {
        inherit username;
        homeDirectory = "/Users/${username}";
      };
    };

  # Create a mock configuration for Linux
  #
  # Parameters:
  #   - username: The username (defaults to "testuser")
  #
  # Returns: Configuration with Linux-specific home directory
  #
  # Example:
  #   mkLinuxHomeConfig "testuser"
  mkLinuxHomeConfig = username:
    {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
      };
    };

  # Create a platform-aware mock configuration
  #
  # Parameters:
  #   - username: The username (defaults to "testuser")
  #
  # Returns: Configuration with platform-specific home directory
  #
  # Example:
  #   mkPlatformHomeConfig "testuser"
  mkPlatformHomeConfig = username:
    if pkgs.stdenv.isDarwin then
      mkDarwinHomeConfig username
    else
      mkLinuxHomeConfig username;

  # Create a mock configuration with custom settings
  #
  # Parameters:
  #   - username: The username (defaults to "testuser")
  #   - homeDirectory: The home directory (optional, defaults to platform-specific)
  #   - extraConfig: Additional configuration to merge (optional)
  #
  # Returns: Configuration with custom settings
  #
  # Example:
  #   mkCustomConfig "testuser" "/custom/home" { some.setting = true; }
  mkCustomConfig =
    username: homeDirectory: extraConfig:
    let
      baseConfig = {
        home = {
          inherit username;
          inherit homeDirectory;
        };
      };
    in
    lib.recursiveUpdate baseConfig (if extraConfig != null then extraConfig else {});

  # Create a mock configuration with currentSystemUser
  #
  # Parameters:
  #   - username: The username (defaults to "testuser")
  #
  # Returns: Configuration suitable for modules that require currentSystemUser
  #
  # Example:
  #   mkSystemUserConfig "testuser"
  mkSystemUserConfig = username:
    let
      homeDir = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    in
    {
      currentSystemUser = username;
      home = {
        inherit username;
        homeDirectory = "${homeDir}/${username}";
      };
    };

  # Create a mock Home Manager configuration
  #
  # Parameters:
  #   - username: The username (defaults to "testuser")
  #   - packages: List of packages to include (optional)
  #
  # Returns: Mock Home Manager configuration structure
  #
  # Example:
  #   mkHomeManagerConfig "testuser" [ pkgs.git pkgs.vim ]
  mkHomeManagerConfig =
    username: packages:
    let
      homeDir = if pkgs.stdenv.isDarwin then "/Users" else "/home";
    in
    {
      home = {
        inherit username;
        homeDirectory = "${homeDir}/${username}";
        stateVersion = "23.11";
        packages = if packages != null then packages else [ ];
      };
    };

  # Create a mock Git configuration
  #
  # Parameters:
  #   - userName: Git user name (optional)
  #   - userEmail: Git user email (optional)
  #
  # Returns: Mock Git configuration structure
  #
  # Example:
  #   mkGitConfig "Test User" "test@example.com"
  mkGitConfig = userName: userEmail:
    {
      programs = {
        git = {
          enable = true;
          userName = if userName != null then userName else "Test User";
          userEmail = if userEmail != null then userEmail else "test@example.com";
        };
      };
    };

  # Create a mock Vim configuration
  #
  # Parameters:
  #   - plugins: List of Vim plugins (optional)
  #
  # Returns: Mock Vim configuration structure
  #
  # Example:
  #   mkVimConfig [ pkgs.vimPlugins.vim-airline ]
  mkVimConfig = plugins:
    {
      programs = {
        vim = {
          enable = true;
          plugins = if plugins != null then plugins else [ ];
        };
      };
    };

  # Create a mock Tmux configuration
  #
  # Parameters:
  #   - plugins: List of Tmux plugins (optional)
  #   - extraConfig: Additional Tmux configuration (optional)
  #
  # Returns: Mock Tmux configuration structure
  #
  # Example:
  #   mkTmuxConfig [ pkgs.tmuxPlugins.sensible ] "set -g mode-keys vi"
  mkTmuxConfig = plugins: extraConfig:
    {
      programs = {
        tmux = {
          enable = true;
          plugins = if plugins != null then plugins else [ ];
          inherit extraConfig;
        };
      };
    };

  # Create a mock Starship configuration
  #
  # Parameters:
  #   - format: Prompt format string (optional)
  #   - settings: Additional Starship settings (optional)
  #
  # Returns: Mock Starship configuration structure
  #
  # Example:
  #   mkStarshipConfig "$directory$git_branch" { username.disabled = true; }
  mkStarshipConfig = format: settings:
    {
      programs = {
        starship = {
          enable = true;
          settings = {
            format = if format != null then format else "$directory$git_branch$git_status$nix_shell$python$character";
          } // (if settings != null then settings else {});
        };
      };
    };

  # Create a mock Zsh configuration
  #
  # Parameters:
  #   - enableIntegration: Enable Zsh integration for tools (optional)
  #   - initExtra: Additional Zsh initialization (optional)
  #
  # Returns: Mock Zsh configuration structure
  #
  # Example:
  #   mkZshConfig true "export TEST_VAR=1"
  mkZshConfig = enableIntegration: initExtra:
    {
      programs = {
        zsh = {
          enable = true;
          enableGlobalCompInit = false;
          autosuggestion.enable = true;
          syntaxHighlighting.enable = true;
          initExtra = if initExtra != null then initExtra else "";
        } // (
          if enableIntegration then
            {
              initExtraBeforeCompInit = "ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'";
            }
          else
            {}
        );
      };
    };
}
