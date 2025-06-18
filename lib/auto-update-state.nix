{ pkgs }:

let
  # State management constants
  CACHE_DIR = "\${HOME}/.cache";
  STATE_FILE = "\${CACHE_DIR}/dotfiles-update-state.json";
  LOCK_FILE = "\${CACHE_DIR}/dotfiles-update-state.lock";
  LOCK_TIMEOUT = "300"; # 5 minutes in seconds
  CLEANUP_DAYS = "30"; # Days after which to clean up old entries

  # Create helper scripts for state management
  scripts = pkgs.runCommand "auto-update-state-scripts"
  {
    buildInputs = with pkgs; [ bash coreutils jq ];
  } ''
    mkdir -p $out/bin

    # get_state function - Initialize and return current state
    cat > $out/bin/get_state << 'EOF'
#!/bin/bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
STATE_FILE="${STATE_FILE}"
LOCK_FILE="${LOCK_FILE}"
LOCK_TIMEOUT="${LOCK_TIMEOUT}"

# Function to acquire file lock
acquire_lock() {
    local timeout="$1"
    local start_time=$(date +%s)

    while true; do
        # Check if lock file exists and is stale
        if [[ -f "$LOCK_FILE" ]]; then
            # Use cross-platform stat command
            local lock_timestamp
            if [[ "$(uname)" == "Darwin" ]]; then
                lock_timestamp=$(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)
            else
                lock_timestamp=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)
            fi
            local lock_age=$(( $(date +%s) - lock_timestamp ))
            if [[ $lock_age -gt $LOCK_TIMEOUT ]]; then
                # Remove stale lock
                rm -f "$LOCK_FILE" 2>/dev/null || true
            fi
        fi

        # Try to acquire lock
        if (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
            return 0
        fi

        # Check timeout
        local current_time=$(date +%s)
        if [[ $((current_time - start_time)) -gt $timeout ]]; then
            return 1
        fi

        sleep 0.1
    done
}

# Function to release file lock
release_lock() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

# Function to initialize state structure
init_state() {
    local current_time=$(date +%s)
    echo "{\"pending_updates\":{},\"user_decisions\":{},\"last_cleanup\":$current_time}"
}

# Function to validate and repair state file
validate_state() {
    local state_content="$1"

    # Check if it's valid JSON
    if ! echo "$state_content" | jq empty 2>/dev/null; then
        return 1
    fi

    # Check if it has required structure
    local has_structure=$(echo "$state_content" | jq 'has("pending_updates") and has("user_decisions") and has("last_cleanup")' 2>/dev/null)
    if [[ "$has_structure" != "true" ]]; then
        return 1
    fi

    return 0
}

# Main logic
main() {
    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Acquire lock
    if ! acquire_lock 10; then
        echo "Failed to acquire lock for state file" >&2
        exit 1
    fi

    # Ensure lock is released on exit
    trap release_lock EXIT

    # Check if state file exists and is valid
    if [[ -f "$STATE_FILE" ]]; then
        local state_content=$(cat "$STATE_FILE" 2>/dev/null || echo "")

        if [[ -n "$state_content" ]] && validate_state "$state_content"; then
            echo "$state_content"
            return 0
        fi
    fi

    # Initialize or repair state file
    local new_state=$(init_state)
    echo "$new_state" > "$STATE_FILE"
    echo "$new_state"
}

main "$@"
EOF

    # set_decision function - Store user decision
    cat > $out/bin/set_decision << 'EOF'
#!/bin/bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
STATE_FILE="${STATE_FILE}"
LOCK_FILE="${LOCK_FILE}"
LOCK_TIMEOUT="${LOCK_TIMEOUT}"

# Validate parameters
if [[ $# -ne 3 ]]; then
    echo "Usage: set_decision <commit_hash> <decision> <timestamp>" >&2
    exit 1
fi

COMMIT_HASH="$1"
DECISION="$2"
TIMESTAMP="$3"

# Validate inputs
if [[ -z "$COMMIT_HASH" ]]; then
    echo "Error: commit_hash cannot be empty" >&2
    exit 1
fi

if [[ -z "$DECISION" ]]; then
    echo "Error: decision cannot be empty" >&2
    exit 1
fi

# Validate decision type
case "$DECISION" in
    "apply"|"defer"|"skip")
        ;;
    *)
        echo "Error: decision must be one of: apply, defer, skip" >&2
        exit 1
        ;;
esac

# Validate timestamp is numeric
if ! [[ "$TIMESTAMP" =~ ^[0-9]+$ ]]; then
    echo "Error: timestamp must be numeric" >&2
    exit 1
fi

# Function to acquire file lock (same as get_state)
acquire_lock() {
    local timeout="$1"
    local start_time=$(date +%s)

    while true; do
        if [[ -f "$LOCK_FILE" ]]; then
            # Use cross-platform stat command
            local lock_timestamp
            if [[ "$(uname)" == "Darwin" ]]; then
                lock_timestamp=$(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)
            else
                lock_timestamp=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)
            fi
            local lock_age=$(( $(date +%s) - lock_timestamp ))
            if [[ $lock_age -gt $LOCK_TIMEOUT ]]; then
                rm -f "$LOCK_FILE" 2>/dev/null || true
            fi
        fi

        if (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
            return 0
        fi

        local current_time=$(date +%s)
        if [[ $((current_time - start_time)) -gt $timeout ]]; then
            return 1
        fi

        sleep 0.1
    done
}

# Function to release file lock
release_lock() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

