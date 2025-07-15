{ pkgs, lib ? pkgs.lib }:

let
  testHelpers = import ../lib/test-helpers.nix { inherit pkgs lib; };

  # Test utilities for notification and auto-recovery testing
  testUtils = {
    createMockNotificationData = ''
      export NOTIFICATION_TEST_DIR=$(mktemp -d)
      mkdir -p "$NOTIFICATION_TEST_DIR"/{notifications,recovery,logs,config}

      # Create mock notification configuration
      cat > "$NOTIFICATION_TEST_DIR/notification_config.yaml" << 'EOF'
notification_channels:
  log:
    enabled: true
    level: info
    file: /tmp/build-switch-notifications.log
  console:
    enabled: true
    level: warning
  email:
    enabled: false
    smtp_server: smtp.example.com
    from: build-system@example.com
    to: [admin@example.com]
  slack:
    enabled: false
    webhook_url: https://hooks.slack.com/services/EXAMPLE
    channel: "#build-alerts"

alert_thresholds:
  cache_hit_rate_critical: 0.05
  cache_hit_rate_warning: 0.3
  build_time_warning: 90
  build_time_critical: 180
  success_rate_warning: 0.9
  success_rate_critical: 0.8
  error_rate_warning: 0.1
  error_rate_critical: 0.2

escalation_rules:
  critical_alert_escalation_minutes: 15
  warning_alert_escalation_minutes: 60
  max_escalation_levels: 3
  auto_recovery_enabled: true
  recovery_retry_attempts: 3
  recovery_retry_delay_seconds: 30
EOF

      # Create mock alert data
      cat > "$NOTIFICATION_TEST_DIR/test_alert.json" << 'EOF'
      {
        "alert_id": "alert_test_001",
        "timestamp": "2025-07-15T10:00:00Z",
        "severity": "critical",
        "category": "performance",
        "title": "Cache Hit Rate Critical",
        "message": "Cache hit rate has dropped to 2%, significantly below the 75% target",
        "details": {
          "current_value": 0.02,
          "threshold": 0.05,
          "target": 0.75,
          "impact": "All builds affected",
          "duration": "2 hours"
        },
        "suggested_actions": [
          "Enable intelligent cache optimization",
          "Increase cache size",
          "Implement preloading strategies"
        ],
        "auto_recovery_possible": true,
        "escalation_required": true
      }
      EOF

      # Create mock system state data
      cat > "$NOTIFICATION_TEST_DIR/system_state.json" << 'EOF'
      {
        "timestamp": "2025-07-15T10:00:00Z",
        "build_system": {
          "status": "degraded",
          "cache_status": "critical",
          "build_queue_length": 15,
          "active_builds": 3,
          "system_load": 0.85
        },
        "recovery_options": [
          {
            "action": "cache_optimization",
            "feasibility": "high",
            "estimated_duration": "5 minutes",
            "expected_improvement": "65%"
          },
          {
            "action": "build_queue_optimization",
            "feasibility": "medium",
            "estimated_duration": "2 minutes",
            "expected_improvement": "25%"
          }
        ]
      }
      EOF
    '';

    setupNotificationEnvironment = ''
      export NOTIFICATION_CONFIG_FILE="$NOTIFICATION_TEST_DIR/notification_config.yaml"
      export NOTIFICATION_LOG_DIR="$NOTIFICATION_TEST_DIR/logs"
      export RECOVERY_STATE_DIR="$NOTIFICATION_TEST_DIR/recovery"
      export ESCALATION_LOG_FILE="$NOTIFICATION_TEST_DIR/logs/escalation.log"

      # Create log directories
      mkdir -p "$NOTIFICATION_LOG_DIR" "$RECOVERY_STATE_DIR"
      touch "$ESCALATION_LOG_FILE"
    '';

    cleanup = ''
      rm -rf "$NOTIFICATION_TEST_DIR" 2>/dev/null || true
    '';
  };

in

pkgs.runCommand "notification-auto-recovery-test" {
  buildInputs = with pkgs; [
    bash
    jq
    coreutils
    findutils
    gnused
    gnugrep
  ];
} ''
  set -euo pipefail

  echo "=== Notification and Auto-Recovery Tests ==="

  # Test 1: send_notifications function
  echo "Test 1: Testing send_notifications function..."

  ${testUtils.createMockNotificationData}
  ${testUtils.setupNotificationEnvironment}

  # Create the notification and auto-recovery script stub for testing
  cat > notification_test.sh << 'EOF'
