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
      # Overlays for unstable packages
      overlays = [
        (final: prev: {
          unstable = import nixpkgs-unstable {
            inherit (prev) system;
            config.allowUnfree = true;
          };
        })
      ];

      mkSystem = import ./lib/mksystem.nix {
        inherit overlays nixpkgs inputs;
      };
    in
    {
      # NixOS system
      nixosConfigurations.vm-aarch64-utm = mkSystem "vm-aarch64-utm" {
        system = "aarch64-linux";
        user   = "baleen";
      };

      # Darwin systems
      darwinConfigurations.macbook-pro-baleen = mkSystem "macbook-pro-baleen" {
        system = "aarch64-darwin";
        user   = "baleen";
        darwin = true;
      };

      darwinConfigurations.macbook-pro-jito = mkSystem "macbook-pro-jito" {
        system = "aarch64-darwin";
        user   = "jito";
        darwin = true;
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
              ./machines/vm-aarch64-utm.nix
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