# Main logic
main() {
    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Acquire lock
    if ! acquire_lock 10; then
        echo "Failed to acquire lock for state file" >&2
        exit 1
    fi

    # Ensure lock is released on exit
    trap release_lock EXIT

    # Get current state (without lock since we already have it)
    local current_state
    if [[ -f "$STATE_FILE" ]]; then
        current_state=$(cat "$STATE_FILE" 2>/dev/null || echo '{"pending_updates":{},"user_decisions":{},"last_cleanup":0}')
        # Validate and repair if needed
        if ! echo "$current_state" | jq empty 2>/dev/null; then
            current_state='{"pending_updates":{},"user_decisions":{},"last_cleanup":0}'
        fi
    else
        current_state='{"pending_updates":{},"user_decisions":{},"last_cleanup":0}'
    fi

    # Add user decision
    local updated_state=$(echo "$current_state" | jq \
        --arg commit "$COMMIT_HASH" \
        --arg decision "$DECISION" \
        --arg timestamp "$TIMESTAMP" \
        '.user_decisions[$commit] = {"decision": $decision, "timestamp": ($timestamp | tonumber)}')

    # Write back to file
    echo "$updated_state" > "$STATE_FILE"
}

main "$@"
EOF

    # get_decision function - Retrieve user decision for a commit
    cat > $out/bin/get_decision << 'EOF'
#!/bin/bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
STATE_FILE="${STATE_FILE}"

if [[ $# -ne 1 ]]; then
    echo "Usage: get_decision <commit_hash>" >&2
    exit 1
fi

COMMIT_HASH="$1"

if [[ -z "$COMMIT_HASH" ]]; then
    echo "Error: commit_hash cannot be empty" >&2
    exit 1
fi

# Get current state directly
current_state=$(cat "${STATE_FILE}" 2>/dev/null || echo '{"pending_updates":{},"user_decisions":{},"last_cleanup":0}')

# Extract decision for the commit
decision=$(echo "$current_state" | jq -r ".user_decisions.\"$COMMIT_HASH\".decision // empty" 2>/dev/null || echo "")

if [[ -n "$decision" ]]; then
    echo "$decision"
    exit 0
else
    exit 1
fi
EOF

    # cleanup_old function - Clean up entries older than specified days
    cat > $out/bin/cleanup_old << 'EOF'
#!/bin/bash
set -euo pipefail

CACHE_DIR="${CACHE_DIR}"
STATE_FILE="${STATE_FILE}"
LOCK_FILE="${LOCK_FILE}"
LOCK_TIMEOUT="${LOCK_TIMEOUT}"
CLEANUP_DAYS="${CLEANUP_DAYS}"

# Function to acquire file lock (same as above)
acquire_lock() {
    local timeout="$1"
    local start_time=$(date +%s)

    while true; do
        if [[ -f "$LOCK_FILE" ]]; then
            # Use cross-platform stat command
            local lock_timestamp
            if [[ "$(uname)" == "Darwin" ]]; then
                lock_timestamp=$(stat -f %m "$LOCK_FILE" 2>/dev/null || echo 0)
            else
                lock_timestamp=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || echo 0)
            fi
            local lock_age=$(( $(date +%s) - lock_timestamp ))
            if [[ $lock_age -gt $LOCK_TIMEOUT ]]; then
                rm -f "$LOCK_FILE" 2>/dev/null || true
            fi
        fi

        if (set -C; echo $$ > "$LOCK_FILE") 2>/dev/null; then
            return 0
        fi

        local current_time=$(date +%s)
        if [[ $((current_time - start_time)) -gt $timeout ]]; then
            return 1
        fi

        sleep 0.1
    done
}

# Function to release file lock
release_lock() {
    rm -f "$LOCK_FILE" 2>/dev/null || true
}

# Main logic
main() {
    # Ensure cache directory exists
    mkdir -p "$CACHE_DIR"

    # Acquire lock
    if ! acquire_lock 10; then
        echo "Failed to acquire lock for state file" >&2
        exit 1
    fi

    # Ensure lock is released on exit
    trap release_lock EXIT

    # Get current state (without lock since we already have it)
    local current_state
    if [[ -f "$STATE_FILE" ]]; then
        current_state=$(cat "$STATE_FILE" 2>/dev/null || echo '{"pending_updates":{},"user_decisions":{},"last_cleanup":0}')
        # Validate and repair if needed
        if ! echo "$current_state" | jq empty 2>/dev/null; then
            current_state='{"pending_updates":{},"user_decisions":{},"last_cleanup":0}'
        fi
    else
        current_state='{"pending_updates":{},"user_decisions":{},"last_cleanup":0}'
    fi

    # Calculate cutoff timestamp
    local current_time=$(date +%s)
    local cutoff_time=$((current_time - CLEANUP_DAYS * 24 * 3600))

    # Clean up old user decisions
    local cleaned_state=$(echo "$current_state" | jq \
        --arg cutoff "$cutoff_time" \
        '.user_decisions = (.user_decisions | to_entries | map(select(.value.timestamp >= ($cutoff | tonumber))) | from_entries)')

    # Update last cleanup timestamp
    local final_state=$(echo "$cleaned_state" | jq \
        --arg timestamp "$current_time" \
        '.last_cleanup = ($timestamp | tonumber)')

    # Write back to file
    echo "$final_state" > "$STATE_FILE"
}

main "$@"
EOF

    # Make all scripts executable
    chmod +x $out/bin/*
  '';

in scripts
