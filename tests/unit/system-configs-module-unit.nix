# Unit test for lib/system-configs.nix module
# Tests that the system configs module exports correct builders and utilities

{ pkgs, flake ? null, src ? ../. }:

pkgs.runCommand "system-configs-module-unit-test" {
  buildInputs = [ pkgs.nix ];
  src = src;
} ''
  echo "Testing system-configs.nix module..."

  # Copy source to build directory for testing
  cp -r $src/* .

  # Test 1: Module should be importable with mock inputs
  echo "Test 1: Checking module import..."
  
  # Create a test Nix expression that imports the module with mock inputs
  cat > test-import.nix << 'EOF'
  let
    mockInputs = {
      darwin = { lib = { darwinSystem = null; }; darwinModules = { home-manager = null; }; };
      nix-homebrew = { darwinModules = { nix-homebrew = null; }; };
      homebrew-bundle = null;
      homebrew-core = null;  
      homebrew-cask = null;
      disko = { nixosModules = { disko = null; }; };
      home-manager = { 
        darwinModules = { home-manager = null; }; 
        nixosModules = { home-manager = null; }; 
      };
      self = null;
    };
    mockNixpkgs = { 
      lib = { 
        genAttrs = systems: f: {}; 
        nixosSystem = null;
      }; 
    };
    systemConfigs = import ./lib/system-configs.nix { 
      inputs = mockInputs; 
      nixpkgs = mockNixpkgs; 
    };
  in
  systemConfigs
  EOF

  # This should not throw an error
  if nix-instantiate --eval --expr "import ./test-import.nix" >/dev/null 2>&1; then
    echo "✓ Module import: PASSED"
  else
    echo "✗ Module import: FAILED"
    exit 1
  fi

  # Test 2: Module should have required configuration builders
  echo "Test 2: Checking required builder functions..."
  
  cat > test-builders.nix << 'EOF'
  let
    mockInputs = {
      darwin = { lib = { darwinSystem = null; }; darwinModules = { home-manager = null; }; };
      nix-homebrew = { darwinModules = { nix-homebrew = null; }; };
      homebrew-bundle = null;
      homebrew-core = null;
      homebrew-cask = null;
      disko = { nixosModules = { disko = null; }; };
      home-manager = { 
        darwinModules = { home-manager = null; }; 
        nixosModules = { home-manager = null; }; 
      };
    };
    mockNixpkgs = { 
      lib = { 
        genAttrs = systems: f: {}; 
        nixosSystem = null;
      }; 
    };
    systemConfigs = import ./lib/system-configs.nix { 
      inputs = mockInputs; 
      nixpkgs = mockNixpkgs; 
    };
    requiredBuilders = [ "mkDarwinConfigurations" "mkNixosConfigurations" "mkAppConfigurations" "utils" ];
    hasAllBuilders = builtins.all (builder: builtins.hasAttr builder systemConfigs) requiredBuilders;
  in
  hasAllBuilders
  EOF

  if nix-instantiate --eval --expr "import ./test-builders.nix" | grep -q "true"; then
    echo "✓ Required builders: PASSED"
  else
    echo "✗ Required builders: FAILED"
    exit 1
  fi

  # Test 3: mkAppConfigurations should have correct structure
  echo "Test 3: Checking mkAppConfigurations structure..."
  
  cat > test-app-configs.nix << 'EOF'
  let
    mockInputs = {
      darwin = { lib = { darwinSystem = null; }; darwinModules = { home-manager = null; }; };
      nix-homebrew = { darwinModules = { nix-homebrew = null; }; };
      homebrew-bundle = null;
      homebrew-core = null;
      homebrew-cask = null;
      disko = { nixosModules = { disko = null; }; };
      home-manager = { 
        darwinModules = { home-manager = null; }; 
        nixosModules = { home-manager = null; }; 
      };
    };
    mockNixpkgs = { 
      lib = { 
        genAttrs = systems: f: {}; 
        nixosSystem = null;
      }; 
    };
    systemConfigs = import ./lib/system-configs.nix { 
      inputs = mockInputs; 
      nixpkgs = mockNixpkgs; 
    };
    appConfigs = systemConfigs.mkAppConfigurations;
    hasLinuxApps = appConfigs ? mkLinuxApps && builtins.isFunction appConfigs.mkLinuxApps;
    hasDarwinApps = appConfigs ? mkDarwinApps && builtins.isFunction appConfigs.mkDarwinApps;
  in
  hasLinuxApps && hasDarwinApps
  EOF

  if nix-instantiate --eval --expr "import ./test-app-configs.nix" | grep -q "true"; then
    echo "✓ App configurations structure: PASSED"
  else
    echo "✗ App configurations structure: FAILED"
    exit 1
  fi

  # Test 4: Utils should have platform detection functions
  echo "Test 4: Checking utils platform detection..."
  
  cat > test-utils.nix << 'EOF'
  let
    mockInputs = {
      darwin = { lib = { darwinSystem = null; }; darwinModules = { home-manager = null; }; };
      nix-homebrew = { darwinModules = { nix-homebrew = null; }; };
      homebrew-bundle = null;
      homebrew-core = null;
      homebrew-cask = null;
      disko = { nixosModules = { disko = null; }; };
      home-manager = { 
        darwinModules = { home-manager = null; }; 
        nixosModules = { home-manager = null; }; 
      };
    };
    mockNixpkgs = { 
      lib = { 
        genAttrs = systems: f: {}; 
        nixosSystem = null;
      }; 
    };
    systemConfigs = import ./lib/system-configs.nix { 
      inputs = mockInputs; 
      nixpkgs = mockNixpkgs; 
    };
    utils = systemConfigs.utils;
    hasIsDarwin = utils ? isDarwin && builtins.isFunction utils.isDarwin;
    hasIsLinux = utils ? isLinux && builtins.isFunction utils.isLinux;
    hasGetArch = utils ? getArch && builtins.isFunction utils.getArch;
    hasGetPlatform = utils ? getPlatform && builtins.isFunction utils.getPlatform;
  in
  hasIsDarwin && hasIsLinux && hasGetArch && hasGetPlatform
  EOF

  if nix-instantiate --eval --expr "import ./test-utils.nix" | grep -q "true"; then
    echo "✓ Utils platform detection: PASSED"
  else
    echo "✗ Utils platform detection: FAILED"
    exit 1
  fi

  # Test 5: Configuration builders should be functions
  echo "Test 5: Checking configuration builders are functions..."
  
  cat > test-config-builders.nix << 'EOF'
  let
    mockInputs = {
      darwin = { lib = { darwinSystem = null; }; darwinModules = { home-manager = null; }; };
      nix-homebrew = { darwinModules = { nix-homebrew = null; }; };
      homebrew-bundle = null;
      homebrew-core = null;
      homebrew-cask = null;
      disko = { nixosModules = { disko = null; }; };
      home-manager = { 
        darwinModules = { home-manager = null; }; 
        nixosModules = { home-manager = null; }; 
      };
    };
    mockNixpkgs = { 
      lib = { 
        genAttrs = systems: f: {}; 
        nixosSystem = null;
      }; 
    };
    systemConfigs = import ./lib/system-configs.nix { 
      inputs = mockInputs; 
      nixpkgs = mockNixpkgs; 
    };
    isDarwinBuilder = builtins.isFunction systemConfigs.mkDarwinConfigurations;
    isNixosBuilder = builtins.isFunction systemConfigs.mkNixosConfigurations;
  in
  isDarwinBuilder && isNixosBuilder
  EOF

  if nix-instantiate --eval --expr "import ./test-config-builders.nix" | grep -q "true"; then
    echo "✓ Configuration builders are functions: PASSED"
  else
    echo "✗ Configuration builders are functions: FAILED"
    exit 1
  fi

  echo "All system-configs module tests passed!"
  touch $out
''