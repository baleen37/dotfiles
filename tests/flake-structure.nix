{ pkgs }:
let
  flake = builtins.getFlake (toString ../.);
  system = pkgs.system;
  
  # Helper function to check attribute existence
  hasAttr = path: obj:
    builtins.foldl' (acc: key: acc && builtins.hasAttr key obj) true path;
    
  # Check flake outputs structure
  hasApps = builtins.hasAttr "apps" flake.outputs;
  hasChecks = builtins.hasAttr "checks" flake.outputs;
  hasDarwinConfigs = builtins.hasAttr "darwinConfigurations" flake.outputs;
  hasNixosConfigs = builtins.hasAttr "nixosConfigurations" flake.outputs;
  hasDevShells = builtins.hasAttr "devShells" flake.outputs;
  
  # Check system-specific outputs
  hasSystemApps = hasApps && builtins.hasAttr system flake.outputs.apps;
  hasSystemChecks = hasChecks && builtins.hasAttr system flake.outputs.checks;
  hasSystemDevShell = hasDevShells && builtins.hasAttr system flake.outputs.devShells;
  
in
pkgs.runCommand "flake-structure-test" {} ''
  export USER=testuser
  
  echo "Testing flake output structure..."
  
  # Test top-level outputs exist
  ${if hasApps then ''
    echo "✓ apps output exists"
  '' else ''
    echo "✗ apps output missing"
    exit 1
  ''}
  
  ${if hasChecks then ''
    echo "✓ checks output exists"
  '' else ''
    echo "✗ checks output missing"  
    exit 1
  ''}
  
  ${if hasDarwinConfigs then ''
    echo "✓ darwinConfigurations output exists"
  '' else ''
    echo "✗ darwinConfigurations output missing"
    exit 1
  ''}
  
  ${if hasNixosConfigs then ''
    echo "✓ nixosConfigurations output exists"
  '' else ''
    echo "✗ nixosConfigurations output missing"
    exit 1
  ''}
  
  ${if hasDevShells then ''
    echo "✓ devShells output exists"
  '' else ''
    echo "✗ devShells output missing"
    exit 1
  ''}
  
  # Test system-specific outputs
  ${if hasSystemApps then ''
    echo "✓ apps.${system} exists"
  '' else ''
    echo "✗ apps.${system} missing"
    exit 1
  ''}
  
  ${if hasSystemChecks then ''
    echo "✓ checks.${system} exists"
  '' else ''
    echo "✗ checks.${system} missing"
    exit 1
  ''}
  
  ${if hasSystemDevShell then ''
    echo "✓ devShells.${system} exists"
  '' else ''
    echo "✗ devShells.${system} missing"
    exit 1
  ''}
  
  echo "All flake structure tests passed!"
  touch $out
''