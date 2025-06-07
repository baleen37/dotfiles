{ pkgs }:
let
  flake = builtins.getFlake (toString ../.);
  darwinModules = import ../modules/darwin/packages.nix { inherit pkgs; };
  nixosModules = import ../modules/nixos/packages.nix { inherit pkgs; };
  sharedModules = import ../modules/shared/packages.nix { inherit pkgs; };
in
pkgs.runCommand "module-validation-test" {} ''
  export USER=testuser
  
  # Test that all module imports are valid
  echo "Validating module imports..."
  
  # Check shared modules can be imported
  ${if builtins.isList sharedModules then ''
    echo "✓ Shared modules import successfully (${toString (builtins.length sharedModules)} packages)"
  '' else ''
    echo "✗ Shared modules import failed"
    exit 1
  ''}
  
  # Check darwin modules can be imported  
  ${if builtins.isList darwinModules then ''
    echo "✓ Darwin modules import successfully (${toString (builtins.length darwinModules)} packages)"
  '' else ''
    echo "✗ Darwin modules import failed"
    exit 1
  ''}
  
  # Check nixos modules can be imported
  ${if builtins.isList nixosModules then ''
    echo "✓ NixOS modules import successfully (${toString (builtins.length nixosModules)} packages)"
  '' else ''
    echo "✗ NixOS modules import failed"
    exit 1
  ''}
  
  echo "All module validation tests passed!"
  touch $out
''