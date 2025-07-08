# Unit test for lib/flake-config.nix module
# Tests that the flake config module exports correct structure and functions

{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "flake-config-module-unit-test" {
  buildInputs = [ pkgs.nix ];
  src = src;
} ''
  echo "Testing flake-config.nix module..."

  # Copy source to build directory for testing
  cp -r $src/* .

  # Test 1: Module should be importable
  echo "Test 1: Checking module import..."

  # Create a test Nix expression that imports the module
  cat > test-import.nix << 'EOF'
  let
    flakeConfig = import ./lib/flake-config.nix;
  in
  flakeConfig
  EOF

  # This should not throw an error
  if nix-instantiate --eval --expr "import ./test-import.nix" >/dev/null 2>error.log; then
    echo "✓ Module import: PASSED"
  else
    echo "✗ Module import: FAILED"
    echo "Error details:"
    cat error.log
    exit 1
  fi

  # Test 2: Module should have required top-level attributes
  echo "Test 2: Checking required attributes..."

  cat > test-attributes.nix << 'EOF'
  let
    flakeConfig = import ./lib/flake-config.nix;
    requiredAttrs = [ "description" "inputs" "systemArchitectures" "utils" ];
    hasAllAttrs = builtins.all (attr: builtins.hasAttr attr flakeConfig) requiredAttrs;
  in
  hasAllAttrs
  EOF

  if nix-instantiate --eval --expr "import ./test-attributes.nix" | grep -q "true"; then
    echo "✓ Required attributes: PASSED"
  else
    echo "✗ Required attributes: FAILED"
    exit 1
  fi

  # Test 3: systemArchitectures should have correct structure
  echo "Test 3: Checking systemArchitectures structure..."

  cat > test-architectures.nix << 'EOF'
  let
    flakeConfig = import ./lib/flake-config.nix;
    archs = flakeConfig.systemArchitectures;
    hasLinux = archs ? linux && builtins.isList archs.linux;
    hasDarwin = archs ? darwin && builtins.isList archs.darwin;
    hasAll = archs ? all && builtins.isList archs.all;
  in
  hasLinux && hasDarwin && hasAll
  EOF

  if nix-instantiate --eval --expr "import ./test-architectures.nix" | grep -q "true"; then
    echo "✓ System architectures structure: PASSED"
  else
    echo "✗ System architectures structure: FAILED"
    exit 1
  fi

  # Test 4: Utils should be a function that accepts nixpkgs
  echo "Test 4: Checking utils function..."

  cat > test-utils.nix << 'EOF'
  let
    flakeConfig = import ./lib/flake-config.nix;
    # Mock nixpkgs for testing
    mockNixpkgs = { lib = { genAttrs = systems: f: {}; }; legacyPackages = {}; };
    utils = flakeConfig.utils mockNixpkgs;
    hasForAllSystems = utils ? forAllSystems && builtins.isFunction utils.forAllSystems;
    hasGetUser = utils ? getUser;
    hasMkDevShell = utils ? mkDevShell && builtins.isFunction utils.mkDevShell;
  in
  hasForAllSystems && hasGetUser && hasMkDevShell
  EOF

  if nix-instantiate --eval --expr "import ./test-utils.nix" | grep -q "true"; then
    echo "✓ Utils function structure: PASSED"
  else
    echo "✗ Utils function structure: FAILED"
    exit 1
  fi

  echo "All flake-config module tests passed!"
  touch $out
''
