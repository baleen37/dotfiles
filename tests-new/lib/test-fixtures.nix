{ pkgs, lib ? pkgs.lib }:
let
  testHelpers = import ./test-helpers-v2.nix { inherit pkgs lib; };

  # Base fixture structure
  baseFixture = {
    name = "base-fixture";
    version = "1.0.0";
    created = "$(date -Iseconds)";
    platform = testHelpers.platform.systemId;
  };

  # Configuration file fixtures
  configFixtures = {
    # Mock flake.nix with various configurations
    mockFlakeBasic = {
      content = ''
        {
          description = "Mock dotfiles system";
          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
            darwin.url = "github:LnL7/nix-darwin";
            home-manager.url = "github:nix-community/home-manager";
          };
          outputs = { self, nixpkgs, darwin, home-manager }: {
            darwinConfigurations.testSystem = darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              modules = [ ./modules/darwin ];
            };
          };
        }
      '';
      filename = "flake.nix";
    };

    mockFlakeWithOverrides = {
      content = ''
        {
          description = "Mock dotfiles with overlays";
          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
            darwin.url = "github:LnL7/nix-darwin";
          };
          outputs = { self, nixpkgs, darwin }: {
            overlays.default = final: prev: {
              customPackage = prev.hello;
            };
            darwinConfigurations.testSystem = darwin.lib.darwinSystem {
              system = "aarch64-darwin";
              modules = [
                { nixpkgs.overlays = [ self.overlays.default ]; }
              ];
            };
          };
        }
      '';
      filename = "flake.nix";
    };

    # Mock CLAUDE.md configuration
    mockClaudeConfig = {
      content = ''
        # Claude Configuration

        ## Instructions
        - Follow TDD principles
        - Write comprehensive tests
        - Maintain code quality

        ## Commands
        Available commands in modules/shared/config/claude/commands/:
        - plan.md: Project planning
        - create-pr.md: Pull request creation
        - do-issues.md: Issue resolution
      '';
      filename = "CLAUDE.md";
    };

    # Mock settings.json for Claude CLI
    mockClaudeSettings = {
      content = ''
        {
          "model": "claude-3-5-sonnet-20241022",
          "max_tokens": 4096,
          "temperature": 0.1,
          "commands_dir": "./commands",
          "default_command": "plan"
        }
      '';
      filename = "settings.json";
    };

    # Mock build-switch script
    mockBuildScript = {
      content = ''
        #!/bin/bash
        set -euo pipefail

        # Mock build-switch script for testing
        echo "Mock build-switch starting..."

        PLATFORM="$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')"
        echo "Platform detected: $PLATFORM"

        # Simulate build process
        echo "Building system configuration..."
        sleep 1

        # Simulate switch process
        echo "Switching to new configuration..."
        sleep 1

        echo "Build-switch completed successfully"
        exit 0
      '';
      filename = "build-switch";
      permissions = "755";
    };

    # Mock package.json for Node.js projects
    mockPackageJson = {
      content = ''
        {
          "name": "dotfiles-test",
          "version": "1.0.0",
          "description": "Test fixture for dotfiles",
          "scripts": {
            "test": "npm run test:unit && npm run test:integration",
            "test:unit": "echo 'Running unit tests'",
            "test:integration": "echo 'Running integration tests'"
          },
          "devDependencies": {
            "jest": "^29.0.0",
            "typescript": "^4.9.0"
          }
        }
      '';
      filename = "package.json";
    };

    # Mock zsh configuration
    mockZshConfig = {
      content = ''
        # Mock .zshrc for testing
        export ZSH="$HOME/.oh-my-zsh"
        ZSH_THEME="powerlevel10k/powerlevel10k"

        plugins=(
          git
          docker
          kubectl
          z
        )

        source $ZSH/oh-my-zsh.sh

        # Custom aliases
        alias ll='ls -alF'
        alias la='ls -A'
        alias l='ls -CF'
      '';
      filename = ".zshrc";
    };

    # Mock Karabiner configuration
    mockKarabinerConfig = {
      content = ''
        {
          "global": {
            "check_for_updates_on_startup": true,
            "show_in_menu_bar": true,
            "show_profile_name_in_menu_bar": false
          },
          "profiles": [
            {
              "name": "Default profile",
              "complex_modifications": {
                "rules": [
                  {
                    "description": "Test modification",
                    "manipulators": [
                      {
                        "from": { "key_code": "caps_lock" },
                        "to": [{ "key_code": "escape" }],
                        "type": "basic"
                      }
                    ]
                  }
                ]
              }
            }
          ]
        }
      '';
      filename = "karabiner.json";
    };
  };

  # System state fixtures
  systemFixtures = {
    # Clean system state
    cleanSystem = {
      hasResult = false;
      hasGitRepo = true;
      gitStatus = "clean";
      platform = "aarch64-darwin";
      nixVersion = "2.18.1";
    };

    # System with existing build
    builtSystem = {
      hasResult = true;
      hasGitRepo = true;
      gitStatus = "clean";
      platform = "aarch64-darwin";
      nixVersion = "2.18.1";
      resultPath = "/nix/store/mock-result";
    };

    # System with dirty git state
    dirtySystem = {
      hasResult = true;
      hasGitRepo = true;
      gitStatus = "dirty";
      platform = "aarch64-darwin";
      nixVersion = "2.18.1";
      uncommittedFiles = [ "test-file.txt" "modified-config.nix" ];
    };

    # System with build errors
    errorSystem = {
      hasResult = false;
      hasGitRepo = true;
      gitStatus = "clean";
      platform = "aarch64-darwin";
      nixVersion = "2.18.1";
      lastError = "evaluation error: attribute 'nonexistent' missing";
    };
  };

  # Test data sets
  testDataSets = {
    # Sample package lists for testing
    darwinPackages = [
      "curl" "wget" "git" "jq" "ripgrep" "fd" "bat" "exa"
      "neovim" "tmux" "zsh" "fzf" "tree" "htop"
    ];

    nixosPackages = [
      "curl" "wget" "git" "jq" "ripgrep" "fd" "bat" "exa"
      "neovim" "tmux" "zsh" "fzf" "tree" "htop" "firefox"
    ];

    # Sample user configurations
    testUsers = {
      testuser = {
        name = "Test User";
        email = "test@example.com";
        shell = "zsh";
        home = "/Users/testuser";
      };
      developer = {
        name = "Developer User";
        email = "dev@example.com";
        shell = "zsh";
        home = "/Users/developer";
        extraPackages = [ "docker" "kubernetes-cli" "terraform" ];
      };
    };

    # Sample command outputs
    commandOutputs = {
      nixVersion = "nix (Nix) 2.18.1";
      platformDetection = "aarch64-darwin";
      gitStatus = "On branch main\nnothing to commit, working tree clean";
      buildSuccess = "building '/nix/store/mock-derivation.drv'...\ninstalling...\nbuild completed successfully";
      buildFailure = "error: evaluation aborted with the following error message: 'package not found'";
    };
  };

  # Environment fixtures
  environmentFixtures = {
    # Development environment
    development = {
      env = {
        NODE_ENV = "development";
        DEBUG = "true";
        LOG_LEVEL = "debug";
      };
      paths = [
        "/usr/local/bin"
        "/opt/homebrew/bin"
        "/nix/var/nix/profiles/default/bin"
      ];
    };

    # CI environment
    ci = {
      env = {
        CI = "true";
        NODE_ENV = "test";
        GITHUB_ACTIONS = "true";
      };
      paths = [
        "/usr/bin"
        "/bin"
        "/nix/var/nix/profiles/default/bin"
      ];
    };

    # Production environment
    production = {
      env = {
        NODE_ENV = "production";
        DEBUG = "false";
        LOG_LEVEL = "info";
      };
      paths = [
        "/usr/local/bin"
        "/usr/bin"
        "/bin"
      ];
    };
  };

  # Fixture creation utilities
  createFixtureFile = { fixture, targetPath ? null }:
    let
      path = if targetPath != null then targetPath else fixture.filename or "fixture-file";
      permissions = fixture.permissions or "644";
    in
    testHelpers.createMockFile {
      inherit path permissions;
      content = fixture.content;
    };

  createFixtureDirectory = { name, fixtures, basePath ? "." }:
    let
      structure = lib.mapAttrs (filename: fixture: {
        content = fixture.content;
        permissions = fixture.permissions or "644";
      }) fixtures;
    in
    testHelpers.createMockDirectory {
      path = "${basePath}/${name}";
      inherit structure;
    };

  # System state simulation
  simulateSystemState = state: ''
    echo "Setting up system state: ${state.platform or "unknown"}"

    # Create mock git repository if needed
    ${lib.optionalString (state.hasGitRepo or false) ''
      if command -v git >/dev/null 2>&1; then
        git init . >/dev/null 2>&1 || true
        git config user.email "test@example.com"
        git config user.name "Test User"
      else
        mkdir -p .git
        echo "ref: refs/heads/main" > .git/HEAD
      fi

      # Set git status
      ${if state.gitStatus or "" == "dirty" then ''
        echo "test content" > test-file.txt
        ${lib.concatMapStringsSep "\n" (file: ''
          echo "modified content" > "${file}"
        '') (state.uncommittedFiles or [])}
      '' else if state.gitStatus or "" == "clean" then ''
        echo "initial content" > README.md
        if command -v git >/dev/null 2>&1; then
          git add README.md
          git commit -m "Initial commit" >/dev/null 2>&1 || true
        fi
      '' else ""}
    ''}

    # Create result symlink if system has been built
    ${lib.optionalString (state.hasResult or false) ''
      mkdir -p mock-result/sw/bin
      echo '#!/bin/bash' > mock-result/sw/bin/darwin-rebuild
      echo 'echo "Mock darwin-rebuild: $@"' >> mock-result/sw/bin/darwin-rebuild
      chmod +x mock-result/sw/bin/darwin-rebuild
      ln -sf mock-result result
    ''}

    # Set up error conditions if specified
    ${lib.optionalString (state ? lastError) ''
      echo "${state.lastError}" > last-error.log
    ''}

    # Set platform environment
    export SYSTEM_PLATFORM="${state.platform or testHelpers.platform.systemId}"
    export NIX_VERSION="${state.nixVersion or "2.18.1"}"
  '';

  # Test environment setup with fixtures
  setupTestEnvironmentWithFixtures = { fixtures ? {}, systemState ? systemFixtures.cleanSystem, environment ? environmentFixtures.development }:
    ''
      ${testHelpers.setupEnhancedTestEnv}

      # Apply system state
      ${simulateSystemState systemState}

      # Set up environment variables
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
        "export ${name}='${value}'"
      ) environment.env)}

      # Update PATH
      export PATH="${lib.concatStringsSep ":" environment.paths}:$PATH"

      # Create fixture files
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: fixture:
        createFixtureFile { inherit fixture; targetPath = name; }
      ) fixtures)}

      echo "Test environment with fixtures ready"
    '';

  # Fixture validation
  validateFixtures = fixtures: ''
    echo "${testHelpers.colors.cyan}🔍 Validating fixtures...${testHelpers.colors.reset}"

    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: fixture: ''
      # Validate fixture: ${name}
      if [ ! -e "${fixture.filename or name}" ]; then
        echo "${testHelpers.colors.red}✗ Fixture file missing: ${name}${testHelpers.colors.reset}"
        exit 1
      fi

      ${lib.optionalString (fixture ? content) ''
        if [ ! -s "${fixture.filename or name}" ]; then
          echo "${testHelpers.colors.red}✗ Fixture file empty: ${name}${testHelpers.colors.reset}"
          exit 1
        fi
      ''}

      ${lib.optionalString (fixture ? permissions) ''
        ACTUAL_PERMS=$(stat -c %a "${fixture.filename or name}" 2>/dev/null || stat -f %A "${fixture.filename or name}" 2>/dev/null || echo "unknown")
        if [ "$ACTUAL_PERMS" != "${fixture.permissions}" ]; then
          echo "${testHelpers.colors.yellow}⚠ Fixture permissions mismatch: ${name} (expected ${fixture.permissions}, got $ACTUAL_PERMS)${testHelpers.colors.reset}"
        fi
      ''}

      echo "${testHelpers.colors.green}✓ Fixture validated: ${name}${testHelpers.colors.reset}"
    '') fixtures)}

    echo "${testHelpers.colors.green}✓ All fixtures validated${testHelpers.colors.reset}"
  '';

