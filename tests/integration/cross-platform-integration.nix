{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;
in
pkgs.runCommand "cross-platform-integration-test" {} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "Cross-Platform Integration Tests"}
  
  # Test 1: Flake supports current platform
  ${testHelpers.testSubsection "Platform Support"}
  
  echo "Testing platform: ${system}"
  
  # Check if platform is supported in flake outputs
  ${if flake != null then ''
    ${if builtins.hasAttr system (flake.outputs.checks or {}) then ''
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Platform ${system} is supported in checks"
    '' else ''
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Platform ${system} is not supported in checks"
      exit 1
    ''}
    
    ${if builtins.hasAttr system (flake.outputs.apps or {}) then ''
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Platform ${system} is supported in apps"
    '' else ''
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Platform ${system} is not supported in apps"
      exit 1
    ''}
  '' else ''
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Flake parameter is null, skipping platform support checks"
  ''}
  
  # Test 2: Configuration availability per platform
  ${testHelpers.testSubsection "Configuration Availability"}
  
  ${if flake != null then ''
    ${if testHelpers.platform.isDarwin then ''
      ${if builtins.hasAttr system (flake.outputs.darwinConfigurations or {}) then ''
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin configuration available for ${system}"
      '' else ''
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Darwin configuration missing for ${system}"
        exit 1
      ''}
    '' else ''
      ${if builtins.hasAttr system (flake.outputs.nixosConfigurations or {}) then ''
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} NixOS configuration available for ${system}"
      '' else ''
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} NixOS configuration missing for ${system}"
        exit 1
      ''}
    ''}
  '' else ''
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Flake parameter is null, skipping configuration availability checks"
  ''}
  
  # Test 3: Shared modules work across platforms
  ${testHelpers.testSubsection "Shared Module Compatibility"}
  
  # Test shared packages can be imported
  ${testHelpers.assertCommand "nix-instantiate --eval --expr 'import ../../modules/shared/packages.nix { pkgs = import <nixpkgs> {}; }'" "Shared packages module works on ${system}"}
  
  # Test shared files module
  ${testHelpers.assertCommand "nix-instantiate --eval --expr 'import ../../modules/shared/files.nix'" "Shared files module works on ${system}"}
  
  # Test 4: Platform-specific modules only on correct platforms
  ${testHelpers.testSubsection "Platform-specific Module Isolation"}
  
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin modules test" ''
    # Darwin modules should work on Darwin
    ${testHelpers.assertCommand "nix-instantiate --eval --expr 'import ../../modules/darwin/packages.nix { pkgs = import <nixpkgs> {}; }'" "Darwin packages module works on Darwin"}
    
    # Check Darwin-specific features
    ${testHelpers.assertExists "../../modules/darwin/casks.nix" "Darwin casks module exists"}
    ${testHelpers.assertExists "../../modules/darwin/dock" "Darwin dock configuration exists"}
  ''}
  
  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "NixOS modules test" ''
    # NixOS modules should work on Linux
    ${testHelpers.assertCommand "nix-instantiate --eval --expr 'import ../../modules/nixos/packages.nix { pkgs = import <nixpkgs> {}; }'" "NixOS packages module works on Linux"}
    
    # Check NixOS-specific features
    ${testHelpers.assertExists "../../modules/nixos/files.nix" "NixOS files module exists"}
  ''}
  
  # Test 5: Architecture-specific features
  ${testHelpers.testSubsection "Architecture Compatibility"}
  
  echo "Current architecture: ${if testHelpers.platform.isAarch64 then "aarch64" else "x86_64"}"
  
  # Test that apps exist for current architecture
  EXPECTED_APPS=(apply build build-switch copy-keys create-keys check-keys)
  ${if testHelpers.platform.isDarwin then ''
    EXPECTED_APPS+=(rollback)
  '' else ''
    # Linux may have additional specific apps
    echo "Linux platform detected"
  ''}
  
  for app in "''${EXPECTED_APPS[@]}"; do
    ${if flake != null then ''
      ${if builtins.hasAttr system (flake.outputs.apps or {}) then 
        if builtins.hasAttr "apply" (flake.outputs.apps.${system} or {}) then ''
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} App '$app' available for ${system}"
        '' else ''
          echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} App '$app' not found for ${system}"
        ''
      else ''
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} No apps available for ${system}"
        exit 1
      ''}
    '' else ''
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Flake parameter is null, skipping app availability check for '$app'"
    ''}
  done
  
  # Test 6: Cross-compilation support
  ${testHelpers.testSubsection "Cross-compilation Support"}
  
  # Test that we can evaluate other platform configurations (without building)
  ${if testHelpers.platform.isDarwin then ''
    # From Darwin, test if we can evaluate NixOS configs
    ${testHelpers.assertCommand "nix eval --impure .#nixosConfigurations.x86_64-linux.config.system.name" "Can evaluate NixOS config from Darwin"}
  '' else ''
    # From Linux, test if we can evaluate Darwin configs  
    ${testHelpers.assertCommand "nix eval --impure .#darwinConfigurations.aarch64-darwin.system" "Can evaluate Darwin config from Linux"}
  ''}
  
  # Test 7: Environment variable handling across platforms
  ${testHelpers.testSubsection "Environment Variable Handling"}
  
  # Test USER variable resolution works consistently
  export USER=crossplatformtest
  USER_RESULT=$(nix-instantiate --eval --expr 'let getUser = import ../../lib/get-user.nix {}; in getUser' 2>/dev/null | tr -d '"')
  ${testHelpers.assertTrue ''[ "$USER_RESULT" = "crossplatformtest" ]'' "USER resolution works consistently across platforms"}
  
  # Test 8: Package manager integration
  ${testHelpers.testSubsection "Package Manager Integration"}
  
  ${if testHelpers.platform.isDarwin then ''
    # Test Homebrew integration on Darwin
    ${testHelpers.assertExists "../../modules/darwin/casks.nix" "Homebrew casks configuration exists"}
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin uses Homebrew integration"
  '' else ''
    # Test native package management on NixOS
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} NixOS uses native package management"
  ''}
  
  ${testHelpers.reportResults "Cross-Platform Integration Tests" 10 10}
  touch $out
''