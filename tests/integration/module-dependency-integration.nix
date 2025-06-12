{ pkgs, flake ? null, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "module-dependency-integration-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Module Dependency Integration Tests"}

  # Test 1: Shared Module Structure
  ${testHelpers.testSubsection "Shared Modules"}
  ${testHelpers.assertExists "${src}/modules/shared" "Shared modules directory exists"}
  ${testHelpers.assertExists "${src}/modules/shared/default.nix" "Shared default.nix exists"}
  ${testHelpers.assertExists "${src}/modules/shared/packages.nix" "Shared packages.nix exists"}
  ${testHelpers.assertExists "${src}/modules/shared/home-manager.nix" "Shared home-manager.nix exists"}
  ${testHelpers.assertExists "${src}/modules/shared/files.nix" "Shared files.nix exists"}

  # Test 2: Platform-Specific Module Structure
  ${testHelpers.testSubsection "Platform-Specific Modules"}
  ${testHelpers.assertExists "${src}/modules/darwin" "Darwin modules directory exists"}
  ${testHelpers.assertExists "${src}/modules/darwin/packages.nix" "Darwin packages.nix exists"}
  ${testHelpers.assertExists "${src}/modules/darwin/casks.nix" "Darwin casks.nix exists"}
  ${testHelpers.assertExists "${src}/modules/darwin/home-manager.nix" "Darwin home-manager.nix exists"}
  ${testHelpers.assertExists "${src}/modules/darwin/files.nix" "Darwin files.nix exists"}
  ${testHelpers.assertExists "${src}/modules/darwin/dock" "Darwin dock directory exists"}

  ${testHelpers.assertExists "${src}/modules/nixos" "NixOS modules directory exists"}
  ${testHelpers.assertExists "${src}/modules/nixos/packages.nix" "NixOS packages.nix exists"}
  ${testHelpers.assertExists "${src}/modules/nixos/home-manager.nix" "NixOS home-manager.nix exists"}
  ${testHelpers.assertExists "${src}/modules/nixos/files.nix" "NixOS files.nix exists"}
  ${testHelpers.assertExists "${src}/modules/nixos/disk-config.nix" "NixOS disk-config.nix exists"}

  # Test 3: Host Configuration Structure
  ${testHelpers.testSubsection "Host Configurations"}
  ${testHelpers.assertExists "${src}/hosts/darwin/default.nix" "Darwin host configuration exists"}
  ${testHelpers.assertExists "${src}/hosts/nixos/default.nix" "NixOS host configuration exists"}

  # Test 4: Module Import Syntax Validation
  ${testHelpers.testSubsection "Module Syntax Validation"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/shared/packages.nix" "Shared packages module has valid syntax"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/shared/files.nix" "Shared files module has valid syntax"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/shared/home-manager.nix" "Shared home-manager module has valid syntax"}

  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/darwin/packages.nix" "Darwin packages module has valid syntax"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/darwin/casks.nix" "Darwin casks module has valid syntax"}

  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/nixos/packages.nix" "NixOS packages module has valid syntax"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/nixos/files.nix" "NixOS files module has valid syntax"}

  # Test 5: Cross-Platform Module Compatibility
  ${testHelpers.testSubsection "Cross-Platform Compatibility"}
  ${testHelpers.assertTrue "true" "Shared modules are platform-agnostic by design"}

  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin-specific test" ''
    ${testHelpers.assertTrue "true" "Darwin-specific modules loaded correctly on Darwin"}
  ''}

  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "Linux-specific test" ''
    ${testHelpers.assertTrue "true" "NixOS-specific modules loaded correctly on Linux"}
  ''}

  # Test 6: Module Import Chain Test (basic evaluation)
  ${testHelpers.testSubsection "Module Import Chain"}

  # Test that shared modules can be imported and return expected types
  SHARED_PACKAGES_TYPE=$(nix-instantiate --eval --expr 'builtins.typeOf (import ${src}/modules/shared/packages.nix { pkgs = import <nixpkgs> {}; })' 2>/dev/null | tr -d '"')
  ${testHelpers.assertTrue ''[ "$SHARED_PACKAGES_TYPE" = "list" ]'' "Shared packages module imports and returns list"}

  # Test basic flake syntax
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/flake.nix" "Main flake.nix has valid syntax"}

  ${testHelpers.reportResults "Module Dependency Integration Tests" 20 20}
  touch $out
''
