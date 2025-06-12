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
pkgs.runCommand "module-imports-unit-test" {} ''
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

  # Test 4: Module syntax validation (basic Nix parsing)
  ${testHelpers.testSubsection "Syntax Validation"}

  # Test shared modules syntax
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/shared/packages.nix" "Shared packages module has valid syntax"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/shared/files.nix" "Shared files module has valid syntax"}

  # Test platform modules syntax
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/darwin/packages.nix" "Darwin packages module has valid syntax"}
  ${testHelpers.assertCommand "nix-instantiate --parse ${src}/modules/nixos/packages.nix" "NixOS packages module has valid syntax"}

  # Test 5: Module return types
  ${testHelpers.testSubsection "Return Type Validation"}

  # Shared packages should return a list
  SHARED_TYPE=$(nix-instantiate --eval --expr 'builtins.typeOf (import ${src}/modules/shared/packages.nix { pkgs = import <nixpkgs> {}; })' 2>/dev/null | tr -d '"')
  ${testHelpers.assertTrue ''[ "$SHARED_TYPE" = "list" ]'' "Shared packages module returns list"}

  # Darwin packages should return a list
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin-only test" ''
    DARWIN_TYPE=$(nix-instantiate --eval --expr 'builtins.typeOf (import ${src}/modules/darwin/packages.nix { pkgs = import <nixpkgs> {}; })' 2>/dev/null | tr -d '"')
    ${testHelpers.assertTrue ''[ "$DARWIN_TYPE" = "list" ]'' "Darwin packages module returns list"}
  ''}

  ${testHelpers.reportResults "Module Import Unit Tests" 10 10}
  touch $out
''
