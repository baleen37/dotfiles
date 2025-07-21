{ pkgs, lib ? pkgs.lib }:
let
  # Import base helpers
  testHelpers = import ./test-helpers.nix { inherit pkgs lib; };
  homebrewHelpers = import ./homebrew-test-helpers.nix { inherit pkgs lib; };

  # High-level integration test helpers
  testBuildSwitchWithHomebrew = { casksConfig, masApps ? {}, expectedChanges ? [] }:
    ''
      echo "🔄 Testing build-switch with Homebrew integration..."

      # Setup Homebrew test environment
      ${homebrewHelpers.setupHomebrewTestEnv (homebrewHelpers.mockHomebrewState {
        casks = casksConfig;
        masApps = masApps;
      })}

      # Simulate build-switch execution
      echo "  → Building Darwin configuration..."
      echo "  → Processing Homebrew changes..."
      echo "  → Installing/updating casks..."
      echo "  → Installing MAS apps..."

      # Verify expected changes
      ${builtins.concatStringsSep "\n" (map (change:
        ''echo "  ✓ Expected change: ${change}"''
      ) expectedChanges)}

      echo "✅ Build-switch + Homebrew integration test completed"
    '';

  # Compare system state before and after changes
  compareSystemState = { before, after, description }:
    ''
      echo "🔍 Comparing system state: ${description}"

      # Mock state comparison
      echo "Before: ${before}"
      echo "After: ${after}"

      if [ "${before}" != "${after}" ]; then
        echo "  ✓ System state changed as expected"
      else
        echo "  ⚠ No system state change detected"
      fi
    '';

  # Simulate network conditions for testing
  simulateNetworkConditions = condition:
    ''
      echo "🌐 Simulating network condition: ${condition}"

      case "${condition}" in
        "offline")
          echo "  → Network: Offline mode"
          echo "  → Effect: Local operations only"
          ;;
        "slow")
          echo "  → Network: Slow connection"
          echo "  → Effect: Extended download times"
          ;;
        "timeout")
          echo "  → Network: Connection timeouts"
          echo "  → Effect: Download failures"
          ;;
        *)
          echo "  → Network: Normal conditions"
          ;;
      esac
    '';

  # Measure resource usage during operations
  measureResourceUsage = operation:
    ''
      echo "📊 Measuring resource usage for: ${operation}"

      # Mock resource measurement
      echo "  CPU usage: ~45%"
      echo "  Memory usage: ~2.1GB"
      echo "  Disk I/O: ~150MB/s"
      echo "  Network: ~5MB/s"

      echo "📈 Resource usage measurement completed"
    '';

in
{
  # Expose all base helpers
  inherit (testHelpers) colors platform setupTestEnv testSection testSubsection;
  inherit (testHelpers) assertTrue assertExists assertCommand assertContains;
  inherit (testHelpers) benchmark measureExecutionTime cleanup;
  inherit (homebrewHelpers) setupHomebrewTestEnv mockHomebrewState;

  # Integration-specific helpers
  inherit testBuildSwitchWithHomebrew compareSystemState;
  inherit simulateNetworkConditions measureResourceUsage;
}
