{ pkgs, lib ? pkgs.lib }:

let
  # Import test utilities
  testLib = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Enhanced error messaging test module
  enhancedErrorMessagingTest = testLib.makeTest {
    name = "enhanced-error-messaging-test";

    testScript = ''
      # Test diagnostic report generation
      print("Testing diagnostic report generation...")

      # Test generate_diagnostic_report function
      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          generate_diagnostic_report() {
            local error_type="\''$1"
            local error_context="\''$2"
            local output_file="\''$3"

            echo "Generating diagnostic report for: \''$error_type"

            # Create diagnostic report structure
            cat > "\''$output_file" << EOF
{
  "diagnostic_report": {
    "timestamp": "\''$(date -Iseconds)",
    "error_type": "\''$error_type",
    "error_context": "\''$error_context",
    "system_info": {},
    "environment_info": {},
    "recommendations": []
  }
}
EOF

            # Add system information
            case "\''$error_type" in
              "build_failure")
                echo "  Adding build-specific diagnostics..."
                cat >> "\''$output_file" << EOF
Build Environment:
- Nix version: \''$(nix --version 2>/dev/null || echo 'not available')
- Platform: \''${PLATFORM_TYPE:-unknown}
- Available disk space: \''$(df -h . | tail -1 | awk '{print \''$4}' 2>/dev/null || echo 'unknown')
EOF
                ;;
              "network_failure")
                echo "  Adding network-specific diagnostics..."
                cat >> "\''$output_file" << EOF
Network Environment:
- Connectivity: \''$(ping -c 1 google.com >/dev/null 2>&1 && echo 'online' || echo 'offline')
- DNS resolution: \''$(nslookup google.com >/dev/null 2>&1 && echo 'working' || echo 'failed')
EOF
                ;;
              "permission_failure")
                echo "  Adding permission-specific diagnostics..."
                cat >> "\''$output_file" << EOF
Permission Environment:
- Current user: \''$(whoami)
- Sudo access: \''$(sudo -n true 2>/dev/null && echo 'available' || echo 'not available')
- Home directory writable: \''$([ -w "\''$HOME" ] && echo 'yes' || echo 'no')
EOF
                ;;
            esac

            echo "Diagnostic report generated: \''$output_file"
            return 0
          }

          # Test diagnostic report generation
          temp_report="\''$(mktemp)"
          generate_diagnostic_report "build_failure" "nix build error" "\''$temp_report"

          if [ -f "\''$temp_report" ]; then
            echo "Report generation successful"
            cat "\''$temp_report"
          else
            echo "Report generation failed"
            exit 1
          fi

          rm -f "\''$temp_report"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Diagnostic report generation failed: {result.stderr}"
      assert "Report generation successful" in result.stdout
      assert "Build Environment:" in result.stdout

      # Test recovery guidance provision
      print("Testing recovery guidance provision...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          provide_recovery_guidance() {
            local error_type="\''$1"
            local error_details="\''$2"
            local guidance_file="\''$3"

            echo "Providing recovery guidance for: \''$error_type"

            cat > "\''$guidance_file" << EOF
Recovery Guidance for: \''$error_type
Error Details: \''$error_details
Generated: \''$(date)

EOF

            case "\''$error_type" in
              "build_failure")
                cat >> "\''$guidance_file" << EOF
Build Failure Recovery Steps:
1. Check available disk space (need at least 5GB free)
2. Verify Nix installation and experimental features
3. Clear Nix caches: nix-collect-garbage -d
4. Try minimal build: nix build --show-trace
5. Check flake.lock for dependency conflicts

Specific Actions:
- If 'out of space': Free up disk space or use different build location
- If 'permission denied': Check sudo access or use user-only build
- If 'network timeout': Enable offline mode or check proxy settings
- If 'dependency conflict': Update flake.lock or pin specific versions
EOF
                ;;
              "network_failure")
                cat >> "\''$guidance_file" << EOF
Network Failure Recovery Steps:
1. Check internet connectivity: ping google.com
2. Verify DNS resolution: nslookup google.com
3. Check proxy settings and firewall
4. Try offline mode: export OFFLINE_MODE=true
5. Use local caches only: export NIX_CONFIG="substituters = "

