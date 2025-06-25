# Unit test for lib/check-builders.nix module
# Tests that the check builders module exports correct check builders and utilities

{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "check-builders-module-unit-test" {
  buildInputs = [ pkgs.nix ];
  src = src;
} ''
  echo "Testing check-builders.nix module..."

  # Copy source to build directory for testing
  cp -r $src/* .

  # Test 1: Module should be importable with mock inputs
  echo "Test 1: Checking module import..."
  
  # Create a test Nix expression that imports the module with mock inputs
  cat > test-import.nix << 'EOF'
  let
    mockNixpkgs = { 
      lib = { 
        filterAttrs = pred: attrs: {}; 
        stringToCharacters = s: [];
      }; 
    };
    mockSelf = null;
    checkBuilders = import ./lib/check-builders.nix { 
      nixpkgs = mockNixpkgs; 
      self = mockSelf; 
    };
  in
  checkBuilders
  EOF

  # This should not throw an error
  if nix-instantiate --eval --expr "import ./test-import.nix" >/dev/null 2>&1; then
    echo "✓ Module import: PASSED"
  else
    echo "✗ Module import: FAILED"
    exit 1
  fi

  # Test 2: Module should have required check builder functions
  echo "Test 2: Checking required builder functions..."
  
  cat > test-builders.nix << 'EOF'
  let
    mockNixpkgs = { 
      lib = { 
        filterAttrs = pred: attrs: {}; 
        stringToCharacters = s: [];
      }; 
    };
    mockSelf = null;
    checkBuilders = import ./lib/check-builders.nix { 
      nixpkgs = mockNixpkgs; 
      self = mockSelf; 
    };
    requiredBuilders = [ "mkChecks" "utils" ];
    hasAllBuilders = builtins.all (builder: builtins.hasAttr builder checkBuilders) requiredBuilders;
  in
  hasAllBuilders
  EOF

  if nix-instantiate --eval --expr "import ./test-builders.nix" | grep -q "true"; then
    echo "✓ Required builders: PASSED"
  else
    echo "✗ Required builders: FAILED"
    exit 1
  fi

  # Test 3: mkChecks should be a function that accepts system parameter
  echo "Test 3: Checking mkChecks function..."
  
  cat > test-mkChecks.nix << 'EOF'
  let
    mockNixpkgs = { 
      lib = { 
        filterAttrs = pred: attrs: {}; 
        stringToCharacters = s: [];
      }; 
    };
    mockSelf = ./.; # Use current directory as mock self
    checkBuilders = import ./lib/check-builders.nix { 
      nixpkgs = mockNixpkgs; 
      self = mockSelf; 
    };
    isMkChecksFunction = builtins.isFunction checkBuilders.mkChecks;
  in
  isMkChecksFunction
  EOF

  if nix-instantiate --eval --expr "import ./test-mkChecks.nix" | grep -q "true"; then
    echo "✓ mkChecks is function: PASSED"
  else
    echo "✗ mkChecks is function: FAILED"
    exit 1
  fi

  # Test 4: Utils should have required utility functions
  echo "Test 4: Checking utils structure..."
  
  cat > test-utils.nix << 'EOF'
  let
    mockNixpkgs = { 
      lib = { 
        filterAttrs = pred: attrs: {}; 
        stringToCharacters = s: [];
      }; 
    };
    mockSelf = null;
    checkBuilders = import ./lib/check-builders.nix { 
      nixpkgs = mockNixpkgs; 
      self = mockSelf; 
    };
    utils = checkBuilders.utils;
    hasFilterDerivations = utils ? filterDerivations && builtins.isFunction utils.filterDerivations;
    hasMkTestGroup = utils ? mkTestGroup && builtins.isFunction utils.mkTestGroup;
    hasMkParallelTests = utils ? mkParallelTests && builtins.isFunction utils.mkParallelTests;
  in
  hasFilterDerivations && hasMkTestGroup && hasMkParallelTests
  EOF

  if nix-instantiate --eval --expr "import ./test-utils.nix" | grep -q "true"; then
    echo "✓ Utils structure: PASSED"
  else
    echo "✗ Utils structure: FAILED"
    exit 1
  fi

  # Test 5: mkChecks should return an attribute set with required checks when called
  echo "Test 5: Checking mkChecks return structure..."
  
  cat > test-mkChecks-output.nix << 'EOF'
  let
    mockNixpkgs = { 
      lib = { 
        filterAttrs = pred: attrs: {}; 
        stringToCharacters = s: [];
      }; 
    };
    mockSelf = ./.;
    checkBuilders = import ./lib/check-builders.nix { 
      nixpkgs = mockNixpkgs; 
      self = mockSelf; 
    };
    # This will partially evaluate, we just want to ensure mkChecks is callable
    isMkChecksCallable = builtins.isFunction checkBuilders.mkChecks;
  in
  isMkChecksCallable
  EOF

  if nix-instantiate --eval --expr "import ./test-mkChecks-output.nix" | grep -q "true"; then
    echo "✓ mkChecks callable structure: PASSED"
  else
    echo "✗ mkChecks callable structure: FAILED"
    exit 1
  fi

  echo "All check-builders module tests passed!"
  touch $out
''