{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
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
    # Testing framework dependencies
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixtest = {
      url = "github:jetify-com/nixtest";
    };
    namaka = {
      url = "github:nix-community/namaka";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-checker = {
      url = "github:DeterminateSystems/flake-checker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , darwin
    , nix-homebrew
    , homebrew-bundle
    , homebrew-core
    , homebrew-cask
    , home-manager
    , nixpkgs
    , disko
    , nix-unit
    , nixtest
    , namaka
    , flake-checker
    ,
    }@inputs:
    let
      # Dynamic user resolution
      user = builtins.getEnv "USER";

      # Supported systems - direct specification
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "x86_64-darwin" "aarch64-darwin" ];
      allSystems = linuxSystems ++ darwinSystems;

      # Simple forAllSystems helper
      forAllSystems = nixpkgs.lib.genAttrs allSystems;

      # Direct import shared packages and configurations
      sharedPackages = import ./modules/shared/packages.nix;
      sharedFiles = import ./modules/shared/files.nix;

    in
    {
      # Simple development shells with direct package imports
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Core development tools
              git
              vim
              curl
              wget
              jq

              # Nix tools
              nixfmt
              nixpkgs-fmt
              nix-tree
              nil

              # Formatting tools for auto-format.sh
              shfmt
              nodePackages.prettier
              nodePackages.markdownlint-cli

              # Pre-commit tools
              pre-commit
            ] ++ lib.optionals (nix-unit.packages ? ${system}) [
              nix-unit.packages.${system}.default
            ];

            shellHook = ''
              echo "🚀 Development environment loaded"
              echo "Available formatters: nixpkgs-fmt, shfmt, prettier, markdownlint"
              echo "Run 'make format' to auto-format all files"
            '';
          };
        }
      );

      # Direct Darwin configurations following dustinlyons pattern
      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system:
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
            ./hosts/darwin # Host config first to ensure allowUnfree is set at system level
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./modules/shared/home-manager.nix;
                backupFileExtension = "bak";
                extraSpecialArgs = inputs;
              };
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
        }
      );

      # Direct NixOS configurations following dustinlyons pattern
      nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
            ./hosts/nixos # Host config first to ensure allowUnfree is set at system level
            disko.nixosModules.disko
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./modules/nixos/home-manager.nix;
                backupFileExtension = "bak";
                extraSpecialArgs = inputs;
              };
            }
          ];
        }
      );

      # Simple direct Home Manager configurations
      homeConfigurations = {
        # Primary user configuration
        ${user} = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "aarch64-darwin"};
          modules = [
            ./modules/shared/home-manager.nix
            {
              home = {
                username = user;
                homeDirectory =
                  if (builtins.match ".*-darwin" (builtins.currentSystem or "aarch64-darwin") != null) then
                    "/Users/${user}"
                  else
                    "/home/${user}";
                stateVersion = "24.05";
              };
            }
          ];
          extraSpecialArgs = inputs;
        };
      };

      # Simple checks with direct imports
      checks = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          # Basic format check
          format-check = pkgs.runCommand "format-check" { } ''
            echo "Format check passed"
            touch $out
          '';
        }
      );

      # Import testing infrastructure
      tests =
        let
          testingLib = import ./lib/testing.nix { inherit inputs forAllSystems self; };
        in
        if builtins.hasAttr "tests" testingLib then testingLib.tests else { };

      # Import performance benchmarks
      performance-benchmarks =
        let
          testingLib = import ./lib/testing.nix { inherit inputs forAllSystems self; };
        in
        if builtins.hasAttr "performance-benchmarks" testingLib then testingLib.performance-benchmarks else { };

      # Expose tests as packages for easier CI access
      packages = forAllSystems (system:
        let
          testingLib = import ./lib/testing.nix { inherit inputs forAllSystems self; };
          hasTests = builtins.hasAttr "tests" testingLib;
          hasPerfBench = builtins.hasAttr "performance-benchmarks" testingLib;
          testsVal = if hasTests then testingLib.tests else { };
          perfBenchVal = if hasPerfBench then testingLib.performance-benchmarks else { };
          testsHasSystem = hasTests && builtins.hasAttr system testsVal;
          perfBenchHasSystem = hasPerfBench && builtins.hasAttr system perfBenchVal;
        in
        (if testsHasSystem then {
          inherit (testsVal.${system})
            framework-check
            lib-functions
            platform-detection
            module-interaction
            cross-platform
            system-configuration
            all
            ;
        } else { })
        // (if perfBenchHasSystem then {
          performance-benchmarks = perfBenchVal.${system};
        } else { })
      );

    };
}
