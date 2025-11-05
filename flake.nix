{
  description = "baleen's dotfiles - Nix-based development environment";

  nixConfig = {
    substituters = [
      "https://baleen-nix.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      darwin,
      home-manager,
      nixos-generators,
      ...
    }@inputs:
    let
      mkSystem = import ./lib/mksystem.nix { inherit inputs self; };

      # Dynamic user resolution: get from environment variable, fallback to "baleen"
      # Usage: export USER=$(whoami) before running nix commands
      # Requires --impure flag for nix build/switch commands
      user =
        let
          envUser = builtins.getEnv "USER";
        in
        if envUser != "" then envUser else "baleen";

      # Overlays for unstable packages
      overlays = [
        (final: prev: {
          unstable = import nixpkgs-unstable {
            inherit (prev) system;
            config.allowUnfree = true;
          };
        })
      ];
    in
    {
      # macOS configuration
      darwinConfigurations.macbook-pro = mkSystem "macbook-pro" {
        system = "aarch64-darwin";
        user = user;
        darwin = true;
      };

      # Home Manager configurations (supports multiple users)
      homeConfigurations =
        let
          mkHomeConfig =
            userName:
            home-manager.lib.homeManagerConfiguration {
              pkgs = nixpkgs.legacyPackages.aarch64-darwin;
              extraSpecialArgs = {
                inherit inputs self;
                currentSystemUser = userName;
                isDarwin = true;
              };
              modules = [
                ./users/shared/home-manager.nix
              ];
            };
        in
        {
          baleen = mkHomeConfig "baleen";
          jito = mkHomeConfig "jito";
          testuser = mkHomeConfig "testuser";
        };

      # NixOS configurations
      nixosConfigurations = {
        vm-aarch64-utm = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            inherit inputs self;
            currentSystem = "aarch64-linux";
            currentSystemName = "vm-aarch64-utm";
            currentSystemUser = user;
            isWSL = false;
            isDarwin = false;
          };
          modules = [
            ./machines/nixos/vm-aarch64-utm.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./users/shared/home-manager.nix;
                extraSpecialArgs = {
                  inherit inputs self;
                  currentSystemUser = user;
                };
              };

              # Set required home-manager options with correct paths
              users.users.${user} = {
                name = user;
                home = "/home/${user}";
                isNormalUser = true;
              };
            }
          ];
        };
      };

      # Test checks
      checks =
        let
          # Standard checks for all platforms
          standardChecks = nixpkgs.lib.genAttrs [
            "aarch64-darwin"
            "x86_64-darwin"
            "x86_64-linux"
            "aarch64-linux"
          ] (system: import ./tests { inherit system inputs self; });

          # Add VM-specific tests for both Linux architectures
          vmTestsForLinux =
            let
              pkgs-linux-x64 = nixpkgs.legacyPackages.x86_64-linux;
              pkgs-linux-arm = nixpkgs.legacyPackages.aarch64-linux;
              lib = nixpkgs.lib;

              # Optimized VM test suite - consolidates all VM testing functionality
              # Replaces: nixos-vm-test, fast-vm-e2e, vm-e2e, core-vm-test, streamlined-vm-test
              # Target: 3 minutes execution, 2 cores/2GB RAM (vs original 10+ minutes, 4 cores/8GB RAM)
              vm-test-suite-x64 = import ./tests/e2e/optimized-vm-suite.nix {
                inherit inputs;
                pkgs = pkgs-linux-x64;
                system = "x86_64-linux";
                self = self;
              };

              vm-test-suite-arm = import ./tests/e2e/optimized-vm-suite.nix {
                inherit inputs;
                pkgs = pkgs-linux-arm;
                system = "aarch64-linux";
                self = self;
              };
            in
            {
              # Primary VM test suites for both architectures
              vm-test-suite-x64 = vm-test-suite-x64;
              vm-test-suite-arm = vm-test-suite-arm;

              # Legacy aliases for backward compatibility (x86_64-linux)
              vm-test-suite = vm-test-suite-x64;
              vm-build-test = vm-test-suite-x64;
              vm-generation-test = vm-test-suite-x64;
              vm-service-test = vm-test-suite-x64;
              fast-vm-e2e = vm-test-suite-x64;
              vm-e2e = vm-test-suite-x64;

              # Comprehensive test suite validation (validates all test categories)
              comprehensive-suite-validation = import ./tests/e2e/comprehensive-suite-validation-test.nix {
                inherit lib;
                pkgs = pkgs-linux-x64;
                nixpkgs = nixpkgs;
                system = "x86_64-linux";
              };
            };

          # Add VM-specific tests for aarch64-linux
          vmTestsForLinuxARM =
            let
              pkgs-linux-arm = nixpkgs.legacyPackages.aarch64-linux;
              lib = nixpkgs.lib;

              # ARM-specific VM test suite
              vm-test-suite = import ./tests/e2e/optimized-vm-suite.nix {
                inherit inputs;
                pkgs = pkgs-linux-arm;
                system = "aarch64-linux";
                self = self;
              };
            in
            {
              # Primary VM test suite for ARM
              inherit vm-test-suite;

              # Legacy aliases for backward compatibility
              vm-build-test = vm-test-suite;
              vm-generation-test = vm-test-suite;
              vm-service-test = vm-test-suite;
              fast-vm-e2e = vm-test-suite;
              vm-e2e = vm-test-suite;
            };
        in
        standardChecks
        // {
          x86_64-linux = standardChecks.x86_64-linux // vmTestsForLinux;
          aarch64-linux = standardChecks.aarch64-linux // vmTestsForLinuxARM;
        };

      # Add VM generation packages
      packages = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          test-vm = nixos-generators.nixosGenerate {
            inherit system;
            format = "vm-nogui";
            modules = [
              ./machines/nixos/vm-aarch64-utm.nix
              {
                # VM testing configuration
                virtualisation.memorySize = 2048;
                virtualisation.cores = 2;
                virtualisation.diskSize = 10240;

                # SSH port forwarding for testing
                virtualisation.forwardPorts = [
                  {
                    from = "host";
                    host.port = 2222;
                    guest.port = 22;
                  }
                ];

                # Essential services for testing
                services.openssh.enable = true;
                services.openssh.settings.PasswordAuthentication = true;
                virtualisation.docker.enable = true;
                networking.firewall.enable = false;

                # Test user setup
                users.users.testuser = {
                  isNormalUser = true;
                  extraGroups = [
                    "wheel"
                    "docker"
                  ];
                  initialPassword = "test";
                };
                security.sudo.wheelNeedsPassword = false;
              }
            ];
          };
        }
      );

      # Formatter (preserve from old flake if exists)
      formatter = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ] (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
