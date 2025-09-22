#!/usr/bin/env bash

# T030: Test mocks library
# Provides mocking functionality for external dependencies and commands

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.bash"

# Mock management
declare -A MOCKS=()
declare -A MOCK_CALLS=()
declare -A MOCK_CALL_COUNTS=()
declare -a MOCK_CLEANUP_QUEUE=()

# Mock registry and management
mock_command() {
    local command_name="$1"
    local mock_behavior="$2"
    local mock_output="${3:-}"
    local mock_exit_code="${4:-0}"

    # Store original command path if it exists
    local original_path
    original_path=$(command -v "$command_name" 2>/dev/null || echo "")

    if [[ -n "$original_path" ]]; then
        MOCKS["${command_name}:original"]="$original_path"
    fi

    # Create mock script
    local mock_script="/tmp/mock_${command_name}_$$"
    cat > "$mock_script" << EOF
#!/bin/bash
# Mock for $command_name

# Log the call
echo "\$*" >> "/tmp/mock_${command_name}_calls_$$"

# Execute mock behavior
case "$mock_behavior" in
    "success")
        echo "$mock_output"
        exit $mock_exit_code
        ;;
    "failure")
        echo "$mock_output" >&2
        exit ${mock_exit_code:-1}
        ;;
    "custom")
        $mock_output
        ;;
    "echo")
        echo "$mock_output"
        exit $mock_exit_code
        ;;
    "passthrough")
        # Execute original command if available
        if [[ -n "${MOCKS["${command_name}:original"]:-}" ]]; then
            exec "\${MOCKS["${command_name}:original"]}" "\$@"
        else
            echo "Original command not found: $command_name" >&2
            exit 1
        fi
        ;;
    *)
        echo "Unknown mock behavior: $mock_behavior" >&2
        exit 1
        ;;
esac
EOF

    chmod +x "$mock_script"

    # Store mock information
    MOCKS["${command_name}:script"]="$mock_script"
    MOCKS["${command_name}:calls_file"]="/tmp/mock_${command_name}_calls_$$"
    MOCKS["${command_name}:behavior"]="$mock_behavior"

    # Initialize call count
    MOCK_CALL_COUNTS["$command_name"]=0

    # Create empty calls file
    touch "/tmp/mock_${command_name}_calls_$$"

    # Add to PATH
    export PATH="/tmp:$PATH"
    ln -sf "$mock_script" "/tmp/$command_name"

    # Add to cleanup queue
    MOCK_CLEANUP_QUEUE+=("$command_name")

    log_debug "Mocked command: $command_name with behavior: $mock_behavior"
}

mock_function() {
    local function_name="$1"
    local mock_behavior="$2"
    local mock_output="${3:-}"
    local mock_exit_code="${4:-0}"

    # Store original function if it exists
    if declare -f "$function_name" >/dev/null 2>&1; then
        local original_func
        original_func=$(declare -f "$function_name")
        MOCKS["${function_name}:original_func"]="$original_func"
    fi

    # Create mock function
    case "$mock_behavior" in
        "success")
            eval "${function_name}() { echo '$mock_output'; return $mock_exit_code; }"
            ;;
        "failure")
            eval "${function_name}() { echo '$mock_output' >&2; return ${mock_exit_code:-1}; }"
            ;;
        "echo")
            eval "${function_name}() { echo '$mock_output'; return $mock_exit_code; }"
            ;;
        "custom")
            eval "${function_name}() { $mock_output; }"
            ;;
        *)
            log_error "Unknown mock behavior for function: $mock_behavior"
            return 1
            ;;
    esac

    MOCKS["${function_name}:type"]="function"
    MOCKS["${function_name}:behavior"]="$mock_behavior"

    # Add to cleanup queue
    MOCK_CLEANUP_QUEUE+=("$function_name")

    log_debug "Mocked function: $function_name with behavior: $mock_behavior"
}

