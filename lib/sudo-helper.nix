# Sudo permission management utilities for build-switch operations
# Provides consistent, early permission handling across all platforms

{ nixpkgs, system }:

let
  pkgs = nixpkgs.legacyPackages.${system};

  # Generate platform-specific sudo helper script
  mkSudoHelper = {
    platform ? "unknown",
    environmentVars ? [],
    sshForwarding ? false
  }:
    pkgs.writeScriptBin "sudo-helper" ''
      #!/usr/bin/env bash
      set -euo pipefail

      # Colors for user-friendly output
      readonly GREEN='\033[1;32m'
      readonly YELLOW='\033[1;33m'
      readonly RED='\033[1;31m'
      readonly BLUE='\033[1;34m'
      readonly DIM='\033[2m'
      readonly NC='\033[0m'

      # Configuration
      readonly PLATFORM="${platform}"
      readonly SSH_FORWARDING=${if sshForwarding then "true" else "false"}
      readonly SUDO_TIMEOUT_MINUTES=60

      # State management
      SUDO_ACQUIRED=false
      SUDO_PID=""
      CLEANUP_REGISTERED=false

      # Logging functions
      log_info() {
          echo -e "''${DIM}  $1''${NC}" >&2
      }

      log_step() {
          echo -e "''${YELLOW}▶ $1''${NC}" >&2
      }

      log_success() {
          echo -e "''${GREEN}✓ $1''${NC}" >&2
      }

      log_error() {
          echo -e "''${RED}✗ $1''${NC}" >&2
      }

      log_warning() {
          echo -e "''${YELLOW}⚠ $1''${NC}" >&2
      }

      # Check if we already have root privileges
      check_current_privileges() {
          if [ "$(id -u)" -eq 0 ]; then
              log_info "Already running with administrator privileges"
              return 0
          else
              return 1
          fi
      }

      # Check if sudo is available and configured
      check_sudo_availability() {
          if ! command -v sudo >/dev/null 2>&1; then
              log_error "sudo command not found. Please install sudo or run as root."
              return 1
          fi

          # Test if sudo is configured (without actually elevating)
          if ! sudo -n true 2>/dev/null; then
              log_info "sudo access available (password required)"
          else
              log_info "sudo access available (passwordless)"
          fi
          return 0
      }

      # Explain why sudo is needed for this operation
      explain_sudo_requirement() {
          echo ""
          echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
          echo -e "''${BLUE}  Administrator Privileges Required''${NC}"
          echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
          echo ""
          echo -e "''${YELLOW}Why are administrator privileges needed?''${NC}"
          echo ""
          
          case "''${PLATFORM}" in
              *"darwin"*)
                  echo "• System configuration changes require elevated privileges"
                  echo "• Darwin rebuild needs to modify system-level settings"
                  echo "• Nix store operations may need root access"
                  ;;
              *"linux"*)
                  echo "• NixOS rebuild requires root to modify system configuration"
                  echo "• System service management needs elevated privileges"
                  echo "• Bootloader updates require root access"
                  ${if sshForwarding then ''
                  echo "• SSH key forwarding for private repository access"
                  '' else ""}
                  ;;
              *)
                  echo "• System configuration changes require elevated privileges"
                  ;;
          esac
          
          echo ""
          echo -e "''${DIM}This will:''${NC}"
          echo -e "''${DIM}  1. Request your password once at the beginning''${NC}"
          echo -e "''${DIM}  2. Keep privileges active for the entire operation''${NC}"
          echo -e "''${DIM}  3. Automatically clean up when finished''${NC}"
          echo ""
          echo -e "''${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
          echo ""
      }

      # Register cleanup handlers
      register_cleanup() {
          if [ "''${CLEANUP_REGISTERED}" = "true" ]; then
              return 0
          fi
          
          trap 'cleanup_sudo_session' EXIT INT TERM
          CLEANUP_REGISTERED=true
          log_info "Cleanup handlers registered"
      }

      # Clean up sudo session
      cleanup_sudo_session() {
          if [ "''${SUDO_ACQUIRED}" = "true" ]; then
              log_step "Cleaning up administrator privileges"
              
              # Kill background sudo process if it exists
              if [ -n "''${SUDO_PID}" ] && kill -0 "''${SUDO_PID}" 2>/dev/null; then
                  kill "''${SUDO_PID}" 2>/dev/null || true
              fi
              
              # Reset sudo timestamp
              sudo -k 2>/dev/null || true
              
              log_success "Administrator privileges cleaned up"
              SUDO_ACQUIRED=false
              SUDO_PID=""
          fi
      }

      # Acquire sudo privileges early and keep them alive
      acquire_sudo_early() {
          # Skip if already root
          if check_current_privileges; then
              return 0
          fi

          # Check sudo availability
          if ! check_sudo_availability; then
              return 1
          fi

          # Explain why we need sudo
          explain_sudo_requirement

          # Register cleanup handlers
          register_cleanup

          log_step "Requesting administrator privileges"
          
          # Request sudo access
          if ! sudo -v; then
              log_error "Failed to acquire administrator privileges"
              log_error "Please check your sudo configuration or contact your system administrator"
              return 1
          fi

          log_success "Administrator privileges acquired"

          # Keep sudo alive in background
          log_info "Keeping privileges active during operation..."
          (
              while true; do
                  sleep 30
                  sudo -n true 2>/dev/null || exit 1
              done
          ) &
          SUDO_PID=$!

          SUDO_ACQUIRED=true
          log_success "Privilege session established (valid for ''${SUDO_TIMEOUT_MINUTES} minutes)"
          return 0
      }

      # Execute command with appropriate privileges
      execute_with_sudo() {
          local cmd="$*"
          
          if [ -z "''${cmd}" ]; then
              log_error "No command provided to execute_with_sudo"
              return 1
          fi

          if check_current_privileges; then
              # Already root, execute directly
              eval "''${cmd}"
          elif [ "''${SUDO_ACQUIRED}" = "true" ]; then
              # Sudo acquired, use it with environment preservation
              local sudo_cmd="sudo"
              
              # Add environment variable preservation
              ${pkgs.lib.concatMapStrings (var: ''
              sudo_cmd="''${sudo_cmd} -E"
              '') environmentVars}
              
              # Add SSH forwarding if needed
              ${if sshForwarding then ''
              if [ -n "''${SSH_AUTH_SOCK:-}" ]; then
                  sudo_cmd="''${sudo_cmd} SSH_AUTH_SOCK=''${SSH_AUTH_SOCK}"
              fi
              '' else ""}
              
              eval "''${sudo_cmd} ''${cmd}"
          else
              log_error "Administrator privileges not acquired. Call acquire_sudo_early first."
              return 1
          fi
      }

      # Validate that sudo session is still active
      validate_sudo_session() {
          if check_current_privileges; then
              return 0
          fi

          if [ "''${SUDO_ACQUIRED}" = "true" ]; then
              if sudo -n true 2>/dev/null; then
                  return 0
              else
                  log_warning "Administrator privileges expired"
                  SUDO_ACQUIRED=false
                  return 1
              fi
          else
              log_warning "Administrator privileges not acquired"
              return 1
          fi
      }

      # Get the appropriate sudo command prefix for platform
      get_sudo_prefix() {
          if check_current_privileges; then
              echo ""
              return 0
          fi

          local prefix="sudo"
          
          # Add environment preservation
          ${pkgs.lib.concatMapStrings (var: ''
          prefix="''${prefix} -E"
          '') environmentVars}
          
          # Add SSH forwarding for Linux
          ${if sshForwarding then ''
          if [ -n "''${SSH_AUTH_SOCK:-}" ]; then
              prefix="''${prefix} SSH_AUTH_SOCK=''${SSH_AUTH_SOCK}"
          fi
          '' else ""}
          
          echo "''${prefix}"
      }

      # Main function dispatcher
      main() {
          case "''${1:-help}" in
              "check")
                  check_current_privileges
                  ;;
              "acquire")
                  acquire_sudo_early
                  ;;
              "execute")
                  shift
                  execute_with_sudo "$@"
                  ;;
              "validate")
                  validate_sudo_session
                  ;;
              "cleanup")
                  cleanup_sudo_session
                  ;;
              "prefix")
                  get_sudo_prefix
                  ;;
              "help"|*)
                  echo "Usage: $0 {check|acquire|execute|validate|cleanup|prefix|help}"
                  echo ""
                  echo "Commands:"
                  echo "  check     - Check if already running as root"
                  echo "  acquire   - Acquire sudo privileges early with explanation"
                  echo "  execute   - Execute command with appropriate privileges"
                  echo "  validate  - Check if sudo session is still active"
                  echo "  cleanup   - Clean up sudo session"
                  echo "  prefix    - Get sudo command prefix for current platform"
                  echo "  help      - Show this help message"
                  ;;
          esac
      }

      # Run main function
      main "$@"
    '';

  # Darwin-specific sudo helper
  mkDarwinSudoHelper = mkSudoHelper {
    platform = system;
    environmentVars = [ "USER" ];
    sshForwarding = false;
  };

  # Linux-specific sudo helper  
  mkLinuxSudoHelper = mkSudoHelper {
    platform = system;
    environmentVars = [ "USER" ];
    sshForwarding = true;
  };

in
{
  # Export helper builders
  inherit mkSudoHelper mkDarwinSudoHelper mkLinuxSudoHelper;
  
  # Platform-specific helpers
  sudoHelper = 
    if pkgs.stdenv.isDarwin 
    then mkDarwinSudoHelper
    else mkLinuxSudoHelper;
}