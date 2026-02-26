{
  description = "baleen's dotfiles - Nix-based development environment";

  nixConfig = {
    # Flake evaluation caches - performance-first order
    # NOTE: These values are also defined in lib/cache-config.nix for system configuration.
    # flake.nix nixConfig cannot import files (must be a top-level attribute set),
    # so these are maintained separately. Keep in sync with lib/cache-config.nix.
    substituters = [
      "https://baleen-nix.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "baleen-nix.cachix.org-1:awgC7Sut148An/CZ6TZA+wnUtJmJnOvl5NThGio9j5k="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    accept-flake-config = true;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Claude Code - latest stable
    claude-code.url = "github:sadjow/claude-code-nix/main";

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
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
      darwin,
      home-manager,
      nixos-generators,
      determinate,
      claude-code,
      ...
    }@inputs:
    let
      # Overlays for unstable packages
      overlays = [
        (final: prev: {
          # unstable alias - nixpkgs already tracks nixpkgs-unstable
          unstable = prev;

          # Claude Code - latest from flake input
          claude-code = claude-code.packages.${prev.system}.default;
        })
      ];

      mkSystem = import ./lib/mksystem.nix { inherit inputs self overlays; };

      # Dynamic user resolution: get from environment variable, fallback to "baleen"
      # Usage: export USER=$(whoami) before running nix commands
      # Requires --impure flag for nix build/switch commands
      user =
        let
          envUser = builtins.getEnv "USER";
        in
        if envUser != "" && envUser != "root" then envUser else "baleen";

      mkNixosVM =
        name: system:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            currentSystem = system;
            currentSystemName = name;
            currentSystemUser = user;
            isWSL = false;
            isDarwin = false;
          };
          modules = [
            ./machines/nixos/${name}.nix
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./users/shared/home-manager.nix;
                extraSpecialArgs = {
                  inherit inputs self;
                  currentSystemUser = user;
                  isDarwin = false;
                };
              };

              users.users.${user} = {
                name = user;
                home = "/home/${user}";
                isNormalUser = true;
              };
            }
          ];
        };
    in
    {
      # macOS configuration
      darwinConfigurations.macbook-pro = mkSystem "macbook-pro" {
        system = "aarch64-darwin";
        user = user;
        darwin = true;
      };

      darwinConfigurations.baleen-macbook = mkSystem "baleen-macbook" {
        system = "aarch64-darwin";
        user = user;
        darwin = true;
      };

      darwinConfigurations.kakaostyle-jito = mkSystem "kakaostyle-jito" {
        system = "aarch64-darwin";
        user = "jito.hello";
        darwin = true;
      };

      # Home Manager configurations (supports multiple users)
      homeConfigurations =
        let
          mkHomeConfig =
            userName:
            {
              system ? "aarch64-darwin",
              isDarwin ? true,
            }:
            home-manager.lib.homeManagerConfiguration {
              pkgs = import nixpkgs {
                inherit system overlays;
                config.allowUnfree = true;
              };
              extraSpecialArgs = {
                inherit inputs self isDarwin;
                currentSystemUser = userName;
              };
              modules = [
                ./users/shared/home-manager.nix
              ];
            };
        in
        {
          baleen = mkHomeConfig "baleen" { };
          "jito.hello" = mkHomeConfig "jito.hello" { };
          testuser = mkHomeConfig "testuser" { };
          "baleen-linux" = mkHomeConfig "baleen" {
            system = "x86_64-linux";
            isDarwin = false;
          };
          "baleen-dev-ubuntu" = mkHomeConfig "baleen" {
            system = "x86_64-linux";
            isDarwin = false;
          };
        };

      # NixOS configurations
      nixosConfigurations = {
        vm-aarch64-utm = mkNixosVM "vm-aarch64-utm" "aarch64-linux";
        vm-x86_64-utm = mkNixosVM "vm-x86_64-utm" "x86_64-linux";
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

        in
        standardChecks;

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

      # E2E tests (only for Linux platforms where VMs can run)
      e2e-tests =
        let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
          lib = nixpkgs.lib;
        in
        import ./tests/e2e {
          inherit
            pkgs
            lib
            system
            self
            inputs
            ;
        };

      # Development shell for nix-direnv
      devShells =
        nixpkgs.lib.genAttrs
          [
            "aarch64-darwin"
            "x86_64-darwin"
            "x86_64-linux"
            "aarch64-linux"
          ]
          (
            system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in
            {
              default = pkgs.mkShell {
                packages = with pkgs; [
                  # Core Nix tooling
                  nixfmt-rfc-style
                  alejandra
                  deadnix
                  statix

                  # Development utilities
                  git
                  jq
                  yq

                  # Testing tools
                  bats

                  # Optional: common utilities
                  curl
                  wget
                ];

                # Set up development environment
                shellHook = ''
                  echo "🚀 Dotfiles development environment loaded"
                  echo "Available commands:"
                  echo "  make format    - Format all files"
                  echo "  make test      - Run tests"
                  echo "  make build     - Build current platform"
                  echo "  make switch    - Apply configuration changes"
                '';
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