# Mock verification
mock_was_called() {
    local command_name="$1"
    local calls_file="${MOCKS["${command_name}:calls_file"]:-}"

    if [[ -n "$calls_file" && -f "$calls_file" ]]; then
        [[ -s "$calls_file" ]]
    else
        false
    fi
}

mock_call_count() {
    local command_name="$1"
    local calls_file="${MOCKS["${command_name}:calls_file"]:-}"

    if [[ -n "$calls_file" && -f "$calls_file" ]]; then
        wc -l < "$calls_file" | tr -d ' '
    else
        echo "0"
    fi
}

mock_was_called_with() {
    local command_name="$1"
    local expected_args="$2"
    local calls_file="${MOCKS["${command_name}:calls_file"]:-}"

    if [[ -n "$calls_file" && -f "$calls_file" ]]; then
        grep -Fxq "$expected_args" "$calls_file"
    else
        false
    fi
}

mock_get_calls() {
    local command_name="$1"
    local calls_file="${MOCKS["${command_name}:calls_file"]:-}"

    if [[ -n "$calls_file" && -f "$calls_file" ]]; then
        cat "$calls_file"
    fi
}

mock_reset() {
    local command_name="$1"
    local calls_file="${MOCKS["${command_name}:calls_file"]:-}"

    if [[ -n "$calls_file" && -f "$calls_file" ]]; then
        > "$calls_file"
        MOCK_CALL_COUNTS["$command_name"]=0
        log_debug "Reset mock calls for: $command_name"
    fi
}

# Mock cleanup
mock_restore() {
    local command_name="$1"
    local mock_script="${MOCKS["${command_name}:script"]:-}"
    local calls_file="${MOCKS["${command_name}:calls_file"]:-}"
    local original_path="${MOCKS["${command_name}:original"]:-}"
    local mock_type="${MOCKS["${command_name}:type"]:-command}"

    if [[ "$mock_type" == "function" ]]; then
        # Restore original function or unset
        local original_func="${MOCKS["${command_name}:original_func"]:-}"
        if [[ -n "$original_func" ]]; then
            eval "$original_func"
        else
            unset -f "$command_name" 2>/dev/null || true
        fi
    else
        # Remove mock script and symlink
        if [[ -n "$mock_script" && -f "$mock_script" ]]; then
            rm -f "$mock_script"
        fi

        rm -f "/tmp/$command_name"

        # Restore original PATH if needed
        # Note: This is simplified - in practice you'd want to restore the exact PATH
    fi

    # Clean up calls file
    if [[ -n "$calls_file" && -f "$calls_file" ]]; then
        rm -f "$calls_file"
    fi

    # Remove from mocks registry
    for key in "${!MOCKS[@]}"; do
        if [[ "$key" == "${command_name}:"* ]]; then
            unset MOCKS["$key"]
        fi
    done

    unset MOCK_CALL_COUNTS["$command_name"]

    log_debug "Restored mock: $command_name"
}

mock_restore_all() {
    log_debug "Restoring all mocks"

    for mock_name in "${MOCK_CLEANUP_QUEUE[@]}"; do
        mock_restore "$mock_name"
    done

    MOCK_CLEANUP_QUEUE=()
}

# Common mock presets
mock_nix_success() {
    mock_command "nix" "success" "nix command executed successfully" 0
}

mock_nix_failure() {
    mock_command "nix" "failure" "nix command failed" 1
}

mock_git_success() {
    mock_command "git" "success" "" 0
}

mock_git_failure() {
    mock_command "git" "failure" "git command failed" 1
}

mock_ssh_success() {
    mock_command "ssh" "success" "SSH connection successful" 0
}

mock_ssh_failure() {
    mock_command "ssh" "failure" "SSH connection failed" 255
}

mock_curl_success() {
    local response_body="${1:-{\"status\":\"ok\"}}"
    mock_command "curl" "echo" "$response_body" 0
}

mock_curl_failure() {
    mock_command "curl" "failure" "curl: (7) Failed to connect" 7
}

