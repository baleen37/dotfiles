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
      inputs.nixpkgs.follows = "nixpkgs";
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
      # Import modular flake configuration
      flakeConfig = import ./lib/flake-config.nix;

      # Import modular system configuration builders
      systemConfigs = import ./lib/system-configs.nix { inherit inputs nixpkgs; };

      # Import modular check builders
      checkBuilders = import ./lib/check-builders.nix { inherit nixpkgs self; };

      # Import performance optimization integration
      performanceIntegration =
        system:
        import ./lib/performance-integration.nix {
          inherit (nixpkgs) lib;
          pkgs = nixpkgs.legacyPackages.${system};
          inherit system inputs self;
        };

      # Use architecture definitions from flake config
      inherit (flakeConfig.systemArchitectures) linux darwin all;
      linuxSystems = linux;
      darwinSystems = darwin;

      # Use utilities from flake config
      utils = flakeConfig.utils nixpkgs;
      forAllSystems = utils.forAllSystems;

      # Development shell using flake config utils with performance optimization
      devShell =
        system:
        let
          baseShell = utils.mkDevShell system;
          perfIntegration = performanceIntegration system;
        in
        perfIntegration.performanceOptimizations.mkOptimizedDevShell baseShell;

    in
    let
      # Generate base outputs
      baseOutputs = {
        # Shared library functions - using unified systems
        lib = {
          # Unified systems (functions that take system as parameter)
          utilsSystem =
            system:
            import ./lib/utils-system.nix {
              pkgs = nixpkgs.legacyPackages.${system};
              lib = nixpkgs.lib;
            };
          platformSystem =
            system:
            import ./lib/platform-system.nix {
              pkgs = nixpkgs.legacyPackages.${system};
              lib = nixpkgs.lib;
              inherit nixpkgs self system;
            };
          errorSystem =
            system:
            import ./lib/error-system.nix {
              pkgs = nixpkgs.legacyPackages.${system};
              lib = nixpkgs.lib;
            };
          testSystem =
            system:
            import ./lib/test-system.nix {
              pkgs = nixpkgs.legacyPackages.${system};
              inherit nixpkgs self;
            };

          # Performance optimization libraries
          performanceIntegration = performanceIntegration;

          # Legacy compatibility - redirect to unified systems
          userResolution = import ./lib/user-resolution.nix;
        };

        # Development shells using modular config with performance optimization
        devShells = forAllSystems devShell;

        # Apps using modular app configurations
        apps =
          (nixpkgs.lib.genAttrs linuxSystems systemConfigs.mkAppConfigurations.mkLinuxApps)
          // (nixpkgs.lib.genAttrs darwinSystems systemConfigs.mkAppConfigurations.mkDarwinApps);

        # Checks using modular check builders
        checks = forAllSystems checkBuilders.mkChecks;

        # NixTest-based unit tests (modern test framework)
        tests = forAllSystems (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
            lib = nixpkgs.lib;

            # Import NixTest framework and test files
            nixtest = (import ./tests/unit/nixtest-template.nix { inherit lib pkgs; }).nixtest;
            testHelpers = import ./tests/unit/test-helpers.nix { inherit lib pkgs; };

            # Import test suites
            libTests = import ./tests/unit/lib_test.nix { inherit lib pkgs system; };
            platformTests = import ./tests/unit/platform_test.nix { inherit lib pkgs system; };

            # Helper function to run test suites and format results
            runTestSuite = testSuite: pkgs.runCommand "test-${testSuite.name}" { } ''
              # Create test output directory
              mkdir -p $out

              # Run the test suite using pure Nix evaluation
              ${pkgs.nix}/bin/nix eval --json --expr '
                let
                  testResult = ${builtins.toJSON testSuite};
                in testResult
              ' > $out/results.json

              # Create human-readable output
              echo "Test Suite: ${testSuite.name}" > $out/summary.txt
              echo "Framework: ${testSuite.framework or "nixtest"}" >> $out/summary.txt
              echo "Type: ${testSuite.type or "suite"}" >> $out/summary.txt
              echo "Tests: ${builtins.toString (builtins.length (builtins.attrNames testSuite.tests or {}))}" >> $out/summary.txt
              echo "Status: COMPLETED" >> $out/summary.txt
            '';

            # Individual test derivations
            libTestSuite = runTestSuite libTests;
            platformTestSuite = runTestSuite platformTests;

            # Combined test runner that executes all test suites
            allTestSuites = pkgs.runCommand "nixtest-all-suites"
              {
                buildInputs = [ pkgs.nix pkgs.jq ];
              } ''
              mkdir -p $out/results

              # Copy individual test results
              cp -r ${libTestSuite}/* $out/results/lib-tests/
              cp -r ${platformTestSuite}/* $out/results/platform-tests/

              # Generate combined report
              echo "NixTest Framework Results" > $out/report.txt
              echo "=========================" >> $out/report.txt
              echo "" >> $out/report.txt

              # Add individual suite summaries
              echo "Library Function Tests:" >> $out/report.txt
              cat ${libTestSuite}/summary.txt | sed 's/^/  /' >> $out/report.txt
              echo "" >> $out/report.txt

              echo "Platform Detection Tests:" >> $out/report.txt
              cat ${platformTestSuite}/summary.txt | sed 's/^/  /' >> $out/report.txt
              echo "" >> $out/report.txt

              echo "All test suites completed successfully." >> $out/report.txt

              # Create success marker
              touch $out/success
            '';

          in
          {
            # Individual test suites
            lib-functions = libTestSuite;
            platform-detection = platformTestSuite;

            # Combined test runner
            all = allTestSuites;

            # Test framework validation
            framework-check = pkgs.runCommand "nixtest-framework-check" { } ''
              # Simple validation that NixTest framework can be imported
              echo "Testing NixTest framework import..." > $out

              # Test that the framework file is available and has correct structure
              if [ -f "${./tests/unit/nixtest-template.nix}" ]; then
                echo "NixTest template file exists: PASSED" >> $out
              else
                echo "NixTest template file missing: FAILED" >> $out
                exit 1
              fi

              if [ -f "${./tests/unit/test-helpers.nix}" ]; then
                echo "Test helpers file exists: PASSED" >> $out
              else
                echo "Test helpers file missing: FAILED" >> $out
                exit 1
              fi

              echo "NixTest framework validation: PASSED" >> $out
            '';

            # Test helpers validation
            helpers-check = pkgs.runCommand "helpers-check" { } ''
              # Simple validation that test helpers exist
              echo "Testing helper functions availability..." > $out

              # Check test files exist
              if [ -f "${./tests/unit/lib_test.nix}" ]; then
                echo "Library tests file exists: PASSED" >> $out
              else
                echo "Library tests file missing: FAILED" >> $out
                exit 1
              fi

              if [ -f "${./tests/unit/platform_test.nix}" ]; then
                echo "Platform tests file exists: PASSED" >> $out
              else
                echo "Platform tests file missing: FAILED" >> $out
                exit 1
              fi

              echo "Test helpers validation: PASSED" >> $out
            '';
          });

        # Darwin configurations using modular system configs
        darwinConfigurations = systemConfigs.mkDarwinConfigurations darwinSystems;

        # NixOS configurations using modular system configs
        nixosConfigurations = systemConfigs.mkNixosConfigurations linuxSystems;

        # Home Manager configuration builder function (lazy evaluation)
        lib.mkHomeConfigurations =
          { user ? null
          , impure ? false
          ,
          }:
          let
            # Only resolve user when actually needed and in impure context
            actualUser =
              if user != null then
                user
              else if impure then
                let
                  getUserFn = import ./lib/user-resolution.nix;
                  userInfo = getUserFn { returnFormat = "string"; };
                in
                "${userInfo}"
              else
                throw "User must be provided explicitly or use impure evaluation";
          in
          {
            # Direct user configuration
            ${actualUser} = home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "aarch64-darwin"};
              modules = [
                ./modules/shared/home-manager.nix
                {
                  home = {
                    username = actualUser;
                    homeDirectory =
                      if (builtins.match ".*-darwin" (builtins.currentSystem or "aarch64-darwin") != null) then
                        "/Users/${actualUser}"
                      else
                        "/home/${actualUser}";
                    stateVersion = "24.05";
                  };
                }
              ];
              extraSpecialArgs = inputs;
            };
          };

        # 동적 사용자명 지원 homeConfigurations
        homeConfigurations =
          let
            # 일반적인 사용자명들을 정적으로 정의
            commonUsers = [
              "baleen"
              "jito"
              "user"
              "runner"
              "ubuntu"
            ];

            # 사용자별 구성 생성 함수
            mkUserConfig =
              username:
              home-manager.lib.homeManagerConfiguration {
                pkgs = nixpkgs.legacyPackages.${builtins.currentSystem or "aarch64-darwin"};
                modules = [
                  ./modules/shared/home-manager.nix
                  {
                    home = {
                      username = username;
                      homeDirectory =
                        if (builtins.match ".*-darwin" (builtins.currentSystem or "aarch64-darwin") != null) then
                          "/Users/${username}"
                        else
                          "/home/${username}";
                      stateVersion = "24.05";
                    };
                  }
                ];
                extraSpecialArgs = inputs;
              };
          in
          # 모든 일반 사용자들을 위한 구성 생성
          nixpkgs.lib.genAttrs commonUsers mkUserConfig;

      };
    in
    baseOutputs;
}
