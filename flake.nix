{
  description = "baleen's dotfiles - Nix-based development environment";

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
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      darwin,
      home-manager,
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
          modules = [
            ./machines/nixos/vm-aarch64-utm.nix
          ];
        };
      };

      # Test checks
      checks = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ] (
        system: import ./tests { inherit system inputs self; }
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
