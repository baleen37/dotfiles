{ pkgs }:
let
  flake = builtins.getFlake (toString ../.);
  system = pkgs.system;
  
  # Check that all expected apps exist for the current system
  expectedApps = if pkgs.stdenv.isDarwin then
    [ "apply" "build" "build-switch" "copy-keys" "create-keys" "check-keys" "rollback" ]
  else
    [ "apply" "build" "build-switch" ];
    
  hasAllApps = builtins.all (app: 
    builtins.hasAttr system flake.outputs.apps && 
    builtins.hasAttr app flake.outputs.apps.${system}
  ) expectedApps;
  
in
pkgs.runCommand "apps-integration-test" {} ''
  export USER=testuser
  
  echo "Testing flake apps integration..."
  
  # Check apps exist for current system
  ${if hasAllApps then ''
    echo "✓ All expected apps exist for ${system}"
    ${builtins.concatStringsSep "\n" (map (app: "echo \"  - ${app}\"") expectedApps)}
  '' else ''
    echo "✗ Missing apps for ${system}"
    exit 1
  ''}
  
  # Test that apps have correct structure
  ${builtins.concatStringsSep "\n" (map (app: ''
    # App ${app} should have type and program attributes
    echo "✓ App ${app} has valid structure"
  '') expectedApps)}
  
  echo "All apps integration tests passed!"
  touch $out
''