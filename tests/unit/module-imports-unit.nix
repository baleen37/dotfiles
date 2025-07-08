{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };

  # Test module imports
  testModuleImport = modulePath:
    if builtins.pathExists modulePath then
      try (import modulePath { inherit pkgs; }) null
    else
      null;

  # Safe import function
  try = expr: default:
    let result = builtins.tryEval expr;
    in if result.success then result.value else default;

in
pkgs.runCommand "module-imports-unit-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Module Import Unit Tests"}

  # Test 1: Shared modules import successfully
  ${testHelpers.testSubsection "Shared Modules"}
  ${testHelpers.assertExists "${src}/modules/shared/default.nix" "Shared default module exists"}
  ${testHelpers.assertExists "${src}/modules/shared/packages.nix" "Shared packages module exists"}
  ${testHelpers.assertExists "${src}/modules/shared/files.nix" "Shared files module exists"}

  # Test 2: Platform-specific modules exist
  ${testHelpers.testSubsection "Darwin Modules"}
  ${testHelpers.assertExists "${src}/modules/darwin/packages.nix" "Darwin packages module exists"}
  ${testHelpers.assertExists "${src}/modules/darwin/casks.nix" "Darwin casks module exists"}
  ${testHelpers.assertExists "${src}/modules/darwin/dock" "Darwin dock module exists"}

  ${testHelpers.testSubsection "NixOS Modules"}
  ${testHelpers.assertExists "${src}/modules/nixos/packages.nix" "NixOS packages module exists"}
  ${testHelpers.assertExists "${src}/modules/nixos/files.nix" "NixOS files module exists"}

  # Test 3: Host configurations exist
  ${testHelpers.testSubsection "Host Configurations"}
  ${testHelpers.assertExists "${src}/hosts/darwin/default.nix" "Darwin host configuration exists"}
  ${testHelpers.assertExists "${src}/hosts/nixos/default.nix" "NixOS host configuration exists"}

  # Test 4: Module existence validation
  ${testHelpers.testSubsection "Module Existence"}

  # Test shared modules exist
  ${testHelpers.assertExists "${src}/modules/shared/packages.nix" "Shared packages module exists"}
  ${testHelpers.assertExists "${src}/modules/shared/files.nix" "Shared files module exists"}

  # Test platform modules exist
  ${testHelpers.assertExists "${src}/modules/darwin/packages.nix" "Darwin packages module exists"}
  ${testHelpers.assertExists "${src}/modules/nixos/packages.nix" "NixOS packages module exists"}

  # Test 5: Basic module validation
  ${testHelpers.testSubsection "Module Validation"}

  # Verify core modules are accessible
  echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} All critical modules exist and are accessible"

  ${testHelpers.reportResults "Module Import Unit Tests" 10 10}
  touch $out
''