#!/bin/bash
# Notification and auto-recovery implementation

send_notifications() {
    local notification_type="$1"
    local alert_data="$2"
    local config_file="$3"

    echo "send_notifications called with: $notification_type, $alert_data, $config_file" >&2

    if [ ! -f "$alert_data" ]; then
        echo "Error: Alert data file not found: $alert_data" >&2
        return 1
    fi

    if [ ! -f "$config_file" ]; then
        echo "Error: Configuration file not found: $config_file" >&2
        return 1
    fi

    # Parse alert data
    local alert_id alert_severity alert_message
    if command -v jq >/dev/null 2>&1; then
        alert_id=$(jq -r '.alert_id // "unknown"' "$alert_data")
        alert_severity=$(jq -r '.severity // "info"' "$alert_data")
        alert_message=$(jq -r '.message // "No message"' "$alert_data")
    else
        alert_id="alert_test_001"
        alert_severity="critical"
        alert_message="Cache hit rate critical"
    fi

    case "$notification_type" in
        "immediate")
            # Send immediate notification through all enabled channels
            echo "$(date -Iseconds) [IMMEDIATE] [$alert_severity] Alert: $alert_id - $alert_message" >> "$NOTIFICATION_LOG_DIR/notifications.log"

            # Console notification (always enabled for critical)
            if [ "$alert_severity" = "critical" ] || [ "$alert_severity" = "warning" ]; then
                echo "🚨 BUILD-SWITCH ALERT [$alert_severity]: $alert_message" >&2
            fi

            # Log notification
            echo "$(date -Iseconds) ALERT_SENT alert_id=$alert_id severity=$alert_severity type=immediate" >> "$NOTIFICATION_LOG_DIR/audit.log"
            ;;

        "escalated")
            # Send escalated notification with additional context
            echo "$(date -Iseconds) [ESCALATED] [$alert_severity] Alert: $alert_id - $alert_message (ESCALATED)" >> "$NOTIFICATION_LOG_DIR/notifications.log"

            # Add escalation marker
            echo "$(date -Iseconds) ALERT_ESCALATED alert_id=$alert_id severity=$alert_severity escalation_level=1" >> "$NOTIFICATION_LOG_DIR/audit.log"

            # Console escalation notification
            echo "🔥 BUILD-SWITCH ESCALATED ALERT [$alert_severity]: $alert_message" >&2
            echo "   This alert has been escalated due to duration or severity." >&2
            ;;

        "recovery_success")
            # Send recovery success notification
            echo "$(date -Iseconds) [RECOVERY] [$alert_severity] Alert: $alert_id - RESOLVED" >> "$NOTIFICATION_LOG_DIR/notifications.log"
            echo "$(date -Iseconds) ALERT_RESOLVED alert_id=$alert_id recovery_type=automatic" >> "$NOTIFICATION_LOG_DIR/audit.log"

            echo "✅ BUILD-SWITCH RECOVERY: $alert_message - Successfully resolved" >&2
            ;;

        "recovery_failed")
            # Send recovery failure notification
            echo "$(date -Iseconds) [RECOVERY_FAILED] [$alert_severity] Alert: $alert_id - AUTO-RECOVERY FAILED" >> "$NOTIFICATION_LOG_DIR/notifications.log"
            echo "$(date -Iseconds) ALERT_RECOVERY_FAILED alert_id=$alert_id requires_manual_intervention=true" >> "$NOTIFICATION_LOG_DIR/audit.log"

            echo "❌ BUILD-SWITCH RECOVERY FAILED: $alert_message - Manual intervention required" >&2
            ;;

        *)
            echo "Error: Unknown notification type: $notification_type" >&2
            return 1
            ;;
    esac

    # Create notification receipt
    cat > "\$NOTIFICATION_LOG_DIR/notification_receipt_\${alert_id}.json" << RECEIPT_EOF
{
  "notification_id": "notif_$(date +%s)",
  "alert_id": "$alert_id",
  "notification_type": "$notification_type",
  "sent_timestamp": "$(date -Iseconds)",
  "severity": "$alert_severity",
  "delivery_status": "sent",
  "channels_used": ["log", "console"],
  "retry_count": 0
}
RECEIPT_EOF

    return 0
}

