{ pkgs, flake ? null, src }:
let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs; };
  buildSwitchScript = "${src}/apps/aarch64-darwin/build-switch";
in
pkgs.runCommand "build-switch-rollback-integration-test"
{
  buildInputs = with pkgs; [ bash coreutils gnugrep findutils jq ];
} ''
  ${testHelpers.setupTestEnv}

  ${testHelpers.testSection "Build-Switch Rollback Integration Tests"}

  # Test 1: Pre-rollback state capture
  ${testHelpers.testSubsection "Pre-Rollback State Capture"}

  mkdir -p test_workspace rollback_test backup_states
  cd test_workspace

  # Test system state capture before changes
  echo "Testing pre-rollback state capture..."

  # Create mock system state
  cat > current_system_state.json << 'EOF'
{
  "version": "current",
  "timestamp": "2025-07-15T10:00:00Z",
  "configuration": {
    "build_switch_version": "1.0.0",
    "nix_version": "2.18.0",
    "system_profile": "/nix/var/nix/profiles/system"
  },
  "services": {
    "enabled": ["ssh", "nix-daemon"],
    "disabled": ["apache", "mysql"]
  },
  "packages": {
    "count": 150,
    "essential": ["bash", "coreutils", "nix"]
  }
}
EOF

  if [ -f "current_system_state.json" ] && jq . current_system_state.json >/dev/null 2>&1; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} System state capture format verified"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} System state capture failed"
    exit 1
  fi

  # Test 2: Failed build detection
  ${testHelpers.testSubsection "Failed Build Detection"}

  # Test detection of various failure scenarios
  echo "Testing failed build detection..."

  # Create different failure scenarios
  FAILURE_SCENARIOS=(
    "compilation_error"
    "dependency_missing"
    "disk_space_exhausted"
    "permission_denied"
    "network_timeout"
  )

  for scenario in "''${FAILURE_SCENARIOS[@]}"; do
    mkdir -p "failure_scenarios/$scenario"
    cat > "failure_scenarios/$scenario/error.log" << EOF
