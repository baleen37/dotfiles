{ pkgs, lib ? pkgs.lib }:

let
  # Import test utilities
  testLib = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Alternative execution paths test module
  alternativeExecutionPathsTest = testLib.makeTest {
    name = "alternative-execution-paths-test";

    testScript = ''
      # Test fallback execution mechanisms
      print("Testing fallback execution mechanisms...")

      # Test fallback_execution function
      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          fallback_execution() {
            local primary_command="\''$1"
            local fallback_command="\''$2"
            local execution_context="\''$3"

            echo "Attempting primary execution: \''$primary_command"

            # Try primary command first
            if eval "\''$primary_command" >/dev/null 2>&1; then
              echo "Primary execution successful"
              return 0
            fi

            echo "Primary execution failed, trying fallback: \''$fallback_command"

            # Try fallback command
            if eval "\''$fallback_command" >/dev/null 2>&1; then
              echo "Fallback execution successful"
              return 0
            fi

            echo "Both primary and fallback execution failed"
            return 1
          }

          # Test successful primary execution
          fallback_execution "echo 'primary success'" "echo 'fallback'" "test"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Fallback execution test failed: {result.stderr}"
      assert "Primary execution successful" in result.stdout

      # Test fallback when primary fails
      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          fallback_execution() {
            local primary_command="\''$1"
            local fallback_command="\''$2"
            local execution_context="\''$3"

            echo "Attempting primary execution: \''$primary_command"

            if eval "\''$primary_command" >/dev/null 2>&1; then
              echo "Primary execution successful"
              return 0
            fi

            echo "Primary execution failed, trying fallback: \''$fallback_command"

            if eval "\''$fallback_command" >/dev/null 2>&1; then
              echo "Fallback execution successful"
              return 0
            fi

            echo "Both primary and fallback execution failed"
            return 1
          }

          # Test fallback when primary fails
          fallback_execution "false" "echo 'fallback success'" "test"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Fallback execution test failed: {result.stderr}"
      assert "Fallback execution successful" in result.stdout

      # Test alternative_build_method function
      print("Testing alternative build methods...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          alternative_build_method() {
            local build_type="\''$1"
            local platform_type="\''$2"

            echo "Attempting alternative build method (type: \''$build_type, platform: \''$platform_type)"

            case "\''$build_type" in
              "direct")
                echo "Using direct nix build approach"
                # Simulate direct nix build
                if command -v nix >/dev/null 2>&1; then
                  echo "Direct build method available"
                  return 0
                else
                  echo "Direct build method unavailable"
                  return 1
                fi
                ;;
              "legacy")
                echo "Using legacy build approach"
                # Simulate legacy build approach
                echo "Legacy build method available"
                return 0
                ;;
              "minimal")
                echo "Using minimal build approach"
                # Simulate minimal build
                echo "Minimal build method available"
                return 0
                ;;
              *)
                echo "Unknown build method: \''$build_type"
                return 1
                ;;
            esac
          }

          # Test different build methods
          alternative_build_method "direct" "darwin"
          echo "---"
          alternative_build_method "legacy" "darwin"
          echo "---"
          alternative_build_method "minimal" "darwin"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Alternative build method test failed: {result.stderr}"
      assert "Direct build method" in result.stdout
      assert "Legacy build method" in result.stdout
      assert "Minimal build method" in result.stdout

      # Test emergency_mode function
      print("Testing emergency mode...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          emergency_mode() {
            local emergency_type="\''$1"
            local recovery_action="\''$2"

            echo "Entering emergency mode (type: \''$emergency_type)"

            case "\''$emergency_type" in
              "network_failure")
                echo "Network failure detected - enabling offline mode"
                export OFFLINE_MODE=true
                echo "Emergency mode: offline operations only"
                return 0
                ;;
              "build_failure")
                echo "Build failure detected - attempting recovery"
                case "\''$recovery_action" in
                  "cleanup")
                    echo "Emergency mode: cleaning build cache"
                    ;;
                  "rollback")
                    echo "Emergency mode: rolling back to previous state"
                    ;;
                  "minimal")
                    echo "Emergency mode: minimal build only"
                    ;;
                esac
                return 0
                ;;
              "dependency_failure")
                echo "Dependency failure detected - using alternative dependencies"
                echo "Emergency mode: alternative dependency resolution"
                return 0
                ;;
              *)
                echo "Unknown emergency type: \''$emergency_type"
                return 1
                ;;
            esac
          }

          # Test different emergency modes
          emergency_mode "network_failure" ""
          echo "---"
          emergency_mode "build_failure" "cleanup"
          echo "---"
          emergency_mode "build_failure" "rollback"
          echo "---"
          emergency_mode "dependency_failure" ""
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Emergency mode test failed: {result.stderr}"
      assert "Network failure detected" in result.stdout
      assert "Build failure detected" in result.stdout
      assert "Dependency failure detected" in result.stdout

      # Test alternative execution path selection
      print("Testing execution path selection...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          select_execution_path() {
            local failure_context="\''$1"
            local available_methods="\''$2"

            echo "Selecting execution path for failure: \''$failure_context"
            echo "Available methods: \''$available_methods"

            case "\''$failure_context" in
              "network_timeout")
                echo "Selected path: offline_mode"
                return 0
                ;;
              "build_dependency_missing")
                echo "Selected path: alternative_dependencies"
                return 0
                ;;
              "insufficient_permissions")
                echo "Selected path: user_mode_build"
                return 0
                ;;
              "resource_exhaustion")
                echo "Selected path: minimal_build"
                return 0
                ;;
              *)
                echo "Selected path: emergency_mode"
                return 0
                ;;
            esac
          }

          # Test path selection for different failure scenarios
          select_execution_path "network_timeout" "offline_mode,emergency_mode"
          echo "---"
          select_execution_path "build_dependency_missing" "alternative_dependencies,minimal_build"
          echo "---"
          select_execution_path "insufficient_permissions" "user_mode_build,minimal_build"
          echo "---"
          select_execution_path "resource_exhaustion" "minimal_build,emergency_mode"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Execution path selection test failed: {result.stderr}"
      assert "Selected path: offline_mode" in result.stdout
      assert "Selected path: alternative_dependencies" in result.stdout
      assert "Selected path: user_mode_build" in result.stdout
      assert "Selected path: minimal_build" in result.stdout

      # Test execution path recovery and state management
      print("Testing execution path recovery...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          track_execution_attempts() {
            local attempt_file="\''$1"
            local execution_path="\''$2"
            local result="\''$3"

            echo "Tracking execution attempt: \''$execution_path -> \''$result"

            # Create attempt tracking file
            mkdir -p "\''$(dirname "\''$attempt_file")"

            cat >> "\''$attempt_file" << EOF
{
  "timestamp": "\''$(date -Iseconds)",
  "execution_path": "\''$execution_path",
  "result": "\''$result"
}
EOF

            echo "Execution attempt tracked in \''$attempt_file"
          }

          recover_from_failure() {
            local attempt_file="\''$1"
            local max_attempts="\''$2"

            echo "Analyzing execution attempts for recovery"

            if [ -f "\''$attempt_file" ]; then
              local attempt_count=\''$(wc -l < "\''$attempt_file")
              echo "Found \''$attempt_count previous attempts"

              if [ "\''$attempt_count" -ge "\''$max_attempts" ]; then
                echo "Maximum attempts exceeded - entering emergency mode"
                return 1
              else
                echo "Retry possible - \''$((max_attempts - attempt_count)) attempts remaining"
                return 0
              fi
            else
              echo "No previous attempts found - first execution"
              return 0
            fi
          }

          # Test tracking and recovery
          temp_file="\''$(mktemp)"
          track_execution_attempts "\''$temp_file" "primary_build" "failed"
          track_execution_attempts "\''$temp_file" "fallback_build" "failed"

          echo "Recovery check 1:"
          recover_from_failure "\''$temp_file" "5"

          echo "Recovery check 2:"
          track_execution_attempts "\''$temp_file" "emergency_build" "failed"
          track_execution_attempts "\''$temp_file" "minimal_build" "failed"
          track_execution_attempts "\''$temp_file" "last_resort" "failed"
          recover_from_failure "\''$temp_file" "5"

          rm -f "\''$temp_file"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Execution path recovery test failed: {result.stderr}"
      assert "Execution attempt tracked" in result.stdout
      assert "Retry possible" in result.stdout
      assert "Maximum attempts exceeded" in result.stdout

      print("All alternative execution paths tests passed!")
    '';
  };

in alternativeExecutionPathsTest
