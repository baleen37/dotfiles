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

          # Add VM-specific tests for x86_64-linux
          vmTestsForLinux =
            let
              pkgs-linux = nixpkgs.legacyPackages.x86_64-linux;
              lib = nixpkgs.lib;
            in
            {
              # VM test suite for NixOS configurations
              vm-test-suite =
                (import ./tests/e2e/nixos-vm-test.nix {
                  inherit lib nixos-generators;
                  pkgs = pkgs-linux;
                  system = "x86_64-linux";
                  self = self;
                }).vm-test-suite;

              # Individual VM tests for granular debugging
              vm-build-test =
                (import ./tests/e2e/nixos-vm-test.nix {
                  inherit lib nixos-generators;
                  pkgs = pkgs-linux;
                  system = "x86_64-linux";
                  self = self;
                }).vm-build-test;

              vm-generation-test =
                (import ./tests/e2e/nixos-vm-test.nix {
                  inherit lib nixos-generators;
                  pkgs = pkgs-linux;
                  system = "x86_64-linux";
                  self = self;
                }).vm-generation-test;

              vm-service-test =
                (import ./tests/e2e/nixos-vm-test.nix {
                  inherit lib nixos-generators;
                  pkgs = pkgs-linux;
                  system = "x86_64-linux";
                  self = self;
                }).vm-service-test;

              # Fast E2E VM test (self-contained, no vm-shared.nix dependency)
              fast-vm-e2e = import ./tests/e2e/fast-vm-e2e-test.nix {
                inherit lib;
                pkgs = pkgs-linux;
                nixpkgs = nixpkgs;
                system = "x86_64-linux";
              };
            };
        in
        standardChecks
        // {
          x86_64-linux = standardChecks.x86_64-linux // vmTestsForLinux;
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