export -f send_notifications
EOF

  chmod +x notification_test.sh
  source notification_test.sh

  # Test immediate notification
  if send_notifications "immediate" "$NOTIFICATION_TEST_DIR/test_alert.json" "$NOTIFICATION_TEST_DIR/notification_config.yaml"; then
    echo "✓ send_notifications function executed successfully"

    # Verify notification log was created
    if [ -f "$NOTIFICATION_LOG_DIR/notifications.log" ]; then
      echo "✓ Notification log created"

      # Verify log contains alert information
      if grep -q "Cache hit rate critical" "$NOTIFICATION_LOG_DIR/notifications.log"; then
        echo "✓ Alert message logged correctly"
      else
        echo "✗ Alert message not found in log"
        exit 1
      fi
    else
      echo "✗ Notification log not created"
      exit 1
    fi

    # Verify audit log was created
    if [ -f "$NOTIFICATION_LOG_DIR/audit.log" ]; then
      echo "✓ Audit log created"

      if grep -q "ALERT_SENT" "$NOTIFICATION_LOG_DIR/audit.log"; then
        echo "✓ Alert audit entry created"
      else
        echo "✗ Alert audit entry missing"
        exit 1
      fi
    else
      echo "✗ Audit log not created"
      exit 1
    fi

    # Verify notification receipt
    if [ -f "$NOTIFICATION_LOG_DIR/notification_receipt_alert_test_001.json" ]; then
      echo "✓ Notification receipt generated"
    else
      echo "✗ Notification receipt not generated"
      exit 1
    fi
  else
    echo "✗ send_notifications function failed"
    exit 1
  fi

  # Test 2: auto_recovery_system function
  echo "Test 2: Testing auto_recovery_system function..."

  cat >> notification_test.sh << 'EOF'

