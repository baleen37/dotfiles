# Simplified test applications module
# Provides test-related app definitions for both Darwin and Linux systems

{ nixpkgs, self }:

let
  # Simple test app builder
  mkTestApp = { name, system, command }: {
    type = "app";
    program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin name ''
      #!/usr/bin/env bash
      echo "Running ${name} for ${system}..."
      ${command}
    '')}/bin/${name}";
  };

  # Build test apps for a system
  mkTestApps = system: {
    # Run all tests
    "test" = mkTestApp {
      name = "test";
      inherit system;
      command = ''
        echo "Running all tests..."
        nix build --impure .#checks.${system}.test-all -L
      '';
    };

    # Run core tests only (fast, essential)
    "test-core" = mkTestApp {
      name = "test-core";
      inherit system;
      command = ''
        echo "Running core tests..."
        nix build --impure .#checks.${system}.test-core -L
      '';
    };

    # Run workflow tests (end-to-end)
    "test-workflow" = mkTestApp {
      name = "test-workflow";
      inherit system;
      command = ''
        echo "Running workflow tests..."
        nix build --impure .#checks.${system}.test-workflow -L
      '';
    };

    # Run performance tests
    "test-perf" = mkTestApp {
      name = "test-perf";
      inherit system;
      command = ''
        echo "Running performance tests..."
        nix build --impure .#checks.${system}.test-perf -L
      '';
    };

    # Run unit tests (alias for test-core)
    "test-unit" = mkTestApp {
      name = "test-unit";
      inherit system;
      command = ''
        echo "Running unit tests..."
        nix build --impure .#checks.${system}.test-core -L
      '';
    };

    # Run integration tests (alias for test-workflow)
    "test-integration" = mkTestApp {
      name = "test-integration";
      inherit system;
      command = ''
        echo "Running integration tests..."
        nix build --impure .#checks.${system}.test-workflow -L
      '';
    };

    # Quick smoke test (just flake checks)
    "test-smoke" = mkTestApp {
      name = "test-smoke";
      inherit system;
      command = ''
        echo "Running smoke tests..."
        # Basic flake evaluation test - only check syntax
        echo "Checking flake outputs..."
        nix flake show --impure > /dev/null
        echo "Checking devShells..."
        nix build --dry-run .#devShells.${system}.default
        echo "Smoke test completed successfully!"
      '';
    };

    # List available tests
    "test-list" = mkTestApp {
      name = "test-list";
      inherit system;
      command = ''
        echo "=== Simplified Test Framework ==="
        echo ""
        echo "Available test commands:"
        echo "  test         - Run all tests"
        echo "  test-core    - Run core tests (fast, essential)"
        echo "  test-workflow - Run workflow tests (end-to-end)"
        echo "  test-unit    - Run unit tests (alias for test-core)"
        echo "  test-integration - Run integration tests (alias for test-workflow)"
        echo "  test-perf    - Run performance tests"
        echo "  test-smoke   - Quick smoke test (flake check)"
        echo ""
        echo "Categories:"
        echo "  Core:        Essential functionality tests"
        echo "  Workflow:    End-to-end user workflow tests"
        echo "  Performance: Build time and resource usage tests"
      '';
    };
  };
in
{
  # Export function for use in flake.nix
  mkTestApps = mkTestApps;

  # For backwards compatibility
  mkLinuxTestApps = mkTestApps;
  mkDarwinTestApps = mkTestApps;
}
