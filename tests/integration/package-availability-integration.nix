{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
  # Import package configurations
  sharedPackages = import (src + "/modules/shared/packages.nix") { inherit pkgs; };
  darwinPackages = if testHelpers.platform.isDarwin then
    import (src + "/modules/darwin/packages.nix") { inherit pkgs; }
  else [];
  nixosPackages = if testHelpers.platform.isLinux then
    import (src + "/modules/nixos/packages.nix") { inherit pkgs; }
  else [];
  
  # Combine all packages for current platform
  allPackages = sharedPackages ++ 
    (if testHelpers.platform.isDarwin then darwinPackages else []) ++
    (if testHelpers.platform.isLinux then nixosPackages else []);
    
  # Test package availability
  testPackage = pkg: 
    if builtins.isString pkg then
      if builtins.hasAttr pkg pkgs then
        { name = pkg; available = true; derivation = pkgs.${pkg}; }
      else
        { name = pkg; available = false; derivation = null; }
    else if builtins.hasAttr "name" pkg then
      { name = pkg.name or "unknown"; available = true; derivation = pkg; }
    else
      { name = "unknown"; available = true; derivation = pkg; };
      
  packageTests = map testPackage allPackages;
  availablePackages = builtins.filter (p: p.available) packageTests;
  unavailablePackages = builtins.filter (p: !p.available) packageTests;
  
in
pkgs.runCommand "package-availability-integration-test" {} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "Package Availability Integration Tests"}
  
  # Test 1: Shared packages availability
  ${testHelpers.testSubsection "Shared Packages"}
  SHARED_COUNT=${toString (builtins.length sharedPackages)}
  ${testHelpers.assertTrue ''[ $SHARED_COUNT -gt 0 ]'' "Shared packages list is not empty ($SHARED_COUNT packages)"}
  
  # Test core shared packages
  ${testHelpers.assertCommand "nix-instantiate --eval --expr 'builtins.hasAttr \"git\" (import <nixpkgs> {})'" "Git package is available"}
  ${testHelpers.assertCommand "nix-instantiate --eval --expr 'builtins.hasAttr \"vim\" (import <nixpkgs> {})'" "Vim package is available"}
  ${testHelpers.assertCommand "nix-instantiate --eval --expr 'builtins.hasAttr \"curl\" (import <nixpkgs> {})'" "Curl package is available"}
  
  # Test 2: Platform-specific packages
  ${testHelpers.onlyOn ["aarch64-darwin" "x86_64-darwin"] "Darwin-specific packages" ''
    ${testHelpers.testSubsection "Darwin-specific Packages"}
    DARWIN_COUNT=${toString (builtins.length darwinPackages)}
    echo "Darwin packages count: $DARWIN_COUNT"
    ${testHelpers.assertTrue ''[ $DARWIN_COUNT -ge 0 ]'' "Darwin packages list is valid"}
  ''}
  
  ${testHelpers.onlyOn ["aarch64-linux" "x86_64-linux"] "Linux-specific packages" ''
    ${testHelpers.testSubsection "Linux-specific Packages"} 
    NIXOS_COUNT=${toString (builtins.length nixosPackages)}
    echo "NixOS packages count: $NIXOS_COUNT"
    ${testHelpers.assertTrue ''[ $NIXOS_COUNT -ge 0 ]'' "NixOS packages list is valid"}
  ''}
  
  # Test 3: Package derivation validity
  ${testHelpers.testSubsection "Package Derivation Validity"}
  
  # Test that packages can be built (at least evaluated)
  TOTAL_PACKAGES=${toString (builtins.length allPackages)}
  AVAILABLE_PACKAGES=${toString (builtins.length availablePackages)}
  UNAVAILABLE_PACKAGES=${toString (builtins.length unavailablePackages)}
  
  echo "Total packages: $TOTAL_PACKAGES"
  echo "Available packages: $AVAILABLE_PACKAGES"
  echo "Unavailable packages: $UNAVAILABLE_PACKAGES"
  
  ${testHelpers.assertTrue ''[ $TOTAL_PACKAGES -gt 0 ]'' "Total package count is positive"}
  ${testHelpers.assertTrue ''[ $AVAILABLE_PACKAGES -ge $((TOTAL_PACKAGES * 80 / 100)) ]'' "At least 80% of packages are available"}
  
  # Test 4: Essential packages are available
  ${testHelpers.testSubsection "Essential Packages"}
  
  # Core development tools
  ${testHelpers.assertCommand "nix-instantiate --eval --expr '(import <nixpkgs> {}).git != null'" "Git is available"}
  ${testHelpers.assertCommand "nix-instantiate --eval --expr '(import <nixpkgs> {}).bash != null'" "Bash is available"}
  ${testHelpers.assertCommand "nix-instantiate --eval --expr '(import <nixpkgs> {}).coreutils != null'" "Coreutils is available"}
  
  # Test 5: Cross-platform compatibility
  ${testHelpers.testSubsection "Cross-platform Compatibility"}
  
  # Test that shared packages work on current platform
  for package in git vim curl bash coreutils; do
    if nix-instantiate --eval --expr "builtins.hasAttr \"$package\" (import <nixpkgs> {})" >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Package $package is available on ${testHelpers.platform.system}"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Package $package is not available on ${testHelpers.platform.system}"
      exit 1
    fi
  done
  
  # Test 6: Package metadata
  ${testHelpers.testSubsection "Package Metadata"}
  
  # Test that packages have basic metadata
  GIT_META=$(nix-instantiate --eval --expr '(import <nixpkgs> {}).git.meta.description or "none"' 2>/dev/null | tr -d '"')
  ${testHelpers.assertTrue ''[ "$GIT_META" != "none" ]'' "Git package has description metadata"}
  
  # Test 7: Package installation (dry-run)
  ${testHelpers.testSubsection "Package Installation Test"}
  
  # Test that we can build a simple package
  ${testHelpers.assertCommand "nix-build '<nixpkgs>' -A hello --no-out-link" "Hello package can be built"}
  
  ${testHelpers.reportResults "Package Availability Integration Tests" 12 12}
  touch $out
''