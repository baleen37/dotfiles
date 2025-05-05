{
  description = "Home Manager configuration of baleen";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Define supported systems
      supportedSystems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" "x86_64-darwin" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];

      # Helper function to generate outputs for each system
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      forDarwinSystems = nixpkgs.lib.genAttrs darwinSystems;

      # Import nixpkgs for each system
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      });
    in {
      # Only Darwin home configuration
      homeConfigurations."baleen" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgsFor."aarch64-darwin";

        # Use proper path reference using self
        modules = [
          (import ./modules/darwin/home.nix)
        ];

        # Pass extra parameters to home modules
        extraSpecialArgs = {
          # Add any special arguments you want to pass to your modules here
        };
      };

      # Add default packages for each system
      packages = forAllSystems (system:
        let
          isDarwin = builtins.elem system darwinSystems;
        in
        if isDarwin then {
          # For Darwin systems, provide the home configuration
          default = self.homeConfigurations."baleen".activationPackage;
        } else {
          # For non-Darwin systems, provide a dummy package
          default = nixpkgsFor.${system}.runCommand "unsupported-system" {} ''
            echo "This system (${system}) is not supported for home configuration"
            mkdir -p $out/bin
            echo "echo 'This system is not supported for home configuration'" > $out/bin/unsupported
            chmod +x $out/bin/unsupported
          '';
        }
      );

      # Add default package shortcuts
      defaultPackage = forAllSystems (system: self.packages.${system}.default);
    };
}
