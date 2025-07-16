{ pkgs, lib ? pkgs.lib }:
let
  testHelpers = import ./test-helpers.nix { inherit pkgs; };
in
rec {
  # Create a mock system state with configurable properties
  createMockSystemState = { platform ? "aarch64-darwin", hasResult ? false, hasDirtyState ? false, hasPermissionIssues ? false, ... }:
    let
      stateDir = "${testHelpers.createTempDir}/mock_system_state";
      mockSystemScript = pkgs.writeScript "mock-system-state" ''
        #!/bin/bash
        set -e

        # Setup mock system state directory
        mkdir -p "${stateDir}"
        cd "${stateDir}"

        # Mock platform type
        export PLATFORM_TYPE="${platform}"
        export SYSTEM_TYPE="${platform}"

        # Create mock result symlink if requested
        ${lib.optionalString hasResult ''
          mkdir -p mock_result/sw/bin
          echo '#!/bin/bash' > mock_result/sw/bin/darwin-rebuild
          echo 'echo "Mock rebuild command executed with: $@"' >> mock_result/sw/bin/darwin-rebuild
          chmod +x mock_result/sw/bin/darwin-rebuild
          ln -sf mock_result result
        ''}

        # Create dirty state if requested
        ${lib.optionalString hasDirtyState ''
          echo "dirty_file" > dirty_state.txt
          mkdir -p .git
          echo "ref: refs/heads/feature-branch" > .git/HEAD
        ''}

        # Create permission issues if requested
        ${lib.optionalString hasPermissionIssues ''
          mkdir -p restricted_dir
          chmod 000 restricted_dir
        ''}

        # Create mock flake.nix
        cat > flake.nix << 'EOF'
        {
          description = "Mock system flake";
          inputs = {
            nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
          };
          outputs = { self, nixpkgs }: {
            darwinConfigurations.${platform}.system = nixpkgs.lib.nixosSystem {
              system = "${platform}";
              modules = [ ];
            };
          };
        }
        EOF

        echo "Mock system state created at ${stateDir}"
        echo "Platform: ${platform}"
        echo "Has result: ${toString hasResult}"
        echo "Has dirty state: ${toString hasDirtyState}"
        echo "Has permission issues: ${toString hasPermissionIssues}"

        # Return the state directory path
        echo "${stateDir}"
      '';
    in
    {
      inherit stateDir;
      script = mockSystemScript;
      platform = platform;
      hasResult = hasResult;
      hasDirtyState = hasDirtyState;
      hasPermissionIssues = hasPermissionIssues;
    };

  # Mock system state scenarios for testing
  mockSystemScenarios = {
    cleanState = createMockSystemState {
      platform = "aarch64-darwin";
      hasResult = false;
      hasDirtyState = false;
      hasPermissionIssues = false;
    };

    cachedState = createMockSystemState {
      platform = "aarch64-darwin";
      hasResult = true;
      hasDirtyState = false;
      hasPermissionIssues = false;
    };

    dirtyState = createMockSystemState {
      platform = "aarch64-darwin";
      hasResult = true;
      hasDirtyState = true;
      hasPermissionIssues = false;
    };

    permissionIssues = createMockSystemState {
      platform = "aarch64-darwin";
      hasResult = false;
      hasDirtyState = false;
      hasPermissionIssues = true;
    };

    linuxCleanState = createMockSystemState {
      platform = "x86_64-linux";
      hasResult = false;
      hasDirtyState = false;
      hasPermissionIssues = false;
    };
  };

  # Test system state validation
  validateSystemState = { expectedPlatform, expectedHasResult, expectedHasDirtyState, ... }:
    testHelpers.createTestScript {
      name = "validate-system-state";
      script = ''
        # Validate platform
        if [ "$PLATFORM_TYPE" != "${expectedPlatform}" ]; then
          echo "Platform mismatch: expected ${expectedPlatform}, got $PLATFORM_TYPE"
          exit 1
        fi

        # Validate result symlink
        if [ "${toString expectedHasResult}" = "true" ]; then
          ${testHelpers.assertExists "./result" "Result symlink should exist"}
        else
          if [ -L "./result" ]; then
            echo "Result symlink should not exist"
            exit 1
          fi
        fi

        # Validate dirty state
        if [ "${toString expectedHasDirtyState}" = "true" ]; then
          ${testHelpers.assertExists "./dirty_state.txt" "Dirty state file should exist"}
        else
          if [ -f "./dirty_state.txt" ]; then
            echo "Dirty state file should not exist"
            exit 1
          fi
        fi

        echo "System state validation passed"
      '';
    };

  # Simulate system state transitions
  simulateStateTransition = { fromState, toState, operation ? "build" }:
    testHelpers.createTestScript {
      name = "simulate-state-transition-${operation}";
      script = ''
        echo "Simulating state transition: ${fromState} -> ${toState} (${operation})"

        # Mock state transition logic
        case "${operation}" in
          "build")
            echo "Simulating build operation..."
            if [ "${fromState}" = "clean" ]; then
              # Clean -> Building
              echo "Creating build artifacts..."
              mkdir -p build_artifacts
              echo "build_in_progress" > build_artifacts/status
            fi
            ;;
          "switch")
            echo "Simulating switch operation..."
            if [ "${fromState}" = "built" ]; then
              # Built -> Switched
              echo "Applying configuration..."
              echo "configuration_applied" > system_status
            fi
            ;;
          "rollback")
            echo "Simulating rollback operation..."
            echo "Rolling back to previous state..."
            echo "rolled_back" > system_status
            ;;
        esac

        echo "State transition simulation completed"
      '';
    };
}