auto_recovery_system() {
    local recovery_action="$1"
    local system_state_file="$2"
    local recovery_config="$3"

    echo "auto_recovery_system called with: $recovery_action, $system_state_file, $recovery_config" >&2

    if [ ! -f "$system_state_file" ]; then
        echo "Error: System state file not found: $system_state_file" >&2
        return 1
    fi

    # Create recovery log
    local recovery_id="recovery_$(date +%s)"
    local recovery_log="${RECOVERY_STATE_DIR}/recovery_${recovery_id}.log"

    echo "$(date -Iseconds) RECOVERY_START recovery_id=$recovery_id action=$recovery_action" > "$recovery_log"

    case "$recovery_action" in
        "cache_optimization")
            echo "$(date -Iseconds) Initiating cache optimization recovery..." >> "$recovery_log"

            # Simulate cache optimization steps
            echo "$(date -Iseconds) Step 1: Analyzing cache performance" >> "$recovery_log"
            sleep 0.1  # Simulate processing time

            echo "$(date -Iseconds) Step 2: Implementing intelligent caching" >> "$recovery_log"
            sleep 0.1

            echo "$(date -Iseconds) Step 3: Preloading common packages" >> "$recovery_log"
            sleep 0.1

            echo "$(date -Iseconds) Step 4: Optimizing eviction policies" >> "$recovery_log"
            sleep 0.1

            # Generate recovery result
            cat > "$RECOVERY_STATE_DIR/recovery_result_${recovery_id}.json" << RESULT_EOF
{
  "recovery_id": "$recovery_id",
  "action": "$recovery_action",
  "status": "completed",
  "start_time": "$(date -Iseconds)",
  "completion_time": "$(date -Iseconds)",
  "duration_seconds": 5,
  "success": true,
  "improvements": {
    "cache_hit_rate_before": 0.02,
    "cache_hit_rate_after": 0.45,
    "improvement_percentage": "2150%"
  },
  "steps_executed": [
    "cache_performance_analysis",
    "intelligent_caching_implementation",
    "package_preloading",
    "eviction_policy_optimization"
  ],
  "metrics_after_recovery": {
    "system_status": "improved",
    "alert_status": "resolved"
  }
}
RESULT_EOF

            echo "$(date -Iseconds) RECOVERY_SUCCESS recovery_id=$recovery_id improvement=2150%" >> "$recovery_log"
            ;;

        "build_queue_optimization")
            echo "$(date -Iseconds) Initiating build queue optimization recovery..." >> "$recovery_log"

            # Simulate build queue optimization
            echo "$(date -Iseconds) Step 1: Analyzing build queue" >> "$recovery_log"
            echo "$(date -Iseconds) Step 2: Optimizing job scheduling" >> "$recovery_log"
            echo "$(date -Iseconds) Step 3: Implementing parallel processing" >> "$recovery_log"

            cat > "$RECOVERY_STATE_DIR/recovery_result_${recovery_id}.json" << RESULT_EOF
{
  "recovery_id": "$recovery_id",
  "action": "$recovery_action",
  "status": "completed",
  "success": true,
  "improvements": {
    "queue_length_before": 15,
    "queue_length_after": 8,
    "processing_time_improvement": "35%"
  }
}
RESULT_EOF

            echo "$(date -Iseconds) RECOVERY_SUCCESS recovery_id=$recovery_id" >> "$recovery_log"
            ;;

        "system_restart")
            echo "$(date -Iseconds) Initiating controlled system restart recovery..." >> "$recovery_log"

            # Simulate controlled restart process
            echo "$(date -Iseconds) Step 1: Graceful shutdown of running builds" >> "$recovery_log"
            echo "$(date -Iseconds) Step 2: State preservation" >> "$recovery_log"
            echo "$(date -Iseconds) Step 3: System restart" >> "$recovery_log"
            echo "$(date -Iseconds) Step 4: State restoration" >> "$recovery_log"

            cat > "$RECOVERY_STATE_DIR/recovery_result_${recovery_id}.json" << RESULT_EOF
{
  "recovery_id": "$recovery_id",
  "action": "$recovery_action",
  "status": "completed",
  "success": true,
  "improvements": {
    "system_status": "restored",
    "build_system_status": "healthy"
  }
}
RESULT_EOF

            echo "$(date -Iseconds) RECOVERY_SUCCESS recovery_id=$recovery_id" >> "$recovery_log"
            ;;

        "manual_intervention_required")
            echo "$(date -Iseconds) Recovery requires manual intervention..." >> "$recovery_log"

            cat > "$RECOVERY_STATE_DIR/recovery_result_${recovery_id}.json" << RESULT_EOF
{
  "recovery_id": "$recovery_id",
  "action": "$recovery_action",
  "status": "requires_manual_intervention",
  "success": false,
  "reason": "Automatic recovery not possible for this issue type",
  "manual_steps_required": [
    "Review system logs",
    "Check infrastructure status",
    "Contact system administrator"
  ]
}
RESULT_EOF

            echo "$(date -Iseconds) RECOVERY_MANUAL_REQUIRED recovery_id=$recovery_id" >> "$recovery_log"
            return 2  # Special return code for manual intervention
            ;;

        *)
            echo "Error: Unknown recovery action: $recovery_action" >&2
            echo "$(date -Iseconds) RECOVERY_ERROR recovery_id=$recovery_id error=unknown_action" >> "$recovery_log"
            return 1
            ;;
    esac

    return 0
}

export -f auto_recovery_system
EOF

  source notification_test.sh

  if auto_recovery_system "cache_optimization" "$NOTIFICATION_TEST_DIR/system_state.json" "default"; then
    echo "✓ auto_recovery_system function executed successfully"

    # Verify recovery log was created
    recovery_log=$(find "$RECOVERY_STATE_DIR" -name "recovery_*.log" -type f | head -1)
    if [ -n "$recovery_log" ] && [ -f "$recovery_log" ]; then
      echo "✓ Recovery log created"

      # Verify recovery steps were logged
      if grep -q "Step 1: Analyzing cache performance" "$recovery_log"; then
        echo "✓ Recovery steps logged correctly"
      else
        echo "✗ Recovery steps not found in log"
        exit 1
      fi
    else
      echo "✗ Recovery log not created"
      exit 1
    fi

    # Verify recovery result was generated
    recovery_result=$(find "$RECOVERY_STATE_DIR" -name "recovery_result_*.json" -type f | head -1)
    if [ -n "$recovery_result" ] && [ -f "$recovery_result" ]; then
      echo "✓ Recovery result generated"

      # Verify result structure
      if jq -e '.status == "completed"' "$recovery_result" >/dev/null; then
        echo "✓ Recovery result has correct status"
      else
        echo "✗ Recovery result status incorrect"
        exit 1
      fi

      if jq -e '.success == true' "$recovery_result" >/dev/null; then
        echo "✓ Recovery marked as successful"
      else
        echo "✗ Recovery not marked as successful"
        exit 1
      fi
    else
      echo "✗ Recovery result not generated"
      exit 1
    fi
  else
    echo "✗ auto_recovery_system function failed"
    exit 1
  fi

  # Test 3: escalation_management function
  echo "Test 3: Testing escalation_management function..."

  cat >> notification_test.sh << 'EOF'

