# T026: Backup cleaner for /config/clean contract
# Provides backup file cleanup functionality enforcing no-backup policy

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.claude-code;
  
  # Cleanup utilities
  cleanupUtils = {
    # Find backup files in specified directory
    findBackupFiles = ''
      find_backup_files() {
        local search_dir="$1"
        local pattern="''${2:-.*\\.(backup|bak|orig|old|tmp)$}"
        
        [[ -d "$search_dir" ]] || { echo "Error: Directory does not exist: $search_dir" >&2; return 1; }
        
        # Find backup files using multiple patterns
        local backup_patterns=(
          "*.backup"
          "*.bak"
          "*.orig"
          "*.old"
          "*.tmp"
          "*~"
          "*.swp"
          "*.swo"
          ".#*"
          "#*#"
        )
        
        local found_files=()
        for pattern in "''${backup_patterns[@]}"; do
          while IFS= read -r -d '' file; do
            found_files+=("$file")
          done < <(find "$search_dir" -name "$pattern" -type f -print0 2>/dev/null)
        done
        
        # Remove duplicates and sort
        if [[ ''${#found_files[@]} -gt 0 ]]; then
          printf '%s\n' "''${found_files[@]}" | sort -u
        fi
      }
    '';
    
    # Analyze backup files before deletion
    analyzeBackupFiles = ''
      analyze_backup_files() {
        local search_dir="$1"
        local backup_files
        
        echo "Analyzing backup files in: $search_dir"
        
        readarray -t backup_files < <(find_backup_files "$search_dir")
        
        if [[ ''${#backup_files[@]} -eq 0 ]]; then
          echo "No backup files found"
          return 0
        fi
        
        echo "Found ''${#backup_files[@]} backup files:"
        
        local total_size=0
        local oldest_file=""
        local newest_file=""
        local oldest_time=9999999999
        local newest_time=0
        
        for file in "''${backup_files[@]}"; do
          if [[ -f "$file" ]]; then
            local size
            local mtime
            
            size=$(stat -c %s "$file" 2>/dev/null || echo "0")
            mtime=$(stat -c %Y "$file" 2>/dev/null || echo "0")
            
            total_size=$((total_size + size))
            
            if [[ $mtime -lt $oldest_time ]]; then
              oldest_time=$mtime
              oldest_file="$file"
            fi
            
            if [[ $mtime -gt $newest_time ]]; then
              newest_time=$mtime
              newest_file="$file"
            fi
            
            local readable_size
            readable_size=$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "''${size}B")
            local readable_time
            readable_time=$(date -d "@$mtime" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown")
            
            echo "  $file ($readable_size, modified: $readable_time)"
          fi
        done
        
        echo ""
        echo "Summary:"
        echo "  Total files: ''${#backup_files[@]}"
        echo "  Total size: $(numfmt --to=iec --suffix=B "$total_size" 2>/dev/null || echo "''${total_size}B")"
        
        if [[ -n "$oldest_file" ]]; then
          echo "  Oldest: $oldest_file ($(date -d "@$oldest_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown"))"
        fi
        
        if [[ -n "$newest_file" ]]; then
          echo "  Newest: $newest_file ($(date -d "@$newest_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "unknown"))"
        fi
      }
    '';
    
    # Clean backup files with safety checks
    cleanBackupFiles = ''
      clean_backup_files() {
        local search_dir="$1"
        local dry_run="''${2:-false}"
        local force="''${3:-false}"
        local backup_files
        local cleaned_count=0
        local failed_count=0
        local total_size_freed=0
        
        echo "Cleaning backup files in: $search_dir"
        echo "Dry run: $dry_run"
        echo "Force: $force"
        echo ""
        
        readarray -t backup_files < <(find_backup_files "$search_dir")
        
        if [[ ''${#backup_files[@]} -eq 0 ]]; then
          echo "No backup files found to clean"
          return 0
        fi
        
        echo "Processing ''${#backup_files[@]} backup files..."
        
        # Safety confirmation for non-force mode
        if [[ "$force" != "true" && "$dry_run" != "true" ]]; then
          echo "This will permanently delete ''${#backup_files[@]} backup files."
          echo "This action cannot be undone."
          echo ""
          read -p "Continue? (y/N): " -r confirmation
          
          case "$confirmation" in
            [Yy]|[Yy][Ee][Ss])
              echo "Proceeding with cleanup..."
              ;;
            *)
              echo "Cleanup cancelled by user"
              return 1
              ;;
          esac
        fi
        
        # Process each backup file
        for file in "''${backup_files[@]}"; do
          if [[ -f "$file" ]]; then
            local file_size
            file_size=$(stat -c %s "$file" 2>/dev/null || echo "0")
            
            if [[ "$dry_run" == "true" ]]; then
              echo "DRY RUN: Would delete $file ($(numfmt --to=iec --suffix=B "$file_size" 2>/dev/null || echo "''${file_size}B"))"
              ((cleaned_count++))
              total_size_freed=$((total_size_freed + file_size))
            else
              if rm -f "$file" 2>/dev/null; then
                echo "Deleted: $file ($(numfmt --to=iec --suffix=B "$file_size" 2>/dev/null || echo "''${file_size}B"))"
                ((cleaned_count++))
                total_size_freed=$((total_size_freed + file_size))
              else
                echo "Failed to delete: $file"
                ((failed_count++))
              fi
            fi
          else
            echo "Skipping non-file: $file"
          fi
        done
        
        echo ""
        echo "Cleanup summary:"
        echo "  Files processed: ''${#backup_files[@]}"
        echo "  Files cleaned: $cleaned_count"
        echo "  Failures: $failed_count"
        echo "  Space freed: $(numfmt --to=iec --suffix=B "$total_size_freed" 2>/dev/null || echo "''${total_size_freed}B")"
        
        if [[ "$dry_run" == "true" ]]; then
          echo "  (Dry run - no files were actually deleted)"
        fi
        
        return $failed_count
      }
    '';
    
    # Comprehensive system cleanup
    cleanupSystem = ''
      cleanup_system() {
        local dry_run="''${1:-false}"
        local force="''${2:-false}"
        
        echo "=== Claude Code System Cleanup ==="
        echo "Dry run: $dry_run"
        echo "Force: $force"
        echo ""
        
        local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
        local total_failures=0
        
        # Clean Claude Code config directory
        if [[ -d "$config_dir" ]]; then
          echo "Cleaning Claude Code configuration directory..."
          if ! clean_backup_files "$config_dir" "$dry_run" "$force"; then
            ((total_failures++))
          fi
          echo ""
        else
          echo "Claude Code configuration directory not found: $config_dir"
          echo ""
        fi
        
        # Clean temporary directories
        local temp_dirs=(
          "/tmp"
          "''${TMPDIR:-/tmp}"
          "${config.home.homeDirectory}/.cache"
        )
        
        for temp_dir in "''${temp_dirs[@]}"; do
          if [[ -d "$temp_dir" ]]; then
            echo "Cleaning backup files in $temp_dir..."
            
            # Only clean files related to Claude Code
            local claude_backup_files
            readarray -t claude_backup_files < <(find "$temp_dir" -maxdepth 2 -name "*claude*" -name "*.backup" -o -name "*claude*" -name "*.bak" 2>/dev/null || true)
            
            if [[ ''${#claude_backup_files[@]} -gt 0 ]]; then
              for file in "''${claude_backup_files[@]}"; do
                if [[ "$dry_run" == "true" ]]; then
                  echo "DRY RUN: Would delete $file"
                else
                  if rm -f "$file" 2>/dev/null; then
                    echo "Deleted: $file"
                  else
                    echo "Failed to delete: $file"
                    ((total_failures++))
                  fi
                fi
              done
            else
              echo "No Claude Code backup files found in $temp_dir"
            fi
            echo ""
          fi
        done
        
        # Clean old log files
        local log_dirs=(
          "${config.home.homeDirectory}/.local/share/claude-code"
          "${config.home.homeDirectory}/.cache/claude-code"
        )
        
        for log_dir in "''${log_dirs[@]}"; do
          if [[ -d "$log_dir" ]]; then
            echo "Cleaning old log files in $log_dir..."
            
            # Clean log files older than 30 days
            local old_logs
            readarray -t old_logs < <(find "$log_dir" -name "*.log" -type f -mtime +30 2>/dev/null || true)
            
            if [[ ''${#old_logs[@]} -gt 0 ]]; then
              for log_file in "''${old_logs[@]}"; do
                if [[ "$dry_run" == "true" ]]; then
                  echo "DRY RUN: Would delete old log $log_file"
                else
                  if rm -f "$log_file" 2>/dev/null; then
                    echo "Deleted old log: $log_file"
                  else
                    echo "Failed to delete log: $log_file"
                    ((total_failures++))
                  fi
                fi
              done
            else
              echo "No old log files found"
            fi
            echo ""
          fi
        done
        
        echo "=== System Cleanup Complete ==="
        echo "Total failures: $total_failures"
        
        return $total_failures
      }
    '';
    
    # Validate cleanup operation
    validateCleanup = ''
      validate_cleanup() {
        local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
        
        echo "Validating cleanup operation..."
        
        # Check if backup files still exist
        local remaining_backups
        readarray -t remaining_backups < <(find_backup_files "$config_dir" 2>/dev/null || true)
        
        if [[ ''${#remaining_backups[@]} -eq 0 ]]; then
          echo "✓ No backup files found - cleanup successful"
          return 0
        else
          echo "✗ Backup files still present after cleanup:"
          printf '  %s\n' "''${remaining_backups[@]}"
          return 1
        fi
      }
    '';
  };
  
  # Cleanup script implementing the contract
  cleanupScript = pkgs.writeShellScript "claude-code-clean" ''
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Source cleanup utilities
    ${cleanupUtils.findBackupFiles}
    ${cleanupUtils.analyzeBackupFiles}
    ${cleanupUtils.cleanBackupFiles}
    ${cleanupUtils.cleanupSystem}
    ${cleanupUtils.validateCleanup}
    
    # Main cleanup function (implements DELETE /config/clean)
    clean_claude_code_backups() {
      local dry_run="''${1:-false}"
      local force="''${2:-false}"
      local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
      
      # Check if config directory exists
      if [[ ! -d "$config_dir" ]]; then
        echo "Configuration directory not found: $config_dir"
        echo "Nothing to clean"
        return 0
      fi
      
      # Execute cleanup
      clean_backup_files "$config_dir" "$dry_run" "$force"
    }
    
    # Quick backup check
    check_backups() {
      local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
      
      if [[ ! -d "$config_dir" ]]; then
        echo "false"
        return 0
      fi
      
      local backup_files
      readarray -t backup_files < <(find_backup_files "$config_dir" 2>/dev/null || true)
      
      if [[ ''${#backup_files[@]} -gt 0 ]]; then
        echo "true"
        return 0
      else
        echo "false"
        return 0
      fi
    }
    
    # Command line interface
    main() {
      local action="''${1:-clean}"
      local dry_run="''${2:-false}"
      local force="''${3:-false}"
      
      case "$action" in
        clean)
          clean_claude_code_backups "$dry_run" "$force"
          ;;
        analyze)
          local config_dir="${config.home.homeDirectory}/${cfg.configDirectory}"
          analyze_backup_files "$config_dir"
          ;;
        check)
          check_backups
          ;;
        system)
          cleanup_system "$dry_run" "$force"
          ;;
        validate)
          validate_cleanup
          ;;
        help)
          cat <<EOF
Claude Code Backup Cleaner

Usage: claude-code-clean [action] [dry_run] [force]

Actions:
  clean      Clean backup files in Claude Code directory (default)
  analyze    Analyze backup files without cleaning
  check      Check if backup files exist (true/false)
  system     Comprehensive system cleanup
  validate   Validate that cleanup was successful
  help       Show this help message

Parameters:
  dry_run    Show what would be deleted without actually deleting (true/false)
  force      Skip confirmation prompts (true/false)

Examples:
  claude-code-clean
  claude-code-clean clean true false
  claude-code-clean analyze
  claude-code-clean system false true
  claude-code-clean validate

Note: This tool enforces the no-backup policy by removing backup files.
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

in {
  # Configuration options specific to cleanup
  options.programs.claude-code.cleanup = {
    enableAutoCleanup = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically clean backup files during deployment";
    };
    
    cleanupSchedule = mkOption {
      type = types.str;
      default = "daily";
      description = "Schedule for automatic cleanup (systemd timer format)";
    };
    
    enableCleanupNotifications = mkOption {
      type = types.bool;
      default = false;
      description = "Send notifications when cleanup occurs";
    };
    
    cleanupRetentionDays = mkOption {
      type = types.int;
      default = 0;
      description = "Days to retain backup files (0 = immediate deletion)";
    };
    
    safetyChecksEnabled = mkOption {
      type = types.bool;
      default = true;
      description = "Enable safety checks before cleanup";
    };
    
    cleanupLogFile = mkOption {
      type = types.str;
      default = "~/.local/share/claude-code/cleanup.log";
      description = "Path to cleanup log file";
    };
  };
  
  # Configuration implementation
  config = mkIf cfg.enable {
    # Add cleanup script to user packages
    home.packages = [ cleanupScript ];
    
    # Shell aliases for cleanup operations
    home.shellAliases = {
      claude-clean = "claude-code-clean clean";
      claude-clean-dry = "claude-code-clean clean true false";
      claude-clean-force = "claude-code-clean clean false true";
      claude-analyze-backups = "claude-code-clean analyze";
      claude-check-backups = "claude-code-clean check";
    };
    
    # Environment variables for cleanup
    home.sessionVariables = {
      CLAUDE_CODE_CLEANUP_SCRIPT = "${cleanupScript}";
      CLAUDE_CODE_AUTO_CLEANUP = if cfg.cleanup.enableAutoCleanup then "true" else "false";
    };
    
    # Automatic cleanup via systemd timer
    systemd.user = mkIf cfg.cleanup.enableAutoCleanup {
      services.claude-code-cleanup = {
        Unit = {
          Description = "Claude Code Backup Cleanup";
          After = [ "graphical-session.target" ];
        };
        
        Service = {
          Type = "oneshot";
          ExecStart = "${cleanupScript} system false true";
          StandardOutput = "journal";
          StandardError = "journal";
        };
        
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
      
      timers.claude-code-cleanup = {
        Unit = {
          Description = "Claude Code Cleanup Timer";
          Requires = [ "claude-code-cleanup.service" ];
        };
        
        Timer = {
          OnCalendar = cfg.cleanup.cleanupSchedule;
          Persistent = true;
        };
        
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };
    
    # Cleanup log directory
    home.file.".local/share/claude-code/.keep-cleanup" = {
      text = "# Directory for Claude Code cleanup logs";
    };
    
    # Pre-commit hook for backup file detection
    home.file.".git/hooks/pre-commit-backup-check" = mkIf cfg.cleanup.safetyChecksEnabled {
      text = ''
        #!/usr/bin/env bash
        # Pre-commit hook to detect backup files
        set -euo pipefail
        
        echo "Checking for backup files..."
        
        if backup_files=$(${cleanupScript} check) && [[ "$backup_files" == "true" ]]; then
          echo "Error: Backup files detected in repository"
          echo "Please run 'claude-clean' to remove them before committing"
          ${cleanupScript} analyze
          exit 1
        fi
        
        echo "No backup files found"
      '';
      executable = true;
    };
    
    # Cleanup assertions
    assertions = [
      {
        assertion = cfg.cleanup.cleanupRetentionDays >= 0;
        message = "Cleanup retention days must be 0 or greater";
      }
      {
        assertion = !(cfg.enableBackups && cfg.cleanup.enableAutoCleanup);
        message = "Cannot enable both backup creation and auto cleanup";
      }
    ];
    
    # Warnings
    warnings = 
      optional (cfg.cleanup.cleanupRetentionDays > 0)
        "Backup retention is enabled but conflicts with the no-backup policy" ++
      optional (!cfg.cleanup.enableAutoCleanup)
        "Auto cleanup is disabled - backup files may accumulate";
  };
  
  # Export cleanup utilities
  meta = {
    inherit cleanupUtils cleanupScript;
    
    # Contract compliance functions
    contractFunctions = {
      # DELETE /config/clean implementation
      cleanBackups = dry_run: force: ''
        ${cleanupScript} clean "${if dry_run then "true" else "false"}" "${if force then "true" else "false"}"
      '';
      
      # Check if backups exist
      checkBackups = ''
        ${cleanupScript} check
      '';
      
      # Analyze backup files
      analyzeBackups = ''
        ${cleanupScript} analyze
      '';
      
      # System-wide cleanup
      systemCleanup = dry_run: force: ''
        ${cleanupScript} system "${if dry_run then "true" else "false"}" "${if force then "true" else "false"}"
      '';
    };
  };
}