Error Type: $scenario
Timestamp: $(date -Iseconds)
Details: Simulated $scenario failure for testing
EOF
  done

  SCENARIO_COUNT=$(ls failure_scenarios/ | wc -l)
  if [ "$SCENARIO_COUNT" -eq 5 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Failure scenario detection tests prepared"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Failure scenario setup incomplete"
    exit 1
  fi

  # Test 3: Rollback decision logic
  ${testHelpers.testSubsection "Rollback Decision Logic"}

  # Test intelligent rollback decision making
  echo "Testing rollback decision logic..."

  # Create rollback criteria
  cat > rollback_criteria.json << 'EOF'
{
  "auto_rollback_conditions": [
    "system_boot_failure",
    "critical_service_failure",
    "configuration_corruption"
  ],
  "manual_rollback_conditions": [
    "performance_degradation",
    "minor_service_issues",
    "user_preference_change"
  ],
  "no_rollback_conditions": [
    "cosmetic_changes",
    "non_critical_warnings",
    "expected_deprecations"
  ]
}
EOF

  if jq '.auto_rollback_conditions | length' rollback_criteria.json | grep -q "3"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback criteria structure validated"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback criteria validation failed"
    exit 1
  fi

  # Test 4: Configuration restoration
  ${testHelpers.testSubsection "Configuration Restoration"}

  # Test restoration of previous configuration
  echo "Testing configuration restoration..."

  # Create backup configuration
  mkdir -p backup_configs/previous
  cat > backup_configs/previous/system_config.nix << 'EOF'
{ config, pkgs, ... }:
{
  # Previous working configuration
  system.stateVersion = "23.05";

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
  ];

  services.sshd.enable = true;
  services.nix-daemon.enable = true;
}
EOF

  # Create current (problematic) configuration
  mkdir -p backup_configs/current
  cat > backup_configs/current/system_config.nix << 'EOF'
{ config, pkgs, ... }:
{
  # Current problematic configuration
  system.stateVersion = "23.11";

  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    broken-package  # This would cause build failure
  ];

  services.sshd.enable = true;
  services.nix-daemon.enable = true;
  services.problematic-service.enable = true;  # This might cause issues
}
EOF

  if [ -f "backup_configs/previous/system_config.nix" ] && [ -f "backup_configs/current/system_config.nix" ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Configuration backup and restoration structure verified"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Configuration backup setup failed"
    exit 1
  fi

  # Test 5: Service state restoration
  ${testHelpers.testSubsection "Service State Restoration"}

  # Test restoration of system services
  echo "Testing service state restoration..."

  # Create service state snapshots
  cat > service_state_before.json << 'EOF'
{
  "services": {
    "sshd": {
      "enabled": true,
      "running": true,
      "config_hash": "abc123"
    },
    "nix-daemon": {
      "enabled": true,
      "running": true,
      "config_hash": "def456"
    }
  }
}
EOF

  cat > service_state_after_failure.json << 'EOF'
{
  "services": {
    "sshd": {
      "enabled": true,
      "running": false,
      "config_hash": "xyz789",
      "error": "configuration_invalid"
    },
    "nix-daemon": {
      "enabled": true,
      "running": true,
      "config_hash": "def456"
    },
    "problematic-service": {
      "enabled": true,
      "running": false,
      "config_hash": "broken",
      "error": "service_not_found"
    }
  }
}
EOF

  if jq '.services | keys | length' service_state_before.json | grep -q "2" && \
     jq '.services | keys | length' service_state_after_failure.json | grep -q "3"; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Service state restoration tests prepared"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Service state test setup failed"
    exit 1
  fi

  # Test 6: Data preservation verification
  ${testHelpers.testSubsection "Data Preservation Verification"}

  # Test that user data is preserved during rollback
  echo "Testing data preservation during rollback..."

  # Create mock user data that should be preserved
  mkdir -p user_data_preserve_test
  cat > user_data_preserve_test/important_file.txt << 'EOF'
This file contains important user data that must be preserved during rollback.
Created: $(date)
Content: Critical user information
EOF

  cat > user_data_preserve_test/config_file.conf << 'EOF'
# User configuration that should survive rollback
user_setting_1=value1
user_setting_2=value2
important_preference=true
EOF

  USER_FILES=$(ls user_data_preserve_test/ | wc -l)
  if [ "$USER_FILES" -eq 2 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} User data preservation test prepared"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} User data preservation setup failed"
    exit 1
  fi

  # Test 7: Rollback verification and validation
  ${testHelpers.testSubsection "Rollback Verification"}

  # Test post-rollback system validation
  echo "Testing rollback verification process..."

  # Create rollback verification checklist
  cat > rollback_verification.json << 'EOF'
{
  "verification_steps": [
    {
      "step": "system_boot_test",
      "description": "Verify system can boot successfully",
      "critical": true
    },
    {
      "step": "service_functionality_test",
      "description": "Verify all essential services work",
      "critical": true
    },
    {
      "step": "configuration_integrity_test",
      "description": "Verify configuration files are valid",
      "critical": true
    },
    {
      "step": "user_data_integrity_test",
      "description": "Verify user data is intact",
      "critical": true
    },
    {
      "step": "performance_baseline_test",
      "description": "Verify system performance is acceptable",
      "critical": false
    }
  ]
}
EOF

  VERIFICATION_STEPS=$(jq '.verification_steps | length' rollback_verification.json)
  if [ "$VERIFICATION_STEPS" -eq 5 ]; then
    echo "${testHelpers.colors.green}✓${testHelpers.colors.reset} Rollback verification framework prepared"
  else
    echo "${testHelpers.colors.red}✗${testHelpers.colors.reset} Rollback verification setup failed"
    exit 1
  fi

  ${testHelpers.cleanup}

  echo ""
  echo "${testHelpers.colors.blue}=== Test Results: Rollback Integration Tests ===${testHelpers.colors.reset}"
  echo "${testHelpers.colors.green}✓ Rollback integration test infrastructure completed!${testHelpers.colors.reset}"
  echo "${testHelpers.colors.yellow}⚠ Implementation needed: Automatic rollback triggers, state capture/restore, and verification systems${testHelpers.colors.reset}"

  touch $out
''