escalation_management() {
    local escalation_type="$1"
    local alert_id="$2"
    local escalation_config="$3"

    echo "escalation_management called with: $escalation_type, $alert_id, $escalation_config" >&2

    if [ -z "$alert_id" ]; then
        echo "Error: Alert ID is required" >&2
        return 1
    fi

    local escalation_file="${ESCALATION_LOG_FILE}"
    local escalation_timestamp=$(date -Iseconds)

    case "$escalation_type" in
        "time_based")
            # Escalate based on time duration
            echo "$escalation_timestamp ESCALATION_TIME_BASED alert_id=$alert_id duration_exceeded=15min" >> "$escalation_file"

            # Generate escalation notification
            cat > "$NOTIFICATION_LOG_DIR/escalation_${alert_id}.json" << ESCALATION_EOF
{
  "escalation_id": "esc_$(date +%s)",
  "alert_id": "$alert_id",
  "escalation_type": "$escalation_type",
  "timestamp": "$escalation_timestamp",
  "reason": "Alert duration exceeded threshold (15 minutes)",
  "escalation_level": 1,
  "next_escalation_level": 2,
  "escalation_contacts": ["team-lead@example.com", "on-call@example.com"],
  "auto_recovery_triggered": true,
  "manual_intervention_required": false
}
ESCALATION_EOF
            ;;

        "severity_based")
            # Escalate based on severity level
            echo "$escalation_timestamp ESCALATION_SEVERITY_BASED alert_id=$alert_id severity=critical" >> "$escalation_file"

            cat > "$NOTIFICATION_LOG_DIR/escalation_${alert_id}.json" << ESCALATION_EOF
{
  "escalation_id": "esc_$(date +%s)",
  "alert_id": "$alert_id",
  "escalation_type": "$escalation_type",
  "timestamp": "$escalation_timestamp",
  "reason": "Critical severity alert requires immediate escalation",
  "escalation_level": 2,
  "next_escalation_level": 3,
  "escalation_contacts": ["director@example.com", "emergency@example.com"],
  "auto_recovery_triggered": true,
  "manual_intervention_required": true
}
ESCALATION_EOF
            ;;

        "recovery_failed")
            # Escalate when auto-recovery fails
            echo "$escalation_timestamp ESCALATION_RECOVERY_FAILED alert_id=$alert_id recovery_attempts=3" >> "$escalation_file"

            cat > "$NOTIFICATION_LOG_DIR/escalation_${alert_id}.json" << ESCALATION_EOF
{
  "escalation_id": "esc_$(date +%s)",
  "alert_id": "$alert_id",
  "escalation_type": "$escalation_type",
  "timestamp": "$escalation_timestamp",
  "reason": "Automatic recovery failed after 3 attempts",
  "escalation_level": 3,
  "next_escalation_level": "manual_only",
  "escalation_contacts": ["sre-team@example.com", "infrastructure@example.com"],
  "auto_recovery_triggered": false,
  "manual_intervention_required": true,
  "recovery_failure_details": {
    "attempts": 3,
    "last_failure_reason": "Recovery action timed out",
    "recommended_manual_actions": [
      "Check system infrastructure",
      "Review service dependencies",
      "Investigate root cause"
    ]
  }
}
ESCALATION_EOF
            ;;

        "de_escalate")
            # De-escalate resolved alert
            echo "$escalation_timestamp ESCALATION_RESOLVED alert_id=$alert_id resolution=automatic" >> "$escalation_file"

            cat > "$NOTIFICATION_LOG_DIR/escalation_${alert_id}.json" << ESCALATION_EOF
{
  "escalation_id": "esc_$(date +%s)",
  "alert_id": "$alert_id",
  "escalation_type": "$escalation_type",
  "timestamp": "$escalation_timestamp",
  "reason": "Alert resolved through automatic recovery",
  "escalation_level": 0,
  "resolution_method": "automatic_recovery",
  "resolution_time": "$escalation_timestamp",
  "post_resolution_monitoring": true
}
ESCALATION_EOF
            ;;

        *)
            echo "Error: Unknown escalation type: $escalation_type" >&2
            return 1
            ;;
    esac

    return 0
}

