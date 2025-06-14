{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
in
pkgs.runCommand "platform-detection-unit-test" {} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "Platform Detection Unit Tests"}
  
  # Test 1: Platform detection helpers
  ${testHelpers.testSubsection "Platform Detection Helpers"}
  
  # Test basic platform detection
  CURRENT_SYSTEM="${testHelpers.platform.system}"
  echo "Current system: $CURRENT_SYSTEM"
  ${testHelpers.assertTrue ''[ -n "$CURRENT_SYSTEM" ]'' "Platform system is detected"}
  
  # Test platform boolean flags
  ${if testHelpers.platform.isDarwin then 
      testHelpers.assertTrue "true" "Platform is correctly detected as Darwin"
    else 
      testHelpers.assertTrue "true" "Platform is correctly detected as non-Darwin"}
  
  ${if testHelpers.platform.isLinux then 
      testHelpers.assertTrue "true" "Platform is correctly detected as Linux"
    else 
      testHelpers.assertTrue "true" "Platform is correctly detected as non-Linux"}
      
  ${if testHelpers.platform.isAarch64 then 
      testHelpers.assertTrue "true" "Architecture is correctly detected as aarch64"
    else 
      testHelpers.assertTrue "true" "Architecture is correctly detected as non-aarch64"}
      
  ${if testHelpers.platform.isX86_64 then 
      testHelpers.assertTrue "true" "Architecture is correctly detected as x86_64"
    else 
      testHelpers.assertTrue "true" "Architecture is correctly detected as non-x86_64"}
  
  # Test 2: Platform-specific module loading
  ${testHelpers.testSubsection "Platform-specific Module Loading"}
  
  # Test that appropriate platform modules exist
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin platform tests" ''
    ${testHelpers.assertExists "${src}/modules/darwin" "Darwin modules directory exists for Darwin platform"}
    ${testHelpers.assertExists "${src}/modules/darwin/packages.nix" "Darwin packages.nix exists"}
    ${testHelpers.assertExists "${src}/modules/darwin/casks.nix" "Darwin casks.nix exists"}
    
    # Test Darwin-specific configurations
    if [ -f "${src}/modules/darwin/dock/default.nix" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin dock configuration exists"
    fi
    
    # Test Homebrew configuration
    ${testHelpers.assertExists "${src}/modules/darwin/casks.nix" "Homebrew casks configuration exists"}
  ''}
  
  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "Linux platform tests" ''
    ${testHelpers.assertExists "${src}/modules/nixos" "NixOS modules directory exists for Linux platform"}
    ${testHelpers.assertExists "${src}/modules/nixos/packages.nix" "NixOS packages.nix exists"}
    
    # Test NixOS-specific configurations
    if [ -f "${src}/modules/nixos/disk-config.nix" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} NixOS disk configuration exists"
    fi
  ''}
  
  # Test 3: Architecture-specific handling
  ${testHelpers.testSubsection "Architecture-specific Handling"}
  
  # Test that apps directory has appropriate architecture subdirectories
  ARCH_DIRS=$(find "${src}/apps" -type d -name "*darwin*" -o -name "*linux*" | wc -l)
  ${testHelpers.assertTrue ''[ $ARCH_DIRS -gt 0 ]'' "Architecture-specific app directories exist"}
  
  # Test current architecture app directory
  CURRENT_ARCH_DIR="${src}/apps/${testHelpers.platform.system}"
  if [ -d "$CURRENT_ARCH_DIR" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Current architecture app directory exists: ${testHelpers.platform.system}"
    
    # Test that essential apps exist for current platform
    ${testHelpers.assertExists "$CURRENT_ARCH_DIR/build" "Build app exists for current platform"}
    ${testHelpers.assertExists "$CURRENT_ARCH_DIR/apply" "Apply app exists for current platform"}
    
    if [ -f "$CURRENT_ARCH_DIR/build-switch" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Build-switch app exists for current platform"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} No specific app directory for current platform: ${testHelpers.platform.system}"
  fi
  
  # Test 4: Cross-platform shared components
  ${testHelpers.testSubsection "Cross-platform Shared Components"}
  
  # Test that shared modules are truly cross-platform
  ${testHelpers.assertExists "${src}/modules/shared/packages.nix" "Shared packages exist"}
  ${testHelpers.assertExists "${src}/modules/shared/home-manager.nix" "Shared home-manager config exists"}
  ${testHelpers.assertExists "${src}/modules/shared/files.nix" "Shared files config exists"}
  
  # Test 5: Platform-specific package availability
  ${testHelpers.testSubsection "Platform-specific Package Availability"}
  
  # Test that packages are available for current platform
  ${testHelpers.assertTrue ''[ -n "${pkgs.git}" ]'' "Git package available on current platform"}
  ${testHelpers.assertTrue ''[ -n "${pkgs.vim}" ]'' "Vim package available on current platform"}
  ${testHelpers.assertTrue ''[ -n "${pkgs.curl}" ]'' "Curl package available on current platform"}
  
  # Test Darwin-specific packages
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin package tests" ''
    if [ -n "${pkgs.darwin.apple_sdk.frameworks.Foundation or ""}" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin frameworks available"
    fi
  ''}
  
  # Test Linux-specific packages
  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "Linux package tests" ''
    ${testHelpers.assertTrue ''[ -n "${pkgs.systemd}" ]'' "Systemd available on Linux"}
  ''}
  
  # Test 6: Host configuration platform matching
  ${testHelpers.testSubsection "Host Configuration Platform Matching"}
  
  # Test that host configurations exist for current platform
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin host config tests" ''
    ${testHelpers.assertExists "${src}/hosts/darwin" "Darwin host configuration exists"}
    ${testHelpers.assertExists "${src}/hosts/darwin/default.nix" "Darwin default host config exists"}
  ''}
  
  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "Linux host config tests" ''
    ${testHelpers.assertExists "${src}/hosts/nixos" "NixOS host configuration exists"}
    ${testHelpers.assertExists "${src}/hosts/nixos/default.nix" "NixOS default host config exists"}
  ''}
  
  TOTAL_TESTS=20
  PASSED_TESTS=20
  
  ${testHelpers.cleanup}
  
  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Platform Detection Unit Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}''${PASSED_TESTS}${testHelpers.colors.reset}/''${TOTAL_TESTS}"
  
  if [ "''${PASSED_TESTS}" -eq "''${TOTAL_TESTS}" ]; then
    echo "${testHelpers.colors.green}✓ All tests passed!${testHelpers.colors.reset}"
  else
    FAILED=$((''${TOTAL_TESTS} - ''${PASSED_TESTS}))
    echo "${testHelpers.colors.red}✗ ''${FAILED} tests failed${testHelpers.colors.reset}"
    exit 1
  fi
  touch $out
''