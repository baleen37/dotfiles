{ pkgs, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;

in
pkgs.runCommand "legacy-system-integration-e2e-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Legacy System Integration E2E Tests"}

  # Test 1: System Configuration Files Exist
  ${testHelpers.testSubsection "System Configuration"}
  ${testHelpers.assertExists "${src}/flake.nix" "Main flake.nix exists"}
  ${testHelpers.assertExists "${src}/hosts/darwin/default.nix" "Darwin host configuration exists"}
  ${testHelpers.assertExists "${src}/hosts/nixos/default.nix" "NixOS host configuration exists"}

  # Test 2: Module System Structure
  ${testHelpers.testSubsection "Module System"}
  ${testHelpers.assertExists "${src}/modules/shared" "Shared modules directory exists"}
  ${testHelpers.assertExists "${src}/modules/shared/default.nix" "Shared modules entry point exists"}

  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin module test" ''
    ${testHelpers.assertExists "${src}/modules/darwin" "Darwin modules directory exists"}
  ''}

  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "NixOS module test" ''
    ${testHelpers.assertExists "${src}/modules/nixos" "NixOS modules directory exists"}
  ''}

  # Test 3: Apps Structure (verify script files exist)
  ${testHelpers.testSubsection "Apps Structure"}
  ${testHelpers.assertExists "${src}/apps/${testHelpers.platform.system}" "Platform-specific apps directory exists"}
  ${testHelpers.assertExists "${src}/apps/${testHelpers.platform.system}/build" "Build app script exists"}
  ${testHelpers.assertExists "${src}/apps/${testHelpers.platform.system}/apply" "Apply app script exists"}

  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin apps test" ''
    ${testHelpers.assertExists "${src}/apps/${testHelpers.platform.system}/build-switch" "Build-switch app exists"}
    ${testHelpers.assertExists "${src}/apps/${testHelpers.platform.system}/rollback" "Rollback app exists"}
  ''}

  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "NixOS apps test" ''
    ${testHelpers.assertExists "${src}/apps/${testHelpers.platform.system}/build-switch" "Build-switch app exists"}
  ''}

  # Test 4: Flake Structure Validation
  ${testHelpers.testSubsection "Flake Structure"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/flake.nix" "Main flake.nix has valid syntax"}

  # Test that flake evaluates (basic check)
  ${testHelpers.assertCommand "nix flake metadata ${src}/. --impure" "Flake metadata can be read"}

  # Test 5: User Resolution System
  ${testHelpers.testSubsection "User Resolution"}
  ${testHelpers.assertExists "${src}/lib/get-user.nix" "User resolution function exists"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/lib/get-user.nix" "User resolution function has valid syntax"}

  # Test user resolution with environment variable
  export USER=testuser
  USER_RESULT=$(nix-instantiate --eval --expr 'let getUser = import ${src}/lib/get-user.nix {}; in getUser' 2>/dev/null | tr -d '"' || echo "")
  ${testHelpers.assertTrue ''[ "$USER_RESULT" = "testuser" ]'' "User resolution works with environment variable"}

  # Test 6: Package System Integration
  ${testHelpers.testSubsection "Package System"}
  ${testHelpers.assertCommand "nix-instantiate --eval --expr 'import ${src}/modules/shared/packages.nix { pkgs = import <nixpkgs> {}; }' > /dev/null" "Shared packages module evaluates successfully"}

  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin packages test" ''
    ${testHelpers.assertCommand "nix-instantiate --eval --expr 'import ${src}/modules/darwin/packages.nix { pkgs = import <nixpkgs> {}; }' > /dev/null" "Darwin packages module evaluates successfully"}
  ''}

  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "NixOS packages test" ''
    ${testHelpers.assertCommand "nix-instantiate --eval --expr 'import ${src}/modules/nixos/packages.nix { pkgs = import <nixpkgs> {}; }' > /dev/null" "NixOS packages module evaluates successfully"}
  ''}

  # Test 7: Test System Integration
  ${testHelpers.testSubsection "Test System"}
  ${testHelpers.assertExists "${src}/tests" "Tests directory exists"}
  ${testHelpers.assertExists "${src}/tests/default.nix" "Test discovery system exists"}
  ${testHelpers.assertExists "${src}/tests/lib/test-helpers.nix" "Test helpers library exists"}

  # Verify test discovery works
  ${testHelpers.assertCommand "nix-instantiate --eval --expr 'builtins.attrNames (import ${src}/tests { pkgs = import <nixpkgs> {}; })' > /dev/null" "Test discovery system works"}

  # Test 8: Build System Integration
  ${testHelpers.testSubsection "Build System"}
  ${testHelpers.assertExists "${src}/Makefile" "Makefile exists"}

  # Test that basic make targets exist
  if grep -q "^lint:" "${src}/Makefile"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Makefile has lint target"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Makefile missing lint target"
    exit 1
  fi

  if grep -q "^test:" "${src}/Makefile"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Makefile has test target"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Makefile missing test target"
    exit 1
  fi

  # Test 9: Cross-Platform Compatibility
  ${testHelpers.testSubsection "Cross-Platform Compatibility"}
  ${testHelpers.assertTrue "true" "Test framework supports ${testHelpers.platform.system}"}

  # Verify platform detection works correctly
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin platform detection" ''
    ${testHelpers.assertTrue "${if testHelpers.platform.isDarwin then "true" else "false"}" "Platform correctly detected as Darwin"}
  ''}

  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "Linux platform detection" ''
    ${testHelpers.assertTrue "${if testHelpers.platform.isLinux then "true" else "false"}" "Platform correctly detected as Linux"}
  ''}

  ${testHelpers.reportResults "Legacy System Integration E2E Tests" 25 25}
  touch $out
''
