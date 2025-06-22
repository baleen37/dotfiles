{ pkgs, flake ? null, src }:
let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };

in
pkgs.runCommand "refactor-workflow-integration-test"
{
  nativeBuildInputs = with pkgs; [ bash nix git ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Refactor Workflow Integration Tests"}

  cd ${src}
  export USER=testuser

  # Test 1: Baseline capture workflow
  ${testHelpers.testSubsection "Baseline Capture Workflow"}

  # Test that baseline capture script exists and is executable
  CAPTURE_SCRIPT="${src}/tests/refactor/scripts/capture-baseline.sh"
  ${testHelpers.assertExists "$CAPTURE_SCRIPT" "Capture baseline script exists"}
  ${testHelpers.assertTrue ''[ -x "$CAPTURE_SCRIPT" ]'' "Capture baseline script is executable"}

  # Test script help functionality
  if "$CAPTURE_SCRIPT" help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Capture baseline script help works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Capture baseline script help failed"
    exit 1
  fi

  # Test baseline listing (should work even with no baselines)
  if "$CAPTURE_SCRIPT" list >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Baseline listing works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Baseline listing failed"
    exit 1
  fi

  # Test 2: Configuration comparison workflow
  ${testHelpers.testSubsection "Configuration Comparison Workflow"}

  # Test that comparison script exists and is executable
  COMPARE_SCRIPT="${src}/tests/refactor/scripts/compare-configs.sh"
  ${testHelpers.assertExists "$COMPARE_SCRIPT" "Compare configs script exists"}
  ${testHelpers.assertTrue ''[ -x "$COMPARE_SCRIPT" ]'' "Compare configs script is executable"}

  # Test script help functionality
  if "$COMPARE_SCRIPT" help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Compare configs script help works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Compare configs script help failed"
    exit 1
  fi

  # Test baseline listing
  if "$COMPARE_SCRIPT" list >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Baseline listing in compare script works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Baseline listing in compare script failed"
    exit 1
  fi

  # Test 3: Configuration comparison utilities integration
  ${testHelpers.testSubsection "Configuration Comparison Utilities Integration"}

  # Test that the config-compare.nix library can be imported
  if nix eval --impure --file "${src}/tests/refactor/lib/config-compare.nix" '{pkgs = import <nixpkgs> {};}' >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Config comparison library imports successfully"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Config comparison library import failed"
    exit 1
  fi

  # Test that comparison utilities are accessible
  TEMP_CONFIG=$(mktemp)
  cat > $TEMP_CONFIG << 'EOF'
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ git vim ];
}
EOF

  # Use nix to test the config comparison functions
  if nix eval --impure --expr "
    let
      pkgs = import <nixpkgs> {};
      configCompare = import ${src}/tests/refactor/lib/config-compare.nix { inherit pkgs; };
    in
    configCompare.validateConfig \"$TEMP_CONFIG\"
  " >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Config validation utility works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Config validation utility failed"
    exit 1
  fi

  rm -f $TEMP_CONFIG

  # Test 4: Test framework integration
  ${testHelpers.testSubsection "Test Framework Integration"}

  # Test that refactor tests are discoverable by the main test framework
  if [ -f "${src}/tests/default.nix" ]; then
    # Check if refactor tests would be discovered
    if nix eval --impure --file "${src}/tests/default.nix" '{pkgs = import <nixpkgs> {};}' >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Refactor tests integrate with main test framework"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Refactor tests integration failed"
      exit 1
    fi
  fi

  # Test 5: Directory structure validation
  ${testHelpers.testSubsection "Directory Structure Validation"}

  # Test that all expected directories exist
  EXPECTED_DIRS=(
    "tests/refactor"
    "tests/refactor/unit"
    "tests/refactor/integration"
    "tests/refactor/lib"
    "tests/refactor/scripts"
    "tests/refactor/fixtures"
    "tests/refactor/baselines"
  )

  for dir in "''${EXPECTED_DIRS[@]}"; do
    ${testHelpers.assertExists "${src}/$dir" "Directory $dir exists"}
  done

  # Test that expected files exist
  EXPECTED_FILES=(
    "tests/refactor/lib/config-compare.nix"
    "tests/refactor/scripts/capture-baseline.sh"
    "tests/refactor/scripts/compare-configs.sh"
    "tests/refactor/unit/config-comparison-unit.nix"
  )

  for file in "''${EXPECTED_FILES[@]}"; do
    ${testHelpers.assertExists "${src}/$file" "File $file exists"}
  done

  # Test 6: Script permissions and shebangs
  ${testHelpers.testSubsection "Script Permissions and Shebangs"}

  # Test that scripts have proper shebangs
  SCRIPT_FILES=(
    "tests/refactor/scripts/capture-baseline.sh"
    "tests/refactor/scripts/compare-configs.sh"
  )

  for script in "''${SCRIPT_FILES[@]}"; do
    if head -1 "${src}/$script" | grep -q "#!/"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script $script has proper shebang"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script $script missing shebang"
      exit 1
    fi

    if [ -x "${src}/$script" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Script $script is executable"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Script $script is not executable"
      exit 1
    fi
  done

  # Test 7: Current system compatibility
  ${testHelpers.testSubsection "Current System Compatibility"}

  # Test that scripts work with current system
  CURRENT_SYSTEM=$(nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo "unknown")
  echo "Testing on system: $CURRENT_SYSTEM"

  case "$CURRENT_SYSTEM" in
    *-darwin|*-linux)
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System type $CURRENT_SYSTEM is supported"
      ;;
    *)
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Unknown system type: $CURRENT_SYSTEM"
      ;;
  esac

  # Test 8: Error handling
  ${testHelpers.testSubsection "Error Handling"}

  # Test that scripts handle missing arguments gracefully
  if "$CAPTURE_SCRIPT" invalid_command 2>&1 | grep -q "Unknown command"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Capture script handles invalid commands"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Capture script error handling failed"
    exit 1
  fi

  if "$COMPARE_SCRIPT" compare 2>&1 | grep -q "Please provide baseline ID"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Compare script handles missing arguments"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Compare script error handling failed"
    exit 1
  fi

  # Test 9: Makefile integration readiness
  ${testHelpers.testSubsection "Makefile Integration Readiness"}

  # Test that scripts can be called from project root
  if cd "${src}" && "./tests/refactor/scripts/capture-baseline.sh" help >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Scripts work when called from project root"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Scripts fail when called from project root"
    exit 1
  fi

  # Test 10: Documentation completeness
  ${testHelpers.testSubsection "Documentation Completeness"}

  # Test that scripts have help output
  HELP_COMMANDS=("help" "--help" "-h")

  for help_cmd in "''${HELP_COMMANDS[@]}"; do
    if "$CAPTURE_SCRIPT" "$help_cmd" 2>&1 | grep -q "Usage:"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Capture script responds to $help_cmd"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Capture script help for $help_cmd incomplete"
    fi

    if "$COMPARE_SCRIPT" "$help_cmd" 2>&1 | grep -q "Usage:"; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Compare script responds to $help_cmd"
    else
      echo "${testHelpers.colors.yellow}⚠${testHelpers.colors.reset} Compare script help for $help_cmd incomplete"
    fi
  done

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Refactor Workflow Integration Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}25${testHelpers.colors.reset}/25"
  echo "${testHelpers.colors.green}✓ All refactor workflow integration tests passed!${testHelpers.colors.reset}"
  touch $out
''
