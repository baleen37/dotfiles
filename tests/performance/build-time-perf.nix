{ pkgs, flake ? null, src ? ../.. }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  system = pkgs.system;
in
pkgs.runCommand "build-time-performance-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build Time Performance Tests"}

  # Test 1: Flake evaluation speed
  ${testHelpers.testSubsection "Flake Evaluation Performance"}

  ${testHelpers.benchmark "Flake show command" ''
    nix flake show --impure --no-warn-dirty >/dev/null 2>&1
  ''}

  ${testHelpers.benchmark "Flake metadata" ''
    nix flake metadata --impure --no-warn-dirty >/dev/null 2>&1
  ''}

  # Test 2: Configuration evaluation speed
  ${testHelpers.testSubsection "Configuration Evaluation Performance"}

  ${testHelpers.benchmark "System configuration evaluation" ''
    ${if testHelpers.platform.isDarwin then ''
      nix eval --impure .#darwinConfigurations.${system}.system --no-warn-dirty >/dev/null 2>&1
    '' else ''
      nix eval --impure .#nixosConfigurations.${system}.config.system.build.toplevel --no-warn-dirty >/dev/null 2>&1
    ''}
  ''}

  ${testHelpers.benchmark "All system configurations evaluation" ''
    for target in aarch64-darwin x86_64-darwin; do
      nix eval --impure .#darwinConfigurations.$target.system --no-warn-dirty >/dev/null 2>&1 || true
    done
    for target in x86_64-linux aarch64-linux; do
      nix eval --impure .#nixosConfigurations.$target.config.system.build.toplevel --no-warn-dirty >/dev/null 2>&1 || true
    done
  ''}

  # Test 3: Test evaluation speed
  ${testHelpers.testSubsection "Test Evaluation Performance"}

  ${testHelpers.benchmark "All checks evaluation" ''
    nix flake check --impure --no-build --no-warn-dirty >/dev/null 2>&1
  ''}

  ${testHelpers.benchmark "Single test evaluation" ''
    nix eval --impure .#checks.${system}.simple --no-warn-dirty >/dev/null 2>&1
  ''}

  # Test 4: App evaluation speed
  ${testHelpers.testSubsection "Application Evaluation Performance"}

  ${testHelpers.benchmark "All apps evaluation" ''
    nix eval --impure .#apps.${system} --no-warn-dirty >/dev/null 2>&1
  ''}

  APPS=(apply build build-switch copy-keys create-keys check-keys)
  ${if testHelpers.platform.isDarwin then ''
    APPS+=(rollback)
  '' else ''
    echo "Testing Linux apps"
  ''}

  for app in "''${APPS[@]}"; do
    ${testHelpers.benchmark "App $app evaluation" ''
      nix eval --impure .#apps.${system}.$app --no-warn-dirty >/dev/null 2>&1
    ''}
  done

  # Test 5: Package evaluation speed
  ${testHelpers.testSubsection "Package Evaluation Performance"}

  ${testHelpers.benchmark "Shared packages evaluation" ''
    nix eval --impure --expr 'import ./modules/shared/packages.nix { pkgs = import <nixpkgs> {}; }' --no-warn-dirty >/dev/null 2>&1
  ''}

  ${if testHelpers.platform.isDarwin then ''
    ${testHelpers.benchmark "Darwin packages evaluation" ''
      nix eval --impure --expr 'import ./modules/darwin/packages.nix { pkgs = import <nixpkgs> {}; }' --no-warn-dirty >/dev/null 2>&1
    ''}
  '' else ''
    ${testHelpers.benchmark "NixOS packages evaluation" ''
      nix eval --impure --expr 'import ./modules/nixos/packages.nix { pkgs = import <nixpkgs> {}; }' --no-warn-dirty >/dev/null 2>&1
    ''}
  ''}

  # Test 6: Memory usage simulation
  ${testHelpers.testSubsection "Memory Usage Analysis"}

  echo "Analyzing memory usage patterns..."

  # Test evaluation with different complexity levels
  ${testHelpers.benchmark "Simple evaluation" ''
    nix eval --impure --expr '1 + 1' --no-warn-dirty >/dev/null 2>&1
  ''}

  ${testHelpers.benchmark "Complex evaluation" ''
    nix eval --impure --expr 'builtins.length (import ./modules/shared/packages.nix { pkgs = import <nixpkgs> {}; })' --no-warn-dirty >/dev/null 2>&1
  ''}

  # Test 7: Dependency resolution speed
  ${testHelpers.testSubsection "Dependency Resolution Performance"}

  ${testHelpers.benchmark "Nixpkgs import" ''
    nix eval --impure --expr 'import <nixpkgs> {}' --no-warn-dirty >/dev/null 2>&1
  ''}

  ${testHelpers.benchmark "Home Manager import" ''
    nix eval --impure --expr '(builtins.getFlake "github:nix-community/home-manager").outputs' --no-warn-dirty >/dev/null 2>&1 || true
  ''}

  # Test 8: Parallel evaluation capability
  ${testHelpers.testSubsection "Parallel Evaluation Capability"}

  echo "Testing parallel evaluation patterns..."

  # Test multiple simultaneous evaluations
  ${testHelpers.benchmark "Parallel configuration evaluation" ''
    (nix eval --impure .#darwinConfigurations.aarch64-darwin.system --no-warn-dirty >/dev/null 2>&1 &
     nix eval --impure .#darwinConfigurations.x86_64-darwin.system --no-warn-dirty >/dev/null 2>&1 &
     wait) || true
  ''}

  # Test 9: Cache effectiveness
  ${testHelpers.testSubsection "Cache Effectiveness"}

  echo "Testing evaluation cache effectiveness..."

  # First evaluation (cold)
  ${testHelpers.benchmark "Cold evaluation" ''
    nix eval --impure .#checks.${system}.simple --no-warn-dirty >/dev/null 2>&1
  ''}

  # Second evaluation (warm)
  ${testHelpers.benchmark "Warm evaluation" ''
    nix eval --impure .#checks.${system}.simple --no-warn-dirty >/dev/null 2>&1
  ''}

  # Test 10: Resource usage patterns
  ${testHelpers.testSubsection "Resource Usage Patterns"}

  echo "Analyzing resource usage patterns..."

  # Test evaluation with different input sizes
  ${testHelpers.benchmark "Small configuration" ''
    nix eval --impure --expr '{ a = 1; b = 2; }' --no-warn-dirty >/dev/null 2>&1
  ''}

  ${testHelpers.benchmark "Medium configuration" ''
    nix eval --impure .#apps.${system} --no-warn-dirty >/dev/null 2>&1
  ''}

  ${testHelpers.benchmark "Large configuration" ''
    ${if testHelpers.platform.isDarwin then ''
      nix eval --impure .#darwinConfigurations.${system} --no-warn-dirty >/dev/null 2>&1
    '' else ''
      nix eval --impure .#nixosConfigurations.${system} --no-warn-dirty >/dev/null 2>&1
    ''}
  ''}

  # Performance summary
  echo ""
  echo "${testHelpers.colors.blue}=== Performance Test Summary ===${testHelpers.colors.reset}"
  echo "✓ All performance benchmarks completed"
  echo "✓ Timing data collected for optimization analysis"
  echo "✓ Cache effectiveness measured"
  echo "✓ Resource usage patterns analyzed"

  touch $out
''