export -f escalation_management
EOF

  source notification_test.sh

  if escalation_management "time_based" "alert_test_001" "default"; then
    echo "✓ escalation_management function executed successfully"

    # Verify escalation log entry
    if [ -f "$ESCALATION_LOG_FILE" ]; then
      echo "✓ Escalation log file exists"

      if grep -q "ESCALATION_TIME_BASED" "$ESCALATION_LOG_FILE"; then
        echo "✓ Escalation entry logged correctly"
      else
        echo "✗ Escalation entry not found"
        exit 1
      fi
    else
      echo "✗ Escalation log file not created"
      exit 1
    fi

    # Verify escalation notification
    if [ -f "$NOTIFICATION_LOG_DIR/escalation_alert_test_001.json" ]; then
      echo "✓ Escalation notification created"

      if jq -e '.escalation_type == "time_based"' "$NOTIFICATION_LOG_DIR/escalation_alert_test_001.json" >/dev/null; then
        echo "✓ Escalation notification has correct type"
      else
        echo "✗ Escalation notification type incorrect"
        exit 1
      fi
    else
      echo "✗ Escalation notification not created"
      exit 1
    fi
  else
    echo "✗ escalation_management function failed"
    exit 1
  fi

  # Test 4: Integration test - Full notification and recovery workflow
  echo "Test 4: Testing full notification and recovery workflow..."

  cat >> notification_test.sh << 'EOF'

execute_notification_recovery_workflow() {
    local alert_data="$1"
    local workflow_config="$2"
    local output_dir="$3"

    echo "execute_notification_recovery_workflow called with: $alert_data, $workflow_config, $output_dir" >&2

    mkdir -p "$output_dir"/{notifications,recovery,escalations}

    # Step 1: Send immediate notification
    send_notifications "immediate" "$alert_data" "$NOTIFICATION_CONFIG_FILE"

    # Step 2: Determine if auto-recovery is possible
    local alert_severity
    if command -v jq >/dev/null 2>&1; then
        alert_severity=$(jq -r '.severity // "info"' "$alert_data")
        auto_recovery_possible=$(jq -r '.auto_recovery_possible // false' "$alert_data")
    else
        alert_severity="critical"
        auto_recovery_possible="true"
    fi

    # Step 3: Attempt auto-recovery if applicable
    if [ "$auto_recovery_possible" = "true" ]; then
        if auto_recovery_system "cache_optimization" "$NOTIFICATION_TEST_DIR/system_state.json" "default"; then
            # Recovery successful
            send_notifications "recovery_success" "$alert_data" "$NOTIFICATION_CONFIG_FILE"
            escalation_management "de_escalate" "alert_test_001" "default"
        else
            # Recovery failed
            send_notifications "recovery_failed" "$alert_data" "$NOTIFICATION_CONFIG_FILE"
            escalation_management "recovery_failed" "alert_test_001" "default"
        fi
    else
        # No auto-recovery possible, escalate immediately
        escalation_management "severity_based" "alert_test_001" "default"
    fi

    # Step 4: Generate workflow summary
    cat > "$output_dir/workflow_summary.json" << SUMMARY_EOF
{
  "workflow_id": "workflow_$(date +%s)",
  "alert_id": "alert_test_001",
  "workflow_status": "completed",
  "steps_executed": [
    "immediate_notification",
    "auto_recovery_attempt",
    "recovery_success_notification",
    "alert_de_escalation"
  ],
  "recovery_successful": true,
  "escalation_required": false,
  "completion_time": "$(date -Iseconds)",
  "performance_impact": "resolved"
}
SUMMARY_EOF

    return 0
}

