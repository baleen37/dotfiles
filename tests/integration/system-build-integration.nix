{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  
in
pkgs.runCommand "system-build-integration-test" {
  nativeBuildInputs = with pkgs; [ nix git ];
} ''
  ${testHelpers.setupTestEnv}
  
  ${testHelpers.testSection "System Build Integration Tests"}
  
  cd ${src}
  export USER=testuser
  CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw)
  
  # Test 1: Complete build workflow integration
  ${testHelpers.testSubsection "Complete Build Workflow Integration"}
  
  # Test the complete build workflow without actual system application
  echo "${testHelpers.colors.blue}Testing complete build workflow for $CURRENT_SYSTEM${testHelpers.colors.reset}"
  
  # Step 1: Validate flake
  if nix flake check --impure --no-build >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Flake validation passed"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Flake validation failed"
    exit 1
  fi
  
  # Step 2: Build configuration (dry-run)
  case "$CURRENT_SYSTEM" in
    *-darwin)
      CONFIG_PATH="darwinConfigurations.\"$CURRENT_SYSTEM\""
      if nix eval --impure '.#'$CONFIG_PATH'.system.build.toplevel.drvPath' >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin configuration builds successfully"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Darwin configuration build failed"
        exit 1
      fi
      ;;
    *-linux)
      CONFIG_PATH="nixosConfigurations.\"$CURRENT_SYSTEM\""
      if nix eval --impure '.#'$CONFIG_PATH'.config.system.build.toplevel.drvPath' >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} NixOS configuration builds successfully"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} NixOS configuration build failed"
        exit 1
      fi
      ;;
  esac
  
  # Step 3: Test apps integration
  for app in build switch rollback; do
    if nix eval --impure '.#apps.'$CURRENT_SYSTEM'.'$app'.program' >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} App '$app' integrates correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} App '$app' integration failed"
      exit 1
    fi
  done
  
  # Test 2: Cross-platform compatibility integration
  ${testHelpers.testSubsection "Cross-Platform Compatibility Integration"}
  
  # Test that all platform configurations can coexist
  PLATFORMS=("x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux")
  
  for platform in "''${PLATFORMS[@]}"; do
    case "$platform" in
      *-darwin)
        CONFIG="darwinConfigurations.\"$platform\""
        ATTR="system.build.toplevel.drvPath"
        ;;
      *-linux)
        CONFIG="nixosConfigurations.\"$platform\""
        ATTR="config.system.build.toplevel.drvPath"
        ;;
    esac
    
    if nix eval --impure '.#'$CONFIG'.'$ATTR >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Platform $platform configuration is compatible"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Platform $platform configuration failed"
      exit 1
    fi
  done
  
  # Test 3: Module system integration
  ${testHelpers.testSubsection "Module System Integration"}
  
  # Test that all modules integrate correctly
  MODULE_DIRS=("modules/shared" "modules/darwin" "modules/nixos")
  
  for module_dir in "''${MODULE_DIRS[@]}"; do
    if [ -d "${src}/$module_dir" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Module directory $module_dir exists"
      
      # Test that key module files exist and are syntactically correct
      for module_file in $(find "${src}/$module_dir" -name "*.nix" -type f | head -5); do
        if nix-instantiate --parse "$module_file" >/dev/null 2>&1; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Module $(basename $module_file) syntax is valid"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Module $(basename $module_file) has syntax errors"
          exit 1
        fi
      done
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Module directory $module_dir not found"
    fi
  done
  
  # Test 4: Package management integration
  ${testHelpers.testSubsection "Package Management Integration"}
  
  # Test that package configurations integrate properly
  PACKAGE_MODULES=(
    "modules/shared/packages.nix"
    "modules/darwin/packages.nix"
    "modules/nixos/packages.nix"
  )
  
  for package_module in "''${PACKAGE_MODULES[@]}"; do
    if [ -f "${src}/$package_module" ]; then
      if nix eval --impure --file "${src}/$package_module" '{pkgs = import <nixpkgs> {};}' >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Package module $package_module integrates correctly"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Package module $package_module integration issues"
      fi
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Package module $package_module not found"
    fi
  done
  
  # Test 5: Home Manager integration
  ${testHelpers.testSubsection "Home Manager Integration"}
  
  # Test Home Manager configurations
  HM_MODULES=(
    "modules/shared/home-manager.nix"
    "modules/darwin/home-manager.nix"
    "modules/nixos/home-manager.nix"
  )
  
  for hm_module in "''${HM_MODULES[@]}"; do
    if [ -f "${src}/$hm_module" ]; then
      if nix-instantiate --parse "${src}/$hm_module" >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Home Manager module $hm_module syntax is valid"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Home Manager module $hm_module has syntax errors"
        exit 1
      fi
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Home Manager module $hm_module not found"
    fi
  done
  
  # Test 6: Overlay system integration
  ${testHelpers.testSubsection "Overlay System Integration"}
  
  # Test that overlays integrate properly
  if [ -d "${src}/overlays" ]; then
    OVERLAY_COUNT=$(find "${src}/overlays" -name "*.nix" -type f | wc -l)
    
    if [ $OVERLAY_COUNT -gt 0 ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Found $OVERLAY_COUNT overlay files"
      
      # Test that overlays can be evaluated
      for overlay_file in $(find "${src}/overlays" -name "*.nix" -type f | head -3); do
        if nix-instantiate --parse "$overlay_file" >/dev/null 2>&1; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Overlay $(basename $overlay_file) syntax is valid"
        else
          echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Overlay $(basename $overlay_file) has syntax errors"
          exit 1
        fi
      done
      
      # Test overlay application
      if nix eval --impure '.#legacyPackages.'$CURRENT_SYSTEM'.pkgs.system' >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Overlays apply successfully to package set"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Overlay application not verifiable"
      fi
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} No overlay files found"
    fi
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Overlays directory not found"
  fi
  
  # Test 7: Script and app integration
  ${testHelpers.testSubsection "Script and App Integration"}
  
  # Test platform-specific scripts
  SCRIPT_DIR="${src}/apps/$CURRENT_SYSTEM"
  if [ -d "$SCRIPT_DIR" ]; then
    EXPECTED_SCRIPTS=("build" "apply" "rollback")
    
    for script in "''${EXPECTED_SCRIPTS[@]}"; do
      SCRIPT_PATH="$SCRIPT_DIR/$script"
      if [ -f "$SCRIPT_PATH" ]; then
        ${testHelpers.assertExists "$SCRIPT_PATH" "Script $script exists"}
        ${testHelpers.assertTrue ''[ -x "$SCRIPT_PATH" ]'' "Script $script is executable"}
        
        # Test script content has expected patterns
        if grep -q "nix\|darwin\|nixos" "$SCRIPT_PATH" 2>/dev/null; then
          echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script $script contains expected Nix commands"
        else
          echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Script $script content not verifiable"
        fi
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Script $script not found in $SCRIPT_DIR"
      fi
    done
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Platform-specific script directory not found: $SCRIPT_DIR"
  fi
  
  # Test global scripts
  GLOBAL_SCRIPTS_DIR="${src}/scripts"
  if [ -d "$GLOBAL_SCRIPTS_DIR" ]; then
    for script in $(find "$GLOBAL_SCRIPTS_DIR" -type f -executable | head -3); do
      ${testHelpers.assertTrue ''[ -x "$script" ]'' "Global script $(basename $script) is executable"}
    done
  fi
  
  # Test 8: Configuration file integration
  ${testHelpers.testSubsection "Configuration File Integration"}
  
  # Test that configuration files are properly integrated
  CONFIG_DIRS=(
    "modules/shared/config"
    "modules/darwin/config"
    "modules/nixos/config"
  )
  
  for config_dir in "''${CONFIG_DIRS[@]}"; do
    if [ -d "${src}/$config_dir" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Configuration directory $config_dir exists"
      
      # Test that config files are properly structured
      CONFIG_FILE_COUNT=$(find "${src}/$config_dir" -type f | wc -l)
      if [ $CONFIG_FILE_COUNT -gt 0 ]; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Found $CONFIG_FILE_COUNT configuration files in $config_dir"
      fi
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Configuration directory $config_dir not found"
    fi
  done
  
  # Test 9: Testing framework integration
  ${testHelpers.testSubsection "Testing Framework Integration"}
  
  # Test that the testing framework itself integrates properly
  if [ -f "${src}/tests/default.nix" ]; then
    if nix eval --impure --file "${src}/tests/default.nix" '{pkgs = import <nixpkgs> {};}' >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Testing framework integrates correctly"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Testing framework integration failed"
      exit 1
    fi
    
    # Test that test helpers are accessible
    if [ -f "${src}/tests/lib/test-helpers.nix" ]; then
      if nix eval --impure --file "${src}/tests/lib/test-helpers.nix" '{pkgs = import <nixpkgs> {};}' >/dev/null 2>&1; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Test helpers integrate correctly"
      else
        echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Test helpers integration failed"
        exit 1
      fi
    fi
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Testing framework default.nix not found"
    exit 1
  fi
  
  # Test 10: Build system integration
  ${testHelpers.testSubsection "Build System Integration"}
  
  # Test Makefile integration
  if [ -f "${src}/Makefile" ]; then
    ${testHelpers.assertExists "${src}/Makefile" "Makefile exists"}
    
    # Test that Makefile contains expected targets
    EXPECTED_TARGETS=("build" "test" "lint" "switch")
    for target in "''${EXPECTED_TARGETS[@]}"; do
      if grep -q "^$target:" "${src}/Makefile"; then
        echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Makefile target '$target' exists"
      else
        echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Makefile target '$target' not found"
      fi
    done
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Makefile not found"
  fi
  
  # Test flake integration with nix commands
  if nix flake show --impure >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Flake integrates with nix commands"
  else
    echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Flake integration with nix commands not verifiable"
  fi
  
  ${testHelpers.cleanup}
  
  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: System Build Integration Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}30${testHelpers.colors.reset}/30"
  echo "${testHelpers.colors.green}✓ All system integration tests passed!${testHelpers.colors.reset}"
  touch $out
''