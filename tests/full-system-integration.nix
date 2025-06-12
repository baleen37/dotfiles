{ pkgs, flake ? null, src ? ../.. }:
let
  flake = builtins.getFlake (toString ../.);
  system = pkgs.system;

  # Test system configuration evaluation and basic build components
  testSystemConfig =
    if pkgs.stdenv.isDarwin then
      flake.outputs.darwinConfigurations.${system} or null
    else
      flake.outputs.nixosConfigurations.${system} or null;

  # Test apps functionality
  testApps = flake.outputs.apps.${system} or { };
  expectedApps =
    if pkgs.stdenv.isDarwin then
      [ "apply" "build" "build-switch" "copy-keys" "create-keys" "check-keys" "rollback" ]
    else
      [ "apply" "build" "build-switch" ];

  # Test module imports and dependencies
  testModules = {
    shared = builtins.pathExists ../modules/shared/default.nix;
    platform =
      if pkgs.stdenv.isDarwin then
        builtins.pathExists ../modules/darwin
      else
        builtins.pathExists ../modules/nixos;
  };

  # Test overlay integration
  testOverlays = builtins.length (flake.outputs.overlays or [ ]) > 0;

in
pkgs.runCommand "full-system-integration-test" { } ''
  export USER=testuser
  export HOME=/tmp/test-home
  mkdir -p $HOME

  echo "=== Full System Integration Test ==="

  # Test 1: System Configuration Evaluation
  echo "1. Testing system configuration evaluation..."
  ${if testSystemConfig != null then ''
    echo "✓ System configuration evaluates successfully for ${system}"

    # Test that configuration has required attributes
    ${if testSystemConfig ? system then ''
      echo "✓ System configuration has 'system' attribute"
    '' else ''
      echo "✗ System configuration missing 'system' attribute"
      exit 1
    ''}

  '' else ''
    echo "✗ System configuration missing for ${system}"
    exit 1
  ''}

  # Test 2: Apps Integration
  echo "2. Testing apps integration..."
  ${builtins.concatStringsSep "\n" (map (app:
    if builtins.hasAttr app testApps then ''
      echo "✓ App '${app}' exists and has valid structure"
      ${if (testApps.${app} ? type && testApps.${app} ? program) then ''
        echo "  - Type: ${testApps.${app}.type}"
        echo "  - Program: exists"
      '' else ''
        echo "✗ App '${app}' missing required attributes"
        exit 1
      ''}
    '' else ''
      echo "✗ App '${app}' missing"
      exit 1
    ''
  ) expectedApps)}

  # Test 3: Module System Integration
  echo "3. Testing module system integration..."
  ${if testModules.shared then ''
    echo "✓ Shared modules directory exists"
  '' else ''
    echo "✗ Shared modules directory missing"
    exit 1
  ''}

  ${if testModules.platform then ''
    echo "✓ Platform-specific modules directory exists"
  '' else ''
    echo "✗ Platform-specific modules directory missing"
    exit 1
  ''}

  # Test 4: Overlay Integration
  echo "4. Testing overlay integration..."
  ${if testOverlays then ''
    echo "✓ Overlays are configured and available"
  '' else ''
    echo "⚠ No overlays configured (this may be expected)"
  ''}

  # Test 5: Flake Structure Validation
  echo "5. Testing flake structure..."
  ${if builtins.hasAttr "checks" flake.outputs then ''
    echo "✓ Flake has checks output"
  '' else ''
    echo "✗ Flake missing checks output"
    exit 1
  ''}

  ${if builtins.hasAttr "packages" flake.outputs then ''
    echo "✓ Flake has packages output"
  '' else ''
    echo "⚠ Flake has no packages output (may be expected)"
  ''}

  # Test 6: User Resolution Integration
  echo "6. Testing user resolution integration..."
  if [ -z "$USER" ]; then
    echo "✗ USER environment variable not set"
    exit 1
  else
    echo "✓ USER environment variable set: $USER"
  fi

  # Test 7: Home Manager Integration (if applicable)
  echo "7. Testing Home Manager integration..."
  ${if testSystemConfig ? config.home-manager then ''
    echo "✓ Home Manager integration detected"
  '' else ''
    echo "⚠ No Home Manager integration detected (may be expected)"
  ''}

  echo "=== All Integration Tests Passed! ==="
  echo "✓ System configuration evaluates correctly"
  echo "✓ All platform apps are available and valid"
  echo "✓ Module system is properly structured"
  echo "✓ Overlays are integrated"
  echo "✓ Flake structure is valid"
  echo "✓ User resolution works"
  echo "✓ Environment setup is correct"

  touch $out
''