# Network service mocks
mock_http_server() {
    local port="${1:-8080}"
    local response="${2:-OK}"

    # Create a simple HTTP server mock
    cat > "/tmp/mock_http_server_$$" << EOF
#!/bin/bash
echo "HTTP/1.1 200 OK"
echo "Content-Type: text/plain"
echo "Content-Length: \${#response}"
echo ""
echo "$response"
EOF

    chmod +x "/tmp/mock_http_server_$$"

    # Start the mock server in background
    socat TCP-LISTEN:"$port",reuseaddr,fork EXEC:"/tmp/mock_http_server_$$" &
    local server_pid=$!

    MOCKS["http_server:pid"]="$server_pid"
    MOCKS["http_server:port"]="$port"
    MOCKS["http_server:script"]="/tmp/mock_http_server_$$"

    log_debug "Started mock HTTP server on port $port (PID: $server_pid)"

    # Wait a moment for server to start
    sleep 1
}

mock_http_server_stop() {
    local server_pid="${MOCKS["http_server:pid"]:-}"
    local server_script="${MOCKS["http_server:script"]:-}"

    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
        log_debug "Stopped mock HTTP server (PID: $server_pid)"
    fi

    if [[ -n "$server_script" && -f "$server_script" ]]; then
        rm -f "$server_script"
    fi

    unset MOCKS["http_server:pid"]
    unset MOCKS["http_server:port"]
    unset MOCKS["http_server:script"]
}

# Environment mocks
mock_environment() {
    local var_name="$1"
    local var_value="$2"

    # Store original value
    local original_value="${!var_name:-__UNSET__}"
    MOCKS["env:${var_name}:original"]="$original_value"

    # Set new value
    export "$var_name"="$var_value"

    # Add to cleanup queue
    MOCK_CLEANUP_QUEUE+=("env:$var_name")

    log_debug "Mocked environment variable: $var_name=$var_value"
}

mock_environment_restore() {
    local var_name="$1"
    local original_value="${MOCKS["env:${var_name}:original"]:-}"

    if [[ "$original_value" == "__UNSET__" ]]; then
        unset "$var_name"
    else
        export "$var_name"="$original_value"
    fi

    unset MOCKS["env:${var_name}:original"]
    log_debug "Restored environment variable: $var_name"
}

# File system mocks
mock_file() {
    local file_path="$1"
    local content="$2"
    local create_backup="${3:-true}"

    # Create backup if file exists
    if [[ "$create_backup" == "true" && -f "$file_path" ]]; then
        cp "$file_path" "${file_path}.mock_backup"
        MOCKS["file:${file_path}:backup"]="${file_path}.mock_backup"
    fi

    # Create directory if needed
    local dir_path
    dir_path=$(dirname "$file_path")
    mkdir -p "$dir_path"

    # Write mock content
    echo "$content" > "$file_path"

    MOCKS["file:${file_path}:mocked"]="true"
    MOCK_CLEANUP_QUEUE+=("file:$file_path")

    log_debug "Mocked file: $file_path"
}

mock_file_restore() {
    local file_path="$1"
    local backup_path="${MOCKS["file:${file_path}:backup"]:-}"

    if [[ -n "$backup_path" && -f "$backup_path" ]]; then
        mv "$backup_path" "$file_path"
        log_debug "Restored file from backup: $file_path"
    else
        rm -f "$file_path"
        log_debug "Removed mocked file: $file_path"
    fi

    unset MOCKS["file:${file_path}:backup"]
    unset MOCKS["file:${file_path}:mocked"]
}

# Cleanup handler
mocks_cleanup_handler() {
    log_debug "Running mock cleanup on exit"

    # Stop any running services
    mock_http_server_stop 2>/dev/null || true

    # Restore all mocks
    mock_restore_all

    # Clean up any remaining temp files
    rm -f /tmp/mock_*_$$* 2>/dev/null || true
}

# Register cleanup handler
trap mocks_cleanup_handler EXIT

# Functions available when sourced
