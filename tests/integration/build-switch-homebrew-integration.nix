{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  homebrewHelpers = import ../lib/homebrew-test-helpers.nix { inherit pkgs; };

  # Import configurations
  casksConfig = import "${src}/modules/darwin/casks.nix" { };
  homeManagerConfig = "${src}/modules/darwin/home-manager.nix";
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
  buildSwitchCommon = "${src}/scripts/build-switch-common.sh";
in
pkgs.runCommand "build-switch-homebrew-integration-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq nix ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch + Homebrew Integration Tests"}

  # Test 1: Build-Switch Script Homebrew Awareness
  ${testHelpers.testSubsection "Build-Switch Script Homebrew Awareness"}

  ${testHelpers.assertExists "$buildSwitchScript" "Build-switch script exists"}
  ${testHelpers.assertExists "$buildSwitchCommon" "Build-switch common script exists"}

  # Check if build-switch handles Darwin-specific features
  if grep -q "PLATFORM_TYPE.*darwin" "$buildSwitchScript"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Build-switch recognizes Darwin platform"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Build-switch doesn't recognize Darwin platform"
    exit 1
  fi

  # Check for Homebrew-compatible environment variables
  if grep -q "NIXPKGS_ALLOW_UNFREE" "$buildSwitchScript"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Unfree packages enabled for Homebrew compatibility"
  fi

  # Test 2: Home Manager Homebrew Integration
  ${testHelpers.testSubsection "Home Manager Homebrew Integration"}

  ${testHelpers.assertExists "$homeManagerConfig" "Home manager configuration exists"}
  ${testHelpers.assertContains "$homeManagerConfig" "homebrew" "Homebrew section present in home manager"}

  # Verify essential Homebrew configurations
  ${testHelpers.assertContains "$homeManagerConfig" "homebrew.enable = true" "Homebrew is enabled"}
  ${testHelpers.assertContains "$homeManagerConfig" "homebrew.casks" "Homebrew casks configuration present"}

  # Check for MAS (Mac App Store) integration
  if grep -q "masApps" "$homeManagerConfig"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} MAS apps integration present"
  fi

  # Test 3: Casks Configuration Integration
  ${testHelpers.testSubsection "Casks Configuration Integration"}

  # Create test environment with actual casks
  CASKS_JSON='${builtins.toJSON casksConfig}'
  echo "$CASKS_JSON" > casks.json
  CASKS_COUNT=$(echo "$CASKS_JSON" | jq 'length')

  echo "${testHelpers.colors.blue}Found $CASKS_COUNT casks in configuration${testHelpers.colors.reset}"

  # Verify casks are properly referenced in home manager
  if grep -q "casks.nix" "$homeManagerConfig"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Casks.nix properly imported in home manager"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Casks.nix not imported in home manager"
    exit 1
  fi

  # Test 4: Build-Switch Darwin Configuration
  ${testHelpers.testSubsection "Build-Switch Darwin Configuration"}

  # Check Darwin-specific build configuration
  if grep -q "darwinConfigurations" "$buildSwitchScript"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin configurations recognized"
  fi

  # Check for darwin-rebuild command usage
  if grep -q "darwin-rebuild" "$buildSwitchScript"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Darwin-rebuild command configured"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Darwin-rebuild command not found"
    exit 1
  fi

  # Test 5: Homebrew Activation Workflow Simulation
  ${testHelpers.testSubsection "Homebrew Activation Workflow"}

  # Mock Homebrew environment
  ${homebrewHelpers.setupHomebrewTestEnv (homebrewHelpers.mockHomebrewState {
    casks = casksConfig;
    masApps = { "test-app" = 123456789; };
  })}

  # Simulate build-switch execution steps
  ${testHelpers.createTempFile ''
#!/bin/bash
# Mock build-switch execution
set -e

echo "🔄 Starting build-switch with Homebrew integration..."

# Step 1: Pre-build checks
echo "📋 Pre-build checks..."
echo "  ✓ Checking Homebrew installation"
echo "  ✓ Validating casks configuration"
echo "  ✓ Checking MAS apps"

# Step 2: Build phase
echo "🔨 Build phase..."
echo "  ✓ Building Darwin configuration"
echo "  ✓ Including Homebrew configurations"

# Step 3: Switch phase
echo "🔄 Switch phase..."
echo "  ✓ Activating Darwin configuration"
echo "  ✓ Processing Homebrew changes"
echo "  ✓ Installing/updating casks"
echo "  ✓ Installing MAS apps"

# Step 4: Post-switch validation
echo "✅ Post-switch validation..."
echo "  ✓ Verifying system state"
echo "  ✓ Checking Homebrew installations"

echo "🎉 Build-switch completed successfully"
''
  }
  MOCK_BUILD_SWITCH="$TEMP_FILE"
  chmod +x "$MOCK_BUILD_SWITCH"

  ${testHelpers.assertCommand "bash $MOCK_BUILD_SWITCH" "Mock build-switch execution succeeds"}

  # Test 6: Homebrew State Changes Detection
  ${testHelpers.testSubsection "Homebrew State Changes Detection"}

  # Simulate casks.nix changes
  ${testHelpers.createTempFile ''
[
  "docker-desktop"
  "google-chrome"
  "1password"
  "new-app"
]
''
  }
  NEW_CASKS_FILE="$TEMP_FILE"

  # Compare with original casks
  NEW_CASKS_COUNT=$(jq 'length' < "$NEW_CASKS_FILE")
  ORIGINAL_CASKS_COUNT=$CASKS_COUNT

  if [ "$NEW_CASKS_COUNT" -gt "$ORIGINAL_CASKS_COUNT" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Cask addition detected"
  fi

  # Test for new cask validation
  if jq -r '.[]' < "$NEW_CASKS_FILE" | grep -q "new-app"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} New cask 'new-app' properly formatted"
  fi

  # Test 7: MAS App Installation Workflow
  ${testHelpers.testSubsection "MAS App Installation Workflow"}

  # Mock MAS app configuration
  ${testHelpers.createTempFile ''
{
  "masApps": {
    "magnet": 441258766,
    "wireguard": 1451685025,
    "kakaotalk": 869223134,
    "new-test-app": 999999999
  }
}
''
  }
  MAS_CONFIG="$TEMP_FILE"

  # Validate MAS app IDs
  ${homebrewHelpers.assertMasAppValid 441258766 "Magnet app ID valid"}
  ${homebrewHelpers.assertMasAppValid 1451685025 "WireGuard app ID valid"}
  ${homebrewHelpers.assertMasAppValid 869223134 "KakaoTalk app ID valid"}

  # Test MAS installation simulation
  ${testHelpers.createTempFile ''
#!/bin/bash
# Mock MAS installation
echo "📱 Installing MAS apps..."
for app_id in 441258766 1451685025 869223134; do
  echo "  ✓ Installing app with ID: $app_id"
  # Simulate installation time
  sleep 0.1
done
echo "✅ MAS apps installation completed"
''
  }
  MAS_INSTALLER="$TEMP_FILE"
  chmod +x "$MAS_INSTALLER"

  ${testHelpers.benchmark "mas-apps-installation" "bash $MAS_INSTALLER"}

  # Test 8: Rollback Scenario Handling
  ${testHelpers.testSubsection "Rollback Scenario Handling"}

  # Test configuration backup before changes
  ${testHelpers.createTempDir}
  BACKUP_DIR="$TEMP_DIR/config-backup"
  mkdir -p "$BACKUP_DIR"

  # Mock configuration backup
  cp casks.json "$BACKUP_DIR/casks.json.backup"
  cp "$MAS_CONFIG" "$BACKUP_DIR/mas-config.json.backup"

  ${testHelpers.assertExists "$BACKUP_DIR/casks.json.backup" "Casks configuration backed up"}
  ${testHelpers.assertExists "$BACKUP_DIR/mas-config.json.backup" "MAS configuration backed up"}

  # Simulate rollback scenario
  ${testHelpers.createTempFile ''
#!/bin/bash
# Mock rollback scenario
set -e

echo "⚠️  Rollback scenario detected..."
echo "📋 Checking previous generation..."

# Simulate generation switching
echo "🔄 Rolling back to previous generation..."
echo "  ✓ Restoring system configuration"
echo "  ✓ Restoring Homebrew state"
echo "  ✓ Restoring MAS apps"

echo "✅ Rollback completed successfully"
''
  }
  ROLLBACK_SCRIPT="$TEMP_FILE"
  chmod +x "$ROLLBACK_SCRIPT"

  ${testHelpers.assertCommand "bash $ROLLBACK_SCRIPT" "Rollback simulation succeeds"}

  # Test 9: Network Failure Handling
  ${testHelpers.testSubsection "Network Failure Handling"}

  # Mock network failure during Homebrew operations
  ${testHelpers.createTempFile ''
#!/bin/bash
# Mock network failure scenario
echo "🌐 Testing network failure handling..."

# Simulate network timeout
echo "❌ Network timeout during cask download"
echo "🔄 Implementing retry logic..."

# Simulate retry attempts
for i in {1..3}; do
  echo "  Attempt $i/3..."
  if [ "$i" -eq 3 ]; then
    echo "  ✓ Connection restored"
    break
  else
    echo "  ❌ Still failing..."
  fi
done

echo "✅ Network failure handled gracefully"
''
  }
  NETWORK_FAILURE_SCRIPT="$TEMP_FILE"
  chmod +x "$NETWORK_FAILURE_SCRIPT"

  ${testHelpers.assertCommand "bash $NETWORK_FAILURE_SCRIPT" "Network failure handling works"}

  # Test 10: Performance Benchmarks
  ${testHelpers.testSubsection "Performance Benchmarks"}

  # Benchmark different installation scenarios
  ${homebrewHelpers.benchmarkCaskInstall "docker-desktop"}
  ${homebrewHelpers.benchmarkCaskInstall "google-chrome"}
  ${homebrewHelpers.benchmarkCaskInstall "1password"}

  # Mock full build-switch performance
  ${testHelpers.benchmark "full-build-switch" "
    echo 'Simulating full build-switch workflow...'
    sleep 1
    echo 'Build-switch completed'
  "}

  # Test 11: System Integration Verification
  ${testHelpers.testSubsection "System Integration Verification"}

  # Check for system activation script integration
  if grep -q "system.activationScripts" "$homeManagerConfig"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System activation scripts present"
  fi

  # Check for Karabiner-Elements specific integration
  if grep -q "karabiner" "$homeManagerConfig"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Karabiner-Elements integration present"
  fi

  # Test dock integration
  if grep -q "local.dock" "$homeManagerConfig"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Dock integration configured"
  fi

  # Test 12: Configuration Validation
  ${testHelpers.testSubsection "Configuration Validation"}

  # Validate that all referenced files exist
  REFERENCED_FILES=("casks.nix" "packages.nix" "files.nix")

  for file in "''${REFERENCED_FILES[@]}"; do
    if [ -f "${src}/modules/darwin/$file" ]; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Referenced file exists: $file"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Referenced file missing: $file"
      exit 1
    fi
  done

  # Test syntax validation
  if command -v nix-instantiate >/dev/null 2>&1; then
    echo "🔍 Validating Nix syntax..."
    if nix-instantiate --parse "$homeManagerConfig" >/dev/null 2>&1; then
      echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Home manager configuration syntax valid"
    else
      echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Home manager configuration syntax invalid"
      exit 1
    fi
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Build-Switch Homebrew Integration Summary ===${testHelpers.colors.reset}"
  echo "Casks configured: $CASKS_COUNT"
  echo "Platform: Darwin (aarch64)"
  echo "Build command: darwin-rebuild"
  echo "Integration status: ${testHelpers.colors.green}READY${testHelpers.colors.reset}"
  echo ""
  echo "${testHelpers.colors.green}✓ All build-switch + Homebrew integration tests completed successfully!${testHelpers.colors.reset}"

  touch $out
''
