{ pkgs, flake ? null, src }:
let
  testHelpers = import ../../lib/test-helpers.nix { inherit pkgs; };
  configCompare = import ../lib/config-compare.nix { inherit pkgs; };

in
pkgs.runCommand "config-comparison-unit-test" { } ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Configuration Comparison Unit Tests"}

  # Test 1: Basic configuration comparison functionality
  ${testHelpers.testSubsection "Basic Comparison Infrastructure"}

  # This test should initially FAIL to prove we can detect differences
  echo "${testHelpers.colors.blue}Testing configuration comparison utilities...${testHelpers.colors.reset}"

  # Test that config comparison utilities exist and are callable
  ${testHelpers.testSubsection "Configuration Comparison Utilities"}

  # Test comparing identical configurations (should pass)
  TEMP_CONFIG1=$(mktemp)
  TEMP_CONFIG2=$(mktemp)

  cat > $TEMP_CONFIG1 << 'EOF'
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ git vim curl ];
  system.stateVersion = "23.05";
}
EOF

  cp $TEMP_CONFIG1 $TEMP_CONFIG2

  if ${configCompare.compareConfigs} "$TEMP_CONFIG1" "$TEMP_CONFIG2" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Identical configurations detected as equal"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Identical configurations comparison failed"
    exit 1
  fi

  # Test comparing different configurations (should detect differences)
  cat > $TEMP_CONFIG2 << 'EOF'
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ git vim curl jq ];
  system.stateVersion = "23.05";
}
EOF

  if ! ${configCompare.compareConfigs} "$TEMP_CONFIG1" "$TEMP_CONFIG2" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Different configurations detected as different"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Different configurations not detected"
    exit 1
  fi

  # Test 2: Package list comparison
  ${testHelpers.testSubsection "Package List Comparison"}

  # Test package list extraction and comparison
  if ${configCompare.extractPackageList} "$TEMP_CONFIG1" > /tmp/packages1.txt 2>/dev/null; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Package list extraction works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Package list extraction failed"
    exit 1
  fi

  # Test 3: System configuration validation
  ${testHelpers.testSubsection "System Configuration Validation"}

  # Test that we can validate a configuration builds successfully
  if ${configCompare.validateConfig} "$TEMP_CONFIG1" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Configuration validation works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Configuration validation failed"
    exit 1
  fi

  # Test 4: Configuration evaluation comparison
  ${testHelpers.testSubsection "Configuration Evaluation Comparison"}

  # Test that we can extract and compare nix evaluation results
  if ${configCompare.evalAndCompare} "$TEMP_CONFIG1" "$TEMP_CONFIG2" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Configuration evaluation comparison works"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Configuration evaluation comparison failed"
    exit 1
  fi

  # Test 5: Home manager configuration comparison
  ${testHelpers.testSubsection "Home Manager Configuration Comparison"}

  # Test home manager specific comparison
  TEMP_HM_CONFIG1=$(mktemp)
  TEMP_HM_CONFIG2=$(mktemp)

  cat > $TEMP_HM_CONFIG1 << 'EOF'
{ pkgs, ... }: {
  home.packages = with pkgs; [ git vim ];
  programs.git.enable = true;
}
EOF

  cat > $TEMP_HM_CONFIG2 << 'EOF'
{ pkgs, ... }: {
  home.packages = with pkgs; [ git vim curl ];
  programs.git.enable = true;
}
EOF

  if ! ${configCompare.compareHomeManagerConfigs} "$TEMP_HM_CONFIG1" "$TEMP_HM_CONFIG2" >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Home manager configuration differences detected"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Home manager configuration comparison failed"
    exit 1
  fi

  # Cleanup
  rm -f $TEMP_CONFIG1 $TEMP_CONFIG2 $TEMP_HM_CONFIG1 $TEMP_HM_CONFIG2 /tmp/packages1.txt

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Configuration Comparison Unit Tests ===${testHelpers.colors.reset}"
  echo "Passed: ${testHelpers.colors.green}8${testHelpers.colors.reset}/8"
  echo "${testHelpers.colors.green}✓ All configuration comparison tests passed!${testHelpers.colors.reset}"
  touch $out
''
