{ pkgs }:

let
  # Notification management constants
  CACHE_DIR = "\${HOME}/.cache";
  NOTIFICATIONS_DIR = "\${CACHE_DIR}/dotfiles-updates";
  NOTIFICATION_PREFIX = "pending-";
  NOTIFICATION_SUFFIX = ".json";
  CLEANUP_DAYS = "30"; # Days after which to clean up old notifications

  # Import state management library for integration
  stateLib = import ./auto-update-state.nix { inherit pkgs; };

  # Create helper scripts for notification management
  scripts = pkgs.runCommand "auto-update-notifications-scripts"
  {
    buildInputs = with pkgs; [ bash coreutils jq ];
  } ''
    mkdir -p $out/bin

    # create_notification function - Create notification file for update
    cat > $out/bin/create_notification << 'EOF'
#!/bin/bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
NOTIFICATIONS_DIR="${NOTIFICATIONS_DIR}"
NOTIFICATION_PREFIX="${NOTIFICATION_PREFIX}"
NOTIFICATION_SUFFIX="${NOTIFICATION_SUFFIX}"

# Validate parameters
if [[ $# -ne 3 ]]; then
    echo "Usage: create_notification <commit_hash> <summary> <message>" >&2
    exit 1
fi

COMMIT_HASH="$1"
SUMMARY="$2"
MESSAGE="$3"

# Validate inputs
if [[ -z "$COMMIT_HASH" ]]; then
    echo "Error: commit_hash cannot be empty" >&2
    exit 1
fi

if [[ -z "$SUMMARY" ]]; then
    echo "Error: summary cannot be empty" >&2
    exit 1
fi

if [[ -z "$MESSAGE" ]]; then
    echo "Error: message cannot be empty" >&2
    exit 1
fi

# Validate commit hash format (basic check)
if ! [[ "$COMMIT_HASH" =~ ^[a-f0-9]+$ ]]; then
    echo "Error: commit_hash must contain only lowercase hex characters" >&2
    exit 1
fi

# Create notifications directory
mkdir -p "$NOTIFICATIONS_DIR"

# Check if directory is writable
if [[ ! -w "$NOTIFICATIONS_DIR" ]]; then
    echo "Error: Cannot write to notifications directory: $NOTIFICATIONS_DIR" >&2
    exit 1
fi

# Define notification file path
NOTIFICATION_FILE="$NOTIFICATIONS_DIR/$NOTIFICATION_PREFIX$COMMIT_HASH$NOTIFICATION_SUFFIX"

# Check for duplicate notification
if [[ -f "$NOTIFICATION_FILE" ]]; then
    echo "Error: Notification for commit $COMMIT_HASH already exists" >&2
    exit 1
fi

# Create notification content
TIMESTAMP=$(date +%s)
NOTIFICATION_CONTENT=$(jq -n \
    --arg commit_hash "$COMMIT_HASH" \
    --arg timestamp "$TIMESTAMP" \
    --arg summary "$SUMMARY" \
    --arg message "$MESSAGE" \
    '{
        commit_hash: $commit_hash,
        timestamp: ($timestamp | tonumber),
        summary: $summary,
        message: $message
    }')

# Write notification file
echo "$NOTIFICATION_CONTENT" > "$NOTIFICATION_FILE"

# Update state management to track pending update
if command -v ${stateLib}/bin/get_state >/dev/null 2>&1; then
    # Add to pending updates in state
    CURRENT_STATE=$(${stateLib}/bin/get_state 2>/dev/null || echo '{"pending_updates":{},"user_decisions":{},"last_cleanup":0}')
    UPDATED_STATE=$(echo "$CURRENT_STATE" | jq \
        --arg commit "$COMMIT_HASH" \
        --arg timestamp "$TIMESTAMP" \
        '.pending_updates[$commit] = {"timestamp": ($timestamp | tonumber)}')

    # Write updated state back (using temporary approach since set_decision is for decisions)
    echo "$UPDATED_STATE" > "${CACHE_DIR}/dotfiles-update-state.json"
fi

echo "Notification created successfully for commit: $COMMIT_HASH"
EOF

    # cleanup_notification function - Remove specific notification
    cat > $out/bin/cleanup_notification << 'EOF'
#!/bin/bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
NOTIFICATIONS_DIR="${NOTIFICATIONS_DIR}"
NOTIFICATION_PREFIX="${NOTIFICATION_PREFIX}"
NOTIFICATION_SUFFIX="${NOTIFICATION_SUFFIX}"

# Validate parameters
if [[ $# -ne 1 ]]; then
    echo "Usage: cleanup_notification <commit_hash>" >&2
    exit 1
fi

COMMIT_HASH="$1"

# Validate input
if [[ -z "$COMMIT_HASH" ]]; then
    echo "Error: commit_hash cannot be empty" >&2
    exit 1
fi

# Define notification file path
NOTIFICATION_FILE="$NOTIFICATIONS_DIR/$NOTIFICATION_PREFIX$COMMIT_HASH$NOTIFICATION_SUFFIX"

# Remove notification file if it exists
if [[ -f "$NOTIFICATION_FILE" ]]; then
    rm -f "$NOTIFICATION_FILE"
    echo "Notification for commit $COMMIT_HASH removed successfully"
else
    echo "Warning: No notification found for commit $COMMIT_HASH" >&2
fi

# Update state management to remove pending update
if command -v ${stateLib}/bin/get_state >/dev/null 2>&1; then
    # Remove from pending updates in state
    CURRENT_STATE=$(${stateLib}/bin/get_state 2>/dev/null || echo '{"pending_updates":{},"user_decisions":{},"last_cleanup":0}')
    UPDATED_STATE=$(echo "$CURRENT_STATE" | jq \
        --arg commit "$COMMIT_HASH" \
        'del(.pending_updates[$commit])')

    # Write updated state back
    echo "$UPDATED_STATE" > "${CACHE_DIR}/dotfiles-update-state.json"
fi
EOF

    # get_pending_notifications function - List all pending notifications
    cat > $out/bin/get_pending_notifications << 'EOF'
#!/bin/bash
set -euo pipefail

NOTIFICATIONS_DIR="${NOTIFICATIONS_DIR}"
NOTIFICATION_PREFIX="${NOTIFICATION_PREFIX}"
NOTIFICATION_SUFFIX="${NOTIFICATION_SUFFIX}"

# Ensure notifications directory exists
if [[ ! -d "$NOTIFICATIONS_DIR" ]]; then
    echo "[]"
    exit 0
fi

# Find all pending notification files
NOTIFICATION_FILES=()
for file in "$NOTIFICATIONS_DIR"/$NOTIFICATION_PREFIX*$NOTIFICATION_SUFFIX; do
    if [[ -f "$file" ]]; then
        NOTIFICATION_FILES+=("$file")
    fi
done

# If no files found, return empty array
if [[ ''${#NOTIFICATION_FILES[@]} -eq 0 ]]; then
    echo "[]"
    exit 0
fi

# Read and combine all notifications into JSON array
echo "["
first=true
for file in "''${NOTIFICATION_FILES[@]}"; do
    if [[ "$first" == "true" ]]; then
        first=false
    else
        echo ","
    fi
    cat "$file"
done
echo "]"
EOF

    # cleanup_old_notifications function - Remove notifications older than specified days
    cat > $out/bin/cleanup_old_notifications << 'EOF'
#!/bin/bash
set -euo pipefail

NOTIFICATIONS_DIR="${NOTIFICATIONS_DIR}"
NOTIFICATION_PREFIX="${NOTIFICATION_PREFIX}"
NOTIFICATION_SUFFIX="${NOTIFICATION_SUFFIX}"
CLEANUP_DAYS="${CLEANUP_DAYS}"

# Use provided days or default
DAYS_TO_KEEP="$CLEANUP_DAYS"
if [[ $# -eq 1 ]] && [[ "$1" =~ ^[0-9]+$ ]]; then
    DAYS_TO_KEEP="$1"
fi

# Ensure notifications directory exists
if [[ ! -d "$NOTIFICATIONS_DIR" ]]; then
    echo "No notifications directory found"
    exit 0
fi

# Calculate cutoff timestamp
CURRENT_TIME=$(date +%s)
CUTOFF_TIME=$((CURRENT_TIME - DAYS_TO_KEEP * 24 * 3600))

CLEANED_COUNT=0

# Find and remove old notification files
for file in "$NOTIFICATIONS_DIR"/$NOTIFICATION_PREFIX*$NOTIFICATION_SUFFIX; do
    if [[ -f "$file" ]]; then
        # Extract timestamp from notification file
        TIMESTAMP=$(jq -r '.timestamp // 0' "$file" 2>/dev/null || echo 0)

        # Remove if older than cutoff
        if [[ "$TIMESTAMP" -lt "$CUTOFF_TIME" ]]; then
            rm -f "$file"
            ((CLEANED_COUNT++))
        fi
    fi
done

echo "Cleaned up $CLEANED_COUNT old notifications (older than $DAYS_TO_KEEP days)"
EOF

    # validate_notification function - Validate notification file format
    cat > $out/bin/validate_notification << 'EOF'
#!/bin/bash
set -euo pipefail

# Validate parameters
if [[ $# -ne 1 ]]; then
    echo "Usage: validate_notification <notification_file>" >&2
    exit 1
fi

NOTIFICATION_FILE="$1"

# Check if file exists
if [[ ! -f "$NOTIFICATION_FILE" ]]; then
    echo "Error: Notification file does not exist: $NOTIFICATION_FILE" >&2
    exit 1
fi

# Check if file contains valid JSON
if ! jq empty "$NOTIFICATION_FILE" 2>/dev/null; then
    echo "Error: Notification file does not contain valid JSON" >&2
    exit 1
fi

# Check required fields
CONTENT=$(cat "$NOTIFICATION_FILE")

# Validate required fields exist and are not empty
COMMIT_HASH=$(echo "$CONTENT" | jq -r '.commit_hash // empty')
TIMESTAMP=$(echo "$CONTENT" | jq -r '.timestamp // empty')
SUMMARY=$(echo "$CONTENT" | jq -r '.summary // empty')
MESSAGE=$(echo "$CONTENT" | jq -r '.message // empty')

if [[ -z "$COMMIT_HASH" ]]; then
    echo "Error: Missing or empty commit_hash field" >&2
    exit 1
fi

if [[ -z "$TIMESTAMP" ]] || ! [[ "$TIMESTAMP" =~ ^[0-9]+$ ]]; then
    echo "Error: Missing or invalid timestamp field" >&2
    exit 1
fi

if [[ -z "$SUMMARY" ]]; then
    echo "Error: Missing or empty summary field" >&2
    exit 1
fi

if [[ -z "$MESSAGE" ]]; then
    echo "Error: Missing or empty message field" >&2
    exit 1
fi

echo "Notification file is valid"
EOF

    # Make all scripts executable
    chmod +x $out/bin/*
  '';

in scripts
