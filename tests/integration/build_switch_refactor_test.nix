# Build-switch refactor integration test
# Tests that the refactored build-switch scripts maintain functionality

{ pkgs, lib, ... }:

let
  # Test script that validates all build-switch scripts exist and are executable
  testScript = pkgs.writeShellScript "test-build-switch-refactor" ''
    set -euo pipefail
    
    echo "Testing build-switch refactor..."
    
    # Test all platform scripts exist and are executable
    for platform in aarch64-darwin x86_64-darwin aarch64-linux x86_64-linux; do
      script="apps/$platform/build-switch"
      echo "  Checking $script..."
      
      if [ ! -f "$script" ]; then
        echo "ERROR: $script does not exist"
        exit 1
      fi
      
      if [ ! -x "$script" ]; then
        echo "ERROR: $script is not executable"
        exit 1
      fi
      
      # Check that script sources the common file
      if ! grep -q "build-switch-common.sh" "$script"; then
        echo "ERROR: $script does not source common script"
        exit 1
      fi
      
      # Check platform-specific variables are set
      if ! grep -q "SYSTEM_TYPE=" "$script"; then
        echo "ERROR: $script does not set SYSTEM_TYPE"
        exit 1
      fi
      
      if ! grep -q "PLATFORM_TYPE=" "$script"; then
        echo "ERROR: $script does not set PLATFORM_TYPE"
        exit 1
      fi
      
      echo "  ✓ $script looks good"
    done
    
    # Test common script exists
    if [ ! -f "scripts/build-switch-common.sh" ]; then
      echo "ERROR: Common script does not exist"
      exit 1
    fi
    
    # Check common script has key functions
    common_script="scripts/build-switch-common.sh"
    for func in execute_build_switch log_header log_step check_sudo_requirement; do
      if ! grep -q "$func" "$common_script"; then
        echo "ERROR: Common script missing function: $func"
        exit 1
      fi
    done
    
    echo "✓ All build-switch refactor tests passed!"
  '';

in {
  name = "build-switch-refactor-integration-test";
  
  script = ''
    cd ${lib.escapeShellArg (toString ./../..)}
    ${testScript}
  '';
  
  meta = {
    description = "Test that build-switch refactor maintains functionality";
    maintainers = [ ];
  };
}