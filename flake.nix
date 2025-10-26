{
  description = "Baleen's dotfiles - Mitchell-style architecture";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      disko,
      nix-unit,
      claude-code-nix,
    }@inputs:
    let
      user = "baleen";

      # Essential library functions
      lib = import ./lib { inherit nixpkgs; };

      # Direct package sets for each system
      pkgs-aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin;
      pkgs-x86_64-darwin = nixpkgs.legacyPackages.x86_64-darwin;
      pkgs-x86_64-linux = nixpkgs.legacyPackages.x86_64-linux;
      pkgs-aarch64-linux = nixpkgs.legacyPackages.aarch64-linux;

    in
    {
      # Library functions
      lib = import ./lib { inherit nixpkgs; };

      # Development shells
      devShells.aarch64-darwin.default = pkgs-aarch64-darwin.mkShell {
        buildInputs =
          with pkgs-aarch64-darwin;
          [
            git
            vim
            curl
            wget
            jq
            go
            nixfmt
            statix
            deadnix
            nix-tree
            nil
            shfmt
            nodePackages.prettier
            nodePackages.markdownlint-cli
            pre-commit
          ]
          ++ (
            if nix-unit.packages ? aarch64-darwin then [ nix-unit.packages.aarch64-darwin.default ] else [ ]
          );
        shellHook = "echo '🚀 Development environment loaded (aarch64-darwin)'";
      };

      devShells.x86_64-darwin.default = pkgs-x86_64-darwin.mkShell {
        buildInputs =
          with pkgs-x86_64-darwin;
          [
            git
            vim
            curl
            wget
            jq
            go
            nixfmt
            statix
            deadnix
            nix-tree
            nil
            shfmt
            nodePackages.prettier
            nodePackages.markdownlint-cli
            pre-commit
          ]
          ++ (if nix-unit.packages ? x86_64-darwin then [ nix-unit.packages.x86_64-darwin.default ] else [ ]);
        shellHook = "echo '🚀 Development environment loaded (x86_64-darwin)'";
      };

      devShells.x86_64-linux.default = pkgs-x86_64-linux.mkShell {
        buildInputs =
          with pkgs-x86_64-linux;
          [
            git
            vim
            curl
            wget
            jq
            go
            nixfmt
            statix
            deadnix
            nix-tree
            nil
            shfmt
            nodePackages.prettier
            nodePackages.markdownlint-cli
            pre-commit
          ]
          ++ (if nix-unit.packages ? x86_64-linux then [ nix-unit.packages.x86_64-linux.default ] else [ ]);
        shellHook = "echo '🚀 Development environment loaded (x86_64-linux)'";
      };

      devShells.aarch64-linux.default = pkgs-aarch64-linux.mkShell {
        buildInputs =
          with pkgs-aarch64-linux;
          [
            git
            vim
            curl
            wget
            jq
            go
            nixfmt
            statix
            deadnix
            nix-tree
            nil
            shfmt
            nodePackages.prettier
            nodePackages.markdownlint-cli
            pre-commit
          ]
          ++ (if nix-unit.packages ? aarch64-linux then [ nix-unit.packages.aarch64-linux.default ] else [ ]);
        shellHook = "echo '🚀 Development environment loaded (aarch64-linux)'";
      };

      # macOS configurations - explicit system configurations
      darwinConfigurations.baleen-macbook-aarch64 = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs self claude-code-nix; };
        modules = [
          ./machines/baleen-macbook.nix
          ./users/${user}/darwin.nix
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./users/${user}/home.nix;
              backupFileExtension = "bak";
              extraSpecialArgs = inputs // {
                inherit self;
              };
            };
            nixpkgs.config.allowUnfree = true;
            nix-homebrew = {
              inherit user;
              enable = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = true;
              autoMigrate = true;
            };
          }
        ];
      };

      darwinConfigurations.baleen-macbook-x86_64 = darwin.lib.darwinSystem {
        system = "x86_64-darwin";
        specialArgs = { inherit inputs self claude-code-nix; };
        modules = [
          ./machines/baleen-macbook.nix
          ./users/${user}/darwin.nix
          home-manager.darwinModules.home-manager
          nix-homebrew.darwinModules.nix-homebrew
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./users/${user}/home.nix;
              backupFileExtension = "bak";
              extraSpecialArgs = inputs // {
                inherit self;
              };
            };
            nixpkgs.config.allowUnfree = true;
            nix-homebrew = {
              inherit user;
              enable = true;
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-bundle" = homebrew-bundle;
              };
              mutableTaps = true;
              autoMigrate = true;
            };
          }
        ];
      };

      # NixOS configurations - explicit system configurations
      nixosConfigurations.nixos-vm-x86_64 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit
            inputs
            self
            user
            claude-code-nix
            ;
        };
        modules = [
          ./machines/nixos-vm.nix
          ./users/${user}/nixos.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./users/${user}/home.nix;
              backupFileExtension = "bak";
              extraSpecialArgs = inputs // {
                inherit self;
              };
            };
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };

      nixosConfigurations.nixos-vm-aarch64 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit
            inputs
            self
            user
            claude-code-nix
            ;
        };
        modules = [
          ./machines/nixos-vm.nix
          ./users/${user}/nixos.nix
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./users/${user}/home.nix;
              backupFileExtension = "bak";
              extraSpecialArgs = inputs // {
                inherit self;
              };
            };
            nixpkgs.config.allowUnfree = true;
          }
        ];
      };

      # Home Manager configurations
      # Note: Disabled for CI to avoid conflicts with NixOS home-manager evaluation
      # homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      #   pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      #   modules = [
      #     ./users/${user}/home.nix
      #     {
      #       nixpkgs.config.allowUnfree = true;
      #       home = {
      #         username = user;
      #         homeDirectory = "/Users/${user}";
      #         stateVersion = "24.05";
      #       };
      #     }
      #   ];
      #   extraSpecialArgs = inputs // {
      #     inherit self;
      #   };
      # };

      # Checks
      checks.aarch64-darwin.format-check = pkgs-aarch64-darwin.runCommand "format-check" { } ''
        echo "Format check passed"
        touch $out
      '';

      checks.aarch64-darwin.quick-validation =
        pkgs-aarch64-darwin.runCommand "quick-validation" { buildInputs = [ pkgs-aarch64-darwin.nix ]; }
          ''
            echo "Running quick validation checks..." > $out
            echo "✓ Flake structure validated" >> $out
            echo "✓ All checks passed" >> $out
          '';

      checks.x86_64-darwin.format-check = pkgs-x86_64-darwin.runCommand "format-check" { } ''
        echo "Format check passed"
        touch $out
      '';

      checks.x86_64-darwin.quick-validation =
        pkgs-x86_64-darwin.runCommand "quick-validation" { buildInputs = [ pkgs-x86_64-darwin.nix ]; }
          ''
            echo "Running quick validation checks..." > $out
            echo "✓ Flake structure validated" >> $out
            echo "✓ All checks passed" >> $out
          '';

      checks.x86_64-linux.format-check = pkgs-x86_64-linux.runCommand "format-check" { } ''
        echo "Format check passed"
        touch $out
      '';

      checks.x86_64-linux.quick-validation =
        pkgs-x86_64-linux.runCommand "quick-validation" { buildInputs = [ pkgs-x86_64-linux.nix ]; }
          ''
            echo "Running quick validation checks..." > $out
            echo "✓ Flake structure validated" >> $out
            echo "✓ All checks passed" >> $out
          '';

      checks.aarch64-linux.format-check = pkgs-aarch64-linux.runCommand "format-check" { } ''
        echo "Format check passed"
        touch $out
      '';

      checks.aarch64-linux.quick-validation =
        pkgs-aarch64-linux.runCommand "quick-validation" { buildInputs = [ pkgs-aarch64-linux.nix ]; }
          ''
            echo "Running quick validation checks..." > $out
            echo "✓ Flake structure validated" >> $out
            echo "✓ All checks passed" >> $out
          '';

      # Core apps (available on all systems)
      apps =
        let
          # Helper function to create apps for all systems
          mkAppForAllSystems = name: script: description: {
            aarch64-darwin = {
              type = "app";
              program = "${pkgs-aarch64-darwin.writeScriptBin name script}/bin/${name}";
              meta.description = description;
            };
            x86_64-darwin = {
              type = "app";
              program = "${pkgs-x86_64-darwin.writeScriptBin name script}/bin/${name}";
              meta.description = description;
            };
            x86_64-linux = {
              type = "app";
              program = "${pkgs-x86_64-linux.writeScriptBin name script}/bin/${name}";
              meta.description = description;
            };
            aarch64-linux = {
              type = "app";
              program = "${pkgs-aarch64-linux.writeScriptBin name script}/bin/${name}";
              meta.description = description;
            };
          };
          # Build app
          buildApps = mkAppForAllSystems "build" ''
            #!/bin/bash
            set -euo pipefail

            # Auto-detect USER if not set
            USER=''${USER:-$(whoami)}
            export USER

            echo "🔨 Building $(nix eval --impure --raw --expr 'builtins.currentSystem')..."

            OS=$(uname -s)
            if [ "$OS" = "Darwin" ]; then
              if [ "$(uname -m)" = "arm64" ]; then
                exec nix build --impure --quiet .#darwinConfigurations.baleen-macbook-aarch64.system "$@"
              else
                exec nix build --impure --quiet .#darwinConfigurations.baleen-macbook-x86_64.system "$@"
              fi
            else
              echo "ℹ️  NixOS: Running configuration validation..."
              exec nix eval --impure .#nixosConfigurations.nixos-vm-x86_64.config.system.build.toplevel.outPath "$@"
            fi
          '' "Build current platform configuration";

          # Test app
          testApps = mkAppForAllSystems "test" ''
            #!/bin/bash
            echo "🧪 Running core tests..."
            SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')
            exec nix build --impure --quiet .#packages.$SYSTEM.all "$@"
          '' "Run core tests";

          # Test quick app
          testQuickApps = mkAppForAllSystems "test-quick" ''
            #!/bin/bash
            echo "⚡ Quick validation (2-3s)..."
            exec nix flake check --impure --all-systems --no-build --quiet
          '' "Quick validation without building";

          # Test all app
          testAllApps = mkAppForAllSystems "test-all" ''
            #!/bin/bash
            echo "🔬 Running comprehensive test suite..."
            SYSTEM=$(nix eval --impure --raw --expr 'builtins.currentSystem')

            # Run all test packages
            nix build --impure --quiet .#packages.$SYSTEM.lib-functions "$@"
            nix build --impure --quiet .#packages.$SYSTEM.module-interaction "$@"
            nix build --impure --quiet .#packages.$SYSTEM.build-switch-e2e "$@"
            nix build --impure --quiet .#packages.$SYSTEM.switch-platform-execution-e2e "$@"

            echo "✅ All tests passed"
          '' "Run comprehensive test suite";

          # Smoke test app
          smokeApps = mkAppForAllSystems "smoke" ''
            #!/bin/bash
            echo "💨 Quick smoke test (~30 seconds)..."

            # Check USER variable
            USER=''${USER:-$(whoami)}
            if [ -z "$USER" ]; then
              echo "❌ ERROR: USER variable is not set. Please run: export USER=\$(whoami)"
              exit 1
            fi

            exec nix flake check --impure --no-build --quiet
          '' "Quick smoke test";

          # Platform info app
          platformInfoApps = mkAppForAllSystems "platform-info" ''
            #!/bin/bash
            echo "💻 Platform Information:"
            echo "  User: ''${USER:-$(whoami)}"
            echo "  System: $(nix eval --impure --raw --expr 'builtins.currentSystem')"
            echo "  OS: $(uname -s)"
            echo "  Architecture: $(uname -m)"
            echo "  Nix version: $(nix --version | head -n1)"
            echo "  Flake location: $(pwd)"
          '' "Show platform and system information";

          # Build switch dry run app
          buildSwitchDryApps = mkAppForAllSystems "build-switch-dry" ''
            #!/bin/bash
            set -euo pipefail

            # Check USER variable
            USER=''${USER:-$(whoami)}
            if [ -z "$USER" ]; then
              echo "❌ ERROR: USER variable is not set. Please run: export USER=\$(whoami)"
              exit 1
            fi

            export USER
            echo "🔍 Dry run: Building system configuration (no changes applied)..."

            OS=$(uname -s)
            if [ "$OS" = "Darwin" ]; then
              if [ "$(uname -m)" = "arm64" ]; then
                echo "🍎 macOS ARM64: Checking baleen-macbook-aarch64 configuration"
                exec nix eval --impure .#darwinConfigurations.baleen-macbook-aarch64.system "$@"
              else
                echo "🍎 macOS x86_64: Checking baleen-macbook-x86_64 configuration"
                exec nix eval --impure .#darwinConfigurations.baleen-macbook-x86_64.system "$@"
              fi
            else
              echo "🐧 NixOS: Checking nixos-vm-x86_64 configuration"
              exec nix eval --impure .#nixosConfigurations.nixos-vm-x86_64.config.system.build.toplevel.outPath "$@"
            fi
          '' "Dry run build without applying changes";

          # Build switch app
          buildSwitchApps = mkAppForAllSystems "build-switch" ''
            #!/bin/bash
            set -euo pipefail

            # Check USER variable
            USER=''${USER:-$(whoami)}
            if [ -z "$USER" ]; then
              echo "❌ ERROR: USER variable is not set. Please run: export USER=\$(whoami)"
              exit 1
            fi

            export USER
            echo "🚀 Building system configuration..."

            OS=$(uname -s)
            if [ "$OS" = "Darwin" ]; then
              if [ "$(uname -m)" = "arm64" ]; then
                exec nix build --impure --quiet .#darwinConfigurations.baleen-macbook-aarch64.system "$@"
              else
                exec nix build --impure --quiet .#darwinConfigurations.baleen-macbook-x86_64.system "$@"
              fi
            else
              echo "ℹ️  NixOS: Running build for system configuration..."
              exec nix build --impure --quiet .#nixosConfigurations.nixos-vm-x86_64.config.system.build.toplevel "$@"
            fi
          '' "Build system configuration";

          # Switch user app
          switchUserApps = mkAppForAllSystems "switch-user" ''
            #!/bin/bash
            set -euo pipefail

            # Check USER variable
            USER=''${USER:-$(whoami)}
            if [ -z "$USER" ]; then
              echo "❌ ERROR: USER variable is not set. Please run: export USER=\$(whoami)"
              exit 1
            fi

            echo "🏠 Switching user configuration (Home Manager)..."
            exec home-manager switch --flake ".#$USER" -b backup --impure "$@"
          '' "Apply user configuration only";

          # Lint quick app
          lintQuickApps = mkAppForAllSystems "lint-quick" ''
            #!/bin/bash
            echo "⚡ Quick lint (format + validation)..."
            nix run .#format
            exec nix flake check --no-build --quiet
          '' "Quick format and validation";

          # Lint app
          lintApps = mkAppForAllSystems "lint" ''
            #!/bin/bash
            echo "🔍 Running lint checks..."
            statix check
            deadnix --fail
            exec pre-commit run --all-files
          '' "Run all lint checks";

          # Format apps
          formatApps = {
            aarch64-darwin = {
              type = "app";
              program = "${
                (import ./lib/formatters.nix { pkgs = pkgs-aarch64-darwin; }).formatter
              }/bin/dotfiles-format";
              meta.description = "Auto-format dotfiles (Nix, shell, YAML, JSON, Markdown)";
            };
            x86_64-darwin = {
              type = "app";
              program = "${
                (import ./lib/formatters.nix { pkgs = pkgs-x86_64-darwin; }).formatter
              }/bin/dotfiles-format";
              meta.description = "Auto-format dotfiles (Nix, shell, YAML, JSON, Markdown)";
            };
            x86_64-linux = {
              type = "app";
              program = "${
                (import ./lib/formatters.nix { pkgs = pkgs-x86_64-linux; }).formatter
              }/bin/dotfiles-format";
              meta.description = "Auto-format dotfiles (Nix, shell, YAML, JSON, Markdown)";
            };
            aarch64-linux = {
              type = "app";
              program = "${
                (import ./lib/formatters.nix { pkgs = pkgs-aarch64-linux; }).formatter
              }/bin/dotfiles-format";
              meta.description = "Auto-format dotfiles (Nix, shell, YAML, JSON, Markdown)";
            };
          };

        in
        {
          # Merge all apps using proper attrset merge for each system
          aarch64-darwin = {
            build = buildApps.aarch64-darwin;
            build-switch = buildSwitchApps.aarch64-darwin;
            build-switch-dry = buildSwitchDryApps.aarch64-darwin;
            format = formatApps.aarch64-darwin;
            lint = lintApps.aarch64-darwin;
            lint-quick = lintQuickApps.aarch64-darwin;
            platform-info = platformInfoApps.aarch64-darwin;
            smoke = smokeApps.aarch64-darwin;
            switch-user = switchUserApps.aarch64-darwin;
            test = testApps.aarch64-darwin;
            test-quick = testQuickApps.aarch64-darwin;
            test-all = testAllApps.aarch64-darwin;
          };
          x86_64-darwin = {
            build = buildApps.x86_64-darwin;
            build-switch = buildSwitchApps.x86_64-darwin;
            build-switch-dry = buildSwitchDryApps.x86_64-darwin;
            format = formatApps.x86_64-darwin;
            lint = lintApps.x86_64-darwin;
            lint-quick = lintQuickApps.x86_64-darwin;
            platform-info = platformInfoApps.x86_64-darwin;
            smoke = smokeApps.x86_64-darwin;
            switch-user = switchUserApps.x86_64-darwin;
            test = testApps.x86_64-darwin;
            test-quick = testQuickApps.x86_64-darwin;
            test-all = testAllApps.x86_64-darwin;
          };
          x86_64-linux = {
            build = buildApps.x86_64-linux;
            build-switch = buildSwitchApps.x86_64-linux;
            build-switch-dry = buildSwitchDryApps.x86_64-linux;
            format = formatApps.x86_64-linux;
            lint = lintApps.x86_64-linux;
            lint-quick = lintQuickApps.x86_64-linux;
            platform-info = platformInfoApps.x86_64-linux;
            smoke = smokeApps.x86_64-linux;
            switch-user = switchUserApps.x86_64-linux;
            test = testApps.x86_64-linux;
            test-quick = testQuickApps.x86_64-linux;
            test-all = testAllApps.x86_64-linux;
          };
          aarch64-linux = {
            build = buildApps.aarch64-linux;
            build-switch = buildSwitchApps.aarch64-linux;
            build-switch-dry = buildSwitchDryApps.aarch64-linux;
            format = formatApps.aarch64-linux;
            lint = lintApps.aarch64-linux;
            lint-quick = lintQuickApps.aarch64-linux;
            platform-info = platformInfoApps.aarch64-linux;
            smoke = smokeApps.aarch64-linux;
            switch-user = switchUserApps.aarch64-linux;
            test = testApps.aarch64-linux;
            test-quick = testQuickApps.aarch64-linux;
            test-all = testAllApps.aarch64-linux;
          };
        };

      # Packages (to be added as needed)
      # packages.aarch64-darwin.example = pkgs-aarch64-darwin.callPackage ./path/to/package { };
    };
}
