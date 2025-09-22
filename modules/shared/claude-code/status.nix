# T025: Config status checker for /config/status contract
# Provides Claude Code configuration status monitoring and validation

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-code;

  # Status checking utilities
  statusUtils = {
    # Check if Claude Code is configured
    checkConfigured = ''
      check_configured() {
        local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"

        # Check if config directory exists
        [[ -d "$config_dir" ]] || return 1

        # Check if essential symlinks exist
        local essential_paths=(
          "$config_dir/commands"
          "$config_dir/agents"
          "$config_dir/CLAUDE.md"
        )

        for path in "''${essential_paths[@]}"; do
          [[ -e "$path" ]] || return 1
        done

        return 0
      }
    '';

    # Analyze symlink status
    analyzeSymlinks = ''
            analyze_symlinks() {
              local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
              local symlinks_json="[]"

              # Define expected symlinks
              declare -A expected_symlinks=(
                ["commands"]="$config_dir/commands"
                ["agents"]="$config_dir/agents"
                ["constitution"]="$config_dir/commands/constitution.md"
                ["claude_md"]="$config_dir/CLAUDE.md"
              )

              # Check each symlink
              local symlink_objects=()
              for name in "''${!expected_symlinks[@]}"; do
                local path="''${expected_symlinks[$name]}"
                local exists="false"
                local is_symlink="false"
                local target=""
                local valid="false"

                # Check if path exists
                if [[ -e "$path" || -L "$path" ]]; then
                  exists="true"

                  # Check if it's a symlink
                  if [[ -L "$path" ]]; then
                    is_symlink="true"
                    target="$(readlink "$path")"

                    # Check if symlink is valid (target exists)
                    if [[ -e "$path" ]]; then
                      valid="true"
                    fi
                  elif [[ -f "$path" || -d "$path" ]]; then
                    # Regular file or directory (not symlink)
                    is_symlink="false"
                    valid="true"
                  fi
                fi

                # Create symlink status object
                local symlink_obj
                symlink_obj=$(cat <<SYMLINK_JSON
      {
        "path": "$path",
        "exists": $exists,
        "is_symlink": $is_symlink,
        "target": "$target",
        "valid": $valid
      }
      SYMLINK_JSON
      )
                symlink_objects+=("$symlink_obj")
              done

              # Build JSON array
              if command -v jq >/dev/null 2>&1; then
                printf '%s\n' "''${symlink_objects[@]}" | jq -s '.'
              else
                # Fallback without jq
                echo "["
                local first=true
                for obj in "''${symlink_objects[@]}"; do
                  [[ "$first" == "true" ]] && first=false || echo ","
                  echo "$obj"
                done
                echo "]"
              fi
            }
    '';

    # Check for backup files
    checkBackups = ''
      check_backups() {
        local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"

        [[ -d "$config_dir" ]] || { echo "false"; return 0; }

        # Look for backup files
        local backup_files
        backup_files=$(find "$config_dir" -name "*.backup" -o -name "*.bak" -o -name "*.orig" 2>/dev/null || true)

        if [[ -n "$backup_files" ]]; then
          echo "true"
        else
          echo "false"
        fi
      }
    '';

    # Detect current platform
    detectPlatform = ''
      detect_platform() {
        if [[ "$OSTYPE" == "darwin"* ]]; then
          echo "darwin"
        elif [[ -f /etc/nixos/configuration.nix ]]; then
          echo "nixos"
        else
          echo "unknown"
        fi
      }
    '';

    # Get detailed configuration status
    getDetailedStatus = ''
            get_detailed_status() {
              local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
              local configured
              local symlinks_json
              local has_backups
              local platform

              # Check if configured
              if check_configured; then
                configured="true"
              else
                configured="false"
              fi

              # Analyze symlinks
              symlinks_json="$(analyze_symlinks)"

              # Check for backups
              has_backups="$(check_backups)"

              # Detect platform
              platform="$(detect_platform)"

              # Additional status information
              local config_exists="false"
              local last_modified=""
              local nix_managed="false"

              [[ -d "$config_dir" ]] && config_exists="true"

              if [[ -d "$config_dir" ]]; then
                last_modified="$(stat -c %Y "$config_dir" 2>/dev/null || echo "0")"
                last_modified="$(date -d "@$last_modified" -Iseconds 2>/dev/null || echo "unknown")"
              fi

              [[ -n "''${CLAUDE_CODE_NIX_MANAGED:-}" ]] && nix_managed="true"

              # Generate status report per contract
              cat <<STATUS_JSON
      {
        "configured": $configured,
        "symlinks": $symlinks_json,
        "has_backups": $has_backups,
        "platform": "$platform",
        "details": {
          "config_directory": "$config_dir",
          "config_exists": $config_exists,
          "last_modified": "$last_modified",
          "nix_managed": $nix_managed,
          "force_overwrite_enabled": ${if cfg.forceOverwrite then "true" else "false"},
          "backup_policy_enabled": ${if cfg.enableBackups then "true" else "false"}
        }
      }
      STATUS_JSON
            }
    '';

    # Validate configuration integrity
    validateIntegrity = ''
      validate_integrity() {
        local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
        local issues=()
        local warnings=()

        echo "Validating Claude Code configuration integrity..."

        # Check if config directory exists
        if [[ ! -d "$config_dir" ]]; then
          issues+=("Configuration directory does not exist: $config_dir")
          echo "CRITICAL: Configuration directory missing"
          return 1
        fi

        # Check essential symlinks
        declare -A essential_symlinks=(
          ["commands"]="$config_dir/commands"
          ["agents"]="$config_dir/agents"
          ["claude_md"]="$config_dir/CLAUDE.md"
        )

        for name in "''${!essential_symlinks[@]}"; do
          local path="''${essential_symlinks[$name]}"

          if [[ ! -e "$path" ]]; then
            issues+=("Essential path missing: $path")
          elif [[ -L "$path" ]]; then
            # Check symlink validity
            if [[ ! -e "$(readlink "$path")" ]]; then
              issues+=("Broken symlink: $path -> $(readlink "$path")")
            fi
          fi
        done

        # Check for backup files (should not exist per policy)
        local backup_files
        backup_files=$(find "$config_dir" -name "*.backup" -o -name "*.bak" -o -name "*.orig" 2>/dev/null || true)
        if [[ -n "$backup_files" ]]; then
          warnings+=("Backup files found (violates no-backup policy): $backup_files")
        fi

        # Check for conflicting configurations
        if [[ -f "$config_dir/.home-manager-managed" && -z "''${CLAUDE_CODE_NIX_MANAGED:-}" ]]; then
          warnings+=("Configuration appears to be Home Manager managed but NIX_MANAGED flag is not set")
        fi

        # Report results
        if [[ ''${#issues[@]} -eq 0 ]]; then
          echo "Configuration integrity: PASS"

          if [[ ''${#warnings[@]} -gt 0 ]]; then
            echo "Warnings:"
            printf '  - %s\n' "''${warnings[@]}"
          fi

          return 0
        else
          echo "Configuration integrity: FAIL"
          echo "Issues found:"
          printf '  - %s\n' "''${issues[@]}"

          if [[ ''${#warnings[@]} -gt 0 ]]; then
            echo "Warnings:"
            printf '  - %s\n' "''${warnings[@]}"
          fi

          return 1
        fi
      }
    '';

    # Monitor configuration changes
    monitorChanges = ''
      monitor_changes() {
        local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
        local watch_duration="''${1:-60}"  # seconds

        echo "Monitoring Claude Code configuration for $watch_duration seconds..."

        if ! command -v inotifywait >/dev/null 2>&1; then
          echo "Warning: inotifywait not available, using polling method"

          # Polling fallback
          local initial_state
          initial_state="$(find "$config_dir" -type l -exec readlink {} \; 2>/dev/null | sort)"

          sleep "$watch_duration"

          local final_state
          final_state="$(find "$config_dir" -type l -exec readlink {} \; 2>/dev/null | sort)"

          if [[ "$initial_state" != "$final_state" ]]; then
            echo "Changes detected in configuration"
            echo "Initial state hash: $(echo "$initial_state" | md5sum | cut -d' ' -f1)"
            echo "Final state hash: $(echo "$final_state" | md5sum | cut -d' ' -f1)"
          else
            echo "No changes detected"
          fi
        else
          # Use inotifywait for real-time monitoring
          echo "Using inotifywait for real-time monitoring..."

          if timeout "$watch_duration" inotifywait -r -e modify,create,delete,move "$config_dir" 2>/dev/null; then
            echo "Changes detected in configuration directory"
          else
            echo "No changes detected during monitoring period"
          fi
        fi
      }
    '';
  };

  # Status checking script
  statusScript = pkgs.writeShellScript "claude-code-status" ''
        #!/usr/bin/env bash
        set -euo pipefail

        # Source status utilities
        ${statusUtils.checkConfigured}
        ${statusUtils.analyzeSymlinks}
        ${statusUtils.checkBackups}
        ${statusUtils.detectPlatform}
        ${statusUtils.getDetailedStatus}
        ${statusUtils.validateIntegrity}
        ${statusUtils.monitorChanges}

        # Main status function (implements GET /config/status)
        get_claude_code_status() {
          get_detailed_status
        }

        # Quick status check
        quick_status() {
          if check_configured; then
            echo "Claude Code: CONFIGURED"
            return 0
          else
            echo "Claude Code: NOT CONFIGURED"
            return 1
          fi
        }

        # Health check function
        health_check() {
          echo "=== Claude Code Health Check ==="

          # Basic configuration check
          if check_configured; then
            echo "✓ Configuration: OK"
          else
            echo "✗ Configuration: MISSING"
            return 1
          fi

          # Symlink validation
          local symlinks_json
          symlinks_json="$(analyze_symlinks)"
          local broken_symlinks
          broken_symlinks="$(echo "$symlinks_json" | jq -r '.[] | select(.is_symlink == true and .valid == false) | .path' 2>/dev/null || true)"

          if [[ -z "$broken_symlinks" ]]; then
            echo "✓ Symlinks: OK"
          else
            echo "✗ Symlinks: BROKEN"
            echo "  Broken symlinks: $broken_symlinks"
            return 1
          fi

          # Backup policy check
          local has_backups
          has_backups="$(check_backups)"
          if [[ "$has_backups" == "false" ]]; then
            echo "✓ Backup Policy: OK (no backup files found)"
          else
            echo "⚠ Backup Policy: WARNING (backup files found)"
          fi

          # Platform detection
          local platform
          platform="$(detect_platform)"
          echo "✓ Platform: $platform"

          echo "Health check completed"
          return 0
        }

        # Command line interface
        main() {
          local action="''${1:-status}"

          case "$action" in
            status)
              get_claude_code_status
              ;;
            quick)
              quick_status
              ;;
            health)
              health_check
              ;;
            validate)
              validate_integrity
              ;;
            monitor)
              local duration="''${2:-60}"
              monitor_changes "$duration"
              ;;
            platform)
              detect_platform
              ;;
            configured)
              if check_configured; then
                echo "true"
              else
                echo "false"
              fi
              ;;
            backups)
              check_backups
              ;;
            help)
              cat <<EOF
    Claude Code Status Checker

    Usage: claude-code-status [action] [options]

    Actions:
      status      Get detailed configuration status (default)
      quick       Quick configuration check
      health      Comprehensive health check
      validate    Validate configuration integrity
      monitor     Monitor configuration changes [duration_seconds]
      platform    Detect current platform
      configured  Check if Claude Code is configured (true/false)
      backups     Check if backup files exist (true/false)
      help        Show this help message

    Examples:
      claude-code-status
      claude-code-status health
      claude-code-status monitor 120
      claude-code-status validate
    EOF
              ;;
            *)
              echo "Error: Unknown action '$action'. Use 'help' for usage information." >&2
              return 1
              ;;
          esac
        }

        # Execute main function if script is run directly
        if [[ "''${BASH_SOURCE[0]}" == "''${0}" ]]; then
          main "$@"
        fi
  '';