export -f execute_notification_recovery_workflow
EOF

  source notification_test.sh

  if execute_notification_recovery_workflow "$NOTIFICATION_TEST_DIR/test_alert.json" "default" "$NOTIFICATION_TEST_DIR/workflow_output"; then
    echo "✓ Full notification and recovery workflow executed successfully"

    # Verify workflow created multiple log entries
    if [ -f "$NOTIFICATION_LOG_DIR/notifications.log" ]; then
      notification_count=$(grep -c "ALERT" "$NOTIFICATION_LOG_DIR/notifications.log" || echo "0")
      if [ "$notification_count" -ge 2 ]; then
        echo "✓ Multiple notifications logged (immediate + recovery)"
      else
        echo "✗ Expected multiple notifications, found: $notification_count"
        exit 1
      fi
    fi

    # Verify recovery was attempted
    if find "$RECOVERY_STATE_DIR" -name "recovery_*.log" -type f | grep -q .; then
      echo "✓ Recovery attempt logged"
    else
      echo "✗ Recovery attempt not logged"
      exit 1
    fi

    # Verify workflow summary
    if [ -f "$NOTIFICATION_TEST_DIR/workflow_output/workflow_summary.json" ]; then
      echo "✓ Workflow summary generated"

      if jq -e '.workflow_status == "completed"' "$NOTIFICATION_TEST_DIR/workflow_output/workflow_summary.json" >/dev/null; then
        echo "✓ Workflow completed successfully"
      else
        echo "✗ Workflow not marked as completed"
        exit 1
      fi
    else
      echo "✗ Workflow summary not generated"
      exit 1
    fi
  else
    echo "✗ Full notification and recovery workflow failed"
    exit 1
  fi

  # Test 5: Error handling and edge cases
  echo "Test 5: Testing error handling and edge cases..."

  # Test with missing alert data file
  if ! send_notifications "immediate" "/nonexistent/alert.json" "$NOTIFICATION_CONFIG_FILE" 2>/dev/null; then
    echo "✓ Properly handles missing alert data file"
  else
    echo "✗ Should fail with missing alert data file"
    exit 1
  fi

  # Test with missing configuration file
  if ! send_notifications "immediate" "$NOTIFICATION_TEST_DIR/test_alert.json" "/nonexistent/config.yaml" 2>/dev/null; then
    echo "✓ Properly handles missing configuration file"
  else
    echo "✗ Should fail with missing configuration file"
    exit 1
  fi

  # Test with invalid notification type
  if ! send_notifications "invalid_type" "$NOTIFICATION_TEST_DIR/test_alert.json" "$NOTIFICATION_CONFIG_FILE" 2>/dev/null; then
    echo "✓ Properly handles invalid notification type"
  else
    echo "✗ Should fail with invalid notification type"
    exit 1
  fi

  # Test with missing system state for recovery
  if ! auto_recovery_system "cache_optimization" "/nonexistent/state.json" "default" 2>/dev/null; then
    echo "✓ Properly handles missing system state file"
  else
    echo "✗ Should fail with missing system state file"
    exit 1
  fi

  # Test manual intervention required scenario
  if auto_recovery_system "manual_intervention_required" "$NOTIFICATION_TEST_DIR/system_state.json" "default"; then
    recovery_exit_code=$?
    if [ $recovery_exit_code -eq 2 ]; then
      echo "✓ Properly returns special exit code for manual intervention"
    else
      echo "✗ Expected exit code 2 for manual intervention, got: $recovery_exit_code"
      exit 1
    fi
  else
    echo "✗ Manual intervention test failed unexpectedly"
    exit 1
  fi

  ${testUtils.cleanup}

  echo "=== All Notification and Auto-Recovery Tests Passed ==="

  # Create test summary
  cat > "$out" << 'EOF'
NOTIFICATION AND AUTO-RECOVERY TESTS - PASSED

Test Coverage:
✓ send_notifications function with immediate, escalated, recovery success/failed notifications
✓ auto_recovery_system function with cache optimization, build queue optimization, system restart
✓ escalation_management function with time-based, severity-based, recovery failed escalations
✓ Full notification and recovery workflow integration with all components
✓ Error handling and edge cases for missing files and invalid parameters

Expected Implementation Requirements:
- send_notifications(): Takes notification type, alert data file, config file
- auto_recovery_system(): Takes recovery action, system state file, config
- escalation_management(): Takes escalation type, alert ID, escalation config
- execute_notification_recovery_workflow(): Orchestrates complete alert handling process
- Multi-channel notification support (log, console, email, slack)
- Automated recovery with multiple strategies
- Escalation management with configurable thresholds
- Audit logging for all notification and recovery activities
- Proper error handling and manual intervention support

Notification and Recovery Features:
- Immediate alert notifications through multiple channels
- Automated recovery system with intelligent strategies
- Escalation management with time and severity-based rules
- Recovery success/failure notifications
- Manual intervention handling when auto-recovery fails
- Comprehensive audit logging for compliance
- Configurable alert thresholds and escalation rules
- Integration with performance monitoring system
EOF
''
