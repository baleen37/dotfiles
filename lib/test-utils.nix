# Test Utilities and Helpers - Legacy Compatibility Wrapper
# Redirects to unified test-system.nix
# Provides test discovery and reporting functionality

{ pkgs }:

let
  # Import unified test system
  testSystem = import ./test-system.nix { inherit pkgs; };

in
# Re-export test utilities from unified system with legacy compatibility
{
  # Export core utility functions
  inherit (testSystem.utils) mkTestReporter mkTestDiscovery mkEnhancedTestRunner mkTestSuite;

  # Version metadata
  version = "2.0.0-unified";
  description = "Test utilities with unified backend";
}