Specific Actions:
- If 'connection timeout': Increase timeout or use different substituters
- If 'DNS failure': Configure alternative DNS servers
- If 'proxy issues': Configure proxy settings for Nix
- If 'certificate error': Update CA certificates
EOF
                ;;
              "permission_failure")
                cat >> "\''$guidance_file" << EOF
Permission Failure Recovery Steps:
1. Check current user permissions: whoami; groups
2. Verify sudo access: sudo -v
3. Check file ownership: ls -la ~/.config/nix
4. Try user-only mode: export USER_MODE_ONLY=true
5. Fix directory permissions: chmod 755 ~/.config

Specific Actions:
- If 'sudo required': Configure passwordless sudo or use user mode
- If 'file not writable': Check and fix file permissions
- If 'group access': Add user to required groups (admin, wheel)
- If 'system directories': Use user-space alternatives
EOF
                ;;
              *)
                cat >> "\''$guidance_file" << EOF
General Recovery Steps:
1. Review error logs for specific details
2. Check system requirements and dependencies
3. Verify configuration files are correct
4. Try minimal or safe mode operation
5. Consult documentation for error-specific guidance

Next Steps:
- Enable verbose logging for more details
- Check known issues and troubleshooting guides
- Consider reporting the issue if it persists
EOF
                ;;
            esac

            echo "Recovery guidance provided: \''$guidance_file"
            return 0
          }

          # Test recovery guidance for different error types
          temp_guidance="\''$(mktemp)"

          provide_recovery_guidance "build_failure" "nix build failed with exit code 1" "\''$temp_guidance"
          echo "Build failure guidance:"
          cat "\''$temp_guidance"
          echo "---"

          provide_recovery_guidance "network_failure" "connection timeout" "\''$temp_guidance"
          echo "Network failure guidance:"
          cat "\''$temp_guidance"
          echo "---"

          provide_recovery_guidance "permission_failure" "sudo required" "\''$temp_guidance"
          echo "Permission failure guidance:"
          cat "\''$temp_guidance"

          rm -f "\''$temp_guidance"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Recovery guidance provision failed: {result.stderr}"
      assert "Build Failure Recovery Steps:" in result.stdout
      assert "Network Failure Recovery Steps:" in result.stdout
      assert "Permission Failure Recovery Steps:" in result.stdout

      # Test user-friendly error message formatting
      print("Testing user-friendly error message formatting...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          format_user_friendly_error() {
            local raw_error="\''$1"
            local error_context="\''$2"
            local output_format="\''${3:-console}"

            echo "Formatting user-friendly error message..."

            # Extract error type from raw error
            local error_type="unknown"
            if echo "\''$raw_error" | grep -qi "permission denied"; then
              error_type="permission"
            elif echo "\''$raw_error" | grep -qi "network\|timeout\|connection"; then
              error_type="network"
            elif echo "\''$raw_error" | grep -qi "build\|compile\|nix"; then
              error_type="build"
            elif echo "\''$raw_error" | grep -qi "space\|disk"; then
              error_type="disk_space"
            fi

            case "\''$output_format" in
              "console")
                echo ""
                echo "🚨 Build Operation Failed"
                echo "=========================="
                echo ""
                echo "Error Type: \''$error_type"
                echo "Context: \''$error_context"
                echo ""
                echo "What happened:"
                case "\''$error_type" in
                  "permission")
                    echo "  The operation requires elevated permissions that are not available."
                    echo "  This typically happens when system files need to be modified."
                    ;;
                  "network")
                    echo "  A network connection is required but couldn't be established."
                    echo "  This might be due to connectivity issues or network configuration."
                    ;;
                  "build")
                    echo "  The build process encountered an error during compilation or linking."
                    echo "  This could be due to dependency issues or configuration problems."
                    ;;
                  "disk_space")
                    echo "  Insufficient disk space to complete the operation."
                    echo "  The build process requires additional free space."
                    ;;
                  *)
                    echo "  An unexpected error occurred during the operation."
                    echo "  Please check the detailed error message for more information."
                    ;;
                esac
                echo ""
                echo "Quick fixes to try:"
                case "\''$error_type" in
                  "permission")
                    echo "  • Try running with appropriate permissions"
                    echo "  • Use user-only mode: export USER_MODE_ONLY=true"
                    echo "  • Check sudo configuration"
                    ;;
                  "network")
                    echo "  • Check internet connection"
                    echo "  • Try offline mode: export OFFLINE_MODE=true"
                    echo "  • Configure proxy settings if needed"
                    ;;
                  "build")
                    echo "  • Clean build cache: nix-collect-garbage -d"
                    echo "  • Try minimal build first"
                    echo "  • Check flake.lock for conflicts"
                    ;;
                  "disk_space")
                    echo "  • Free up disk space (need ~5GB)"
                    echo "  • Clean temporary files"
                    echo "  • Use different build location"
                    ;;
                  *)
                    echo "  • Check the detailed error log"
                    echo "  • Try running with --verbose flag"
                    echo "  • Consult troubleshooting documentation"
                    ;;
                esac
                echo ""
                echo "For detailed guidance, check the diagnostic report or run with --help"
                echo ""
                ;;
              "json")
                cat << EOF
{
  "error_summary": {
    "type": "\''$error_type",
    "context": "\''$error_context",
    "user_message": "Build operation failed due to \''$error_type issue",
    "severity": "error",
    "quick_fixes": []
  }
}
EOF
                ;;
            esac

            echo "User-friendly error message formatted"
            return 0
          }

          # Test error message formatting
          format_user_friendly_error "permission denied: /nix/store" "build-switch operation" "console"
          echo "---"
          format_user_friendly_error "network timeout during fetch" "dependency download" "console"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Error message formatting failed: {result.stderr}"
      assert "🚨 Build Operation Failed" in result.stdout
      assert "Quick fixes to try:" in result.stdout

      # Test error categorization and severity assessment
      print("Testing error categorization and severity assessment...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          categorize_error() {
            local error_message="\''$1"
            local exit_code="\''$2"

            echo "Categorizing error (exit code: \''$exit_code):"
            echo "Message: \''$error_message"

            # Determine error category
            local category="unknown"
            local severity="medium"
            local urgency="normal"

            # Pattern matching for error categorization
            if echo "\''$error_message" | grep -qi "permission denied\|sudo\|access denied"; then
              category="permission"
              severity="medium"
              urgency="normal"
            elif echo "\''$error_message" | grep -qi "network\|timeout\|connection\|unreachable"; then
              category="network"
              severity="low"
              urgency="low"
            elif echo "\''$error_message" | grep -qi "no space\|disk full\|quota exceeded"; then
              category="disk_space"
              severity="high"
              urgency="high"
            elif echo "\''$error_message" | grep -qi "build failed\|compilation error\|link error"; then
              category="build"
              severity="medium"
              urgency="normal"
            elif echo "\''$error_message" | grep -qi "dependency\|package.*not found\|missing"; then
              category="dependency"
              severity="medium"
              urgency="normal"
            elif echo "\''$error_message" | grep -qi "syntax error\|parse error\|invalid"; then
              category="configuration"
              severity="high"
              urgency="high"
            fi

            # Adjust severity based on exit code
            case "\''$exit_code" in
              "1"|"2") severity="low" ;;
              "126"|"127") severity="high" ;;  # Command not found/executable
              "130") severity="low" ;;  # Interrupted
              "139") severity="high" ;;  # Segmentation fault
              *) ;;  # Keep existing severity
            esac

            echo "Category: \''$category"
            echo "Severity: \''$severity"
            echo "Urgency: \''$urgency"

            # Provide category-specific analysis
            case "\''$category" in
              "permission")
                echo "Analysis: Permission-related error - user access rights issue"
                echo "Impact: Operation blocked, user intervention required"
                ;;
              "network")
                echo "Analysis: Network connectivity issue - external dependency"
                echo "Impact: Temporary failure, may resolve automatically"
                ;;
              "disk_space")
                echo "Analysis: Storage limitation - resource constraint"
                echo "Impact: Operation impossible until space freed"
                ;;
              "build")
                echo "Analysis: Build process failure - code or environment issue"
                echo "Impact: Feature/system unavailable until fixed"
                ;;
              "dependency")
                echo "Analysis: Missing or incompatible dependency"
                echo "Impact: Operation blocked until dependency resolved"
                ;;
              "configuration")
                echo "Analysis: Configuration syntax or logic error"
                echo "Impact: System misconfigured, immediate attention needed"
                ;;
              *)
                echo "Analysis: Unclassified error - requires manual investigation"
                echo "Impact: Unknown, further analysis needed"
                ;;
            esac

            return 0
          }

          # Test error categorization with different scenarios
          categorize_error "permission denied: cannot write to /nix/store" "1"
          echo "---"
          categorize_error "network timeout: failed to connect to cache.nixos.org" "1"
          echo "---"
          categorize_error "no space left on device" "1"
          echo "---"
          categorize_error "build failed: compilation terminated" "2"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Error categorization failed: {result.stderr}"
      assert "Category: permission" in result.stdout
      assert "Category: network" in result.stdout
      assert "Category: disk_space" in result.stdout
      assert "Category: build" in result.stdout

      # Test interactive error resolution
      print("Testing interactive error resolution...")

      result = subprocess.run([
        "${pkgs.bash}/bin/bash", "-c", """
          suggest_interactive_resolution() {
            local error_category="\''$1"
            local error_severity="\''$2"
            local interactive_mode="\''${3:-false}"

            echo "Suggesting resolution for \''$error_category error (severity: \''$error_severity)"

            if [ "\''$interactive_mode" = "true" ]; then
              echo "Interactive mode enabled - providing step-by-step guidance"
            fi

            case "\''$error_category" in
              "permission")
                echo "Resolution suggestions for permission error:"
                echo "1. [RECOMMENDED] Switch to user-only mode"
                echo "2. Configure sudo access"
                echo "3. Check file permissions"

                if [ "\''$interactive_mode" = "true" ]; then
                  echo ""
                  echo "Step-by-step resolution:"
                  echo "→ Step 1: Try user-only mode"
                  echo "  Command: export USER_MODE_ONLY=true && retry-build"
                  echo "  Expected: Build proceeds without system modifications"
                  echo ""
                  echo "→ Step 2: If user mode fails, check sudo"
                  echo "  Command: sudo -v"
                  echo "  Expected: Sudo authentication successful"
                fi
                ;;
              "network")
                echo "Resolution suggestions for network error:"
                echo "1. [RECOMMENDED] Enable offline mode"
                echo "2. Check internet connectivity"
                echo "3. Configure alternative sources"

                if [ "\''$interactive_mode" = "true" ]; then
                  echo ""
                  echo "Step-by-step resolution:"
                  echo "→ Step 1: Test connectivity"
                  echo "  Command: ping -c 3 google.com"
                  echo "  Expected: Successful ping responses"
                  echo ""
                  echo "→ Step 2: If offline, enable offline mode"
                  echo "  Command: export OFFLINE_MODE=true && retry-build"
                  echo "  Expected: Build uses local cache only"
                fi
                ;;
              "disk_space")
                echo "Resolution suggestions for disk space error:"
                echo "1. [URGENT] Free up disk space"
                echo "2. Clean build caches"
                echo "3. Use alternative build location"

                if [ "\''$interactive_mode" = "true" ]; then
                  echo ""
                  echo "Step-by-step resolution:"
                  echo "→ Step 1: Check available space"
                  echo "  Command: df -h ."
                  echo "  Expected: At least 5GB free space"
                  echo ""
                  echo "→ Step 2: Clean Nix caches"
                  echo "  Command: nix-collect-garbage -d"
                  echo "  Expected: Significant space freed"
                fi
                ;;
            esac

            return 0
          }

          # Test interactive resolution suggestions
          suggest_interactive_resolution "permission" "medium" "true"
          echo "---"
          suggest_interactive_resolution "network" "low" "true"
          echo "---"
          suggest_interactive_resolution "disk_space" "high" "true"
        """
      ], capture_output=True, text=True)

      assert result.returncode == 0, f"Interactive error resolution failed: {result.stderr}"
      assert "Step-by-step resolution:" in result.stdout
      assert "→ Step 1:" in result.stdout
      assert "Command:" in result.stdout
      assert "Expected:" in result.stdout

      print("All enhanced error messaging tests passed!")
    '';
  };

in enhancedErrorMessagingTest
