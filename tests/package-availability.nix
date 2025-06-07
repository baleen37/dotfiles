{ pkgs }:
let
  # Import package lists from modules
  sharedPackages = import ../modules/shared/packages.nix { inherit pkgs; };
  darwinPackages = import ../modules/darwin/packages.nix { inherit pkgs; };
  nixosPackages = import ../modules/nixos/packages.nix { inherit pkgs; };
  
  # Test that packages can be built/accessed
  testPackage = pkg: 
    if builtins.isAttrs pkg && builtins.hasAttr "type" pkg && pkg.type or null == "derivation" then
      builtins.seq pkg.name true
    else if builtins.isString pkg then
      builtins.hasAttr pkg pkgs
    else
      false;
      
  testPackageList = packages:
    builtins.all testPackage packages;
    
in
pkgs.runCommand "package-availability-test" {} ''
  export USER=testuser
  
  echo "Testing package availability..."
  
  # Test shared packages
  ${if testPackageList sharedPackages then ''
    echo "✓ All shared packages are available (${toString (builtins.length sharedPackages)} packages)"
  '' else ''
    echo "✗ Some shared packages are not available"
    exit 1
  ''}
  
  # Test platform-specific packages based on current system
  ${if pkgs.stdenv.isDarwin then ''
    ${if testPackageList darwinPackages then ''
      echo "✓ All Darwin packages are available (${toString (builtins.length darwinPackages)} packages)"
    '' else ''
      echo "✗ Some Darwin packages are not available"
      exit 1
    ''}
  '' else ''
    ${if testPackageList nixosPackages then ''
      echo "✓ All NixOS packages are available (${toString (builtins.length nixosPackages)} packages)"
    '' else ''
      echo "✗ Some NixOS packages are not available"
      exit 1
    ''}
  ''}
  
  echo "All package availability tests passed!"
  touch $out
''