in
{
  inherit baseFixture configFixtures systemFixtures testDataSets environmentFixtures;
  inherit createFixtureFile createFixtureDirectory simulateSystemState;
  inherit setupTestEnvironmentWithFixtures validateFixtures;

  # Convenience functions for common fixture combinations
  setupBasicDotfilesFixtures = setupTestEnvironmentWithFixtures {
    fixtures = {
      "flake.nix" = configFixtures.mockFlakeBasic;
      "build-switch" = configFixtures.mockBuildScript;
      ".zshrc" = configFixtures.mockZshConfig;
    };
  };

  setupClaudeFixtures = setupTestEnvironmentWithFixtures {
    fixtures = {
      "CLAUDE.md" = configFixtures.mockClaudeConfig;
      "settings.json" = configFixtures.mockClaudeSettings;
    };
    systemState = systemFixtures.cleanSystem;
  };

  setupFullSystemFixtures = setupTestEnvironmentWithFixtures {
    fixtures = configFixtures;
    systemState = systemFixtures.builtSystem;
    environment = environmentFixtures.development;
  };

  # Quick fixture access
  getFixture = name: configFixtures.${name} or (throw "Fixture '${name}' not found");
  getSystemState = name: systemFixtures.${name} or (throw "System state '${name}' not found");
  getEnvironment = name: environmentFixtures.${name} or (throw "Environment '${name}' not found");
}