in
{
  # Configuration options specific to status checking
  options.programs.claude-code.status = {
    enablePeriodicChecks = mkOption {
      type = types.bool;
      default = true;
      description = "Enable periodic configuration status checks";
    };

    checkInterval = mkOption {
      type = types.str;
      default = "1h";
      description = "Interval for periodic status checks (systemd timer format)";
    };

    enableHealthAlerts = mkOption {
      type = types.bool;
      default = false;
      description = "Enable health check alerts on failures";
    };

    alertCommand = mkOption {
      type = types.str;
      default = "echo";
      description = "Command to execute for health alerts";
    };

    logStatusChecks = mkOption {
      type = types.bool;
      default = true;
      description = "Log status check results";
    };

    statusLogFile = mkOption {
      type = types.str;
      default = "~/.local/share/claude-code/status.log";
      description = "Path to status log file";
    };
  };

  # Configuration implementation
  config = mkIf cfg.enable {
    # Add status script to user packages
    home.packages = [ statusScript ];

    # Shell aliases for status checking
    home.shellAliases = {
      claude-status = "claude-code-status status";
      claude-health = "claude-code-status health";
      claude-quick = "claude-code-status quick";
      claude-validate = "claude-code-status validate";
    };

    # Environment variables for status checking
    home.sessionVariables = {
      CLAUDE_CODE_STATUS_SCRIPT = "${statusScript}";
    };

    # Periodic status checks via systemd timer
    systemd.user = mkIf cfg.status.enablePeriodicChecks {
      services.claude-code-status-check = {
        Unit = {
          Description = "Claude Code Configuration Status Check";
          After = [ "graphical-session.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${statusScript} health";
          StandardOutput = "journal";
          StandardError = "journal";
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

      timers.claude-code-status-check = {
        Unit = {
          Description = "Claude Code Status Check Timer";
          Requires = [ "claude-code-status-check.service" ];
        };

        Timer = {
          OnCalendar = cfg.status.checkInterval;
          Persistent = true;
        };

        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };

    # Status log directory
    home.file = mkIf cfg.status.logStatusChecks {
      ".local/share/claude-code/.keep" = {
        text = "# Directory for Claude Code status logs";
      };
    };

    # XDG desktop entry for status checking
    xdg.desktopEntries = mkIf cfg.status.enableHealthAlerts {
      claude-code-status = {
        name = "Claude Code Status";
        comment = "Check Claude Code configuration status";
        exec = "${statusScript} health";
        icon = "dialog-information";
        type = "Application";
        categories = [ "Development" "Utility" ];
      };
    };
  };

  # Export status utilities
  meta = {
    inherit statusUtils statusScript;

    # Contract compliance functions
    contractFunctions = {
      # GET /config/status implementation
      getConfigStatus = ''
        ${statusScript} status
      '';

      # Health check implementation
      healthCheck = ''
        ${statusScript} health
      '';

      # Quick status check
      quickStatus = ''
        ${statusScript} quick
      '';

      # Configuration validation
      validateConfig = ''
        ${statusScript} validate
      '';
    };
  };
}
