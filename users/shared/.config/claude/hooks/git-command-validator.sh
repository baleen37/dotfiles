#!/usr/bin/env bash
# Claude Code Hook: Git Command Validator
# Prevents --no-verify usage in git commands
# Reads JSON input from stdin for PreToolUse hooks

validate_git_command() {
    local command="$1"

    # Check for --no-verify in git commit commands
    if echo "$command" | grep -qE "git\s+commit.*--no-verify"; then
        echo "❌ --no-verify is not allowed in this repository" >&2
        echo "💡 Please use 'git commit' without --no-verify" >&2
        echo "🔒 All commits must pass quality checks" >&2
        return 2  # Exit code 2 blocks the tool execution
    fi

    # Check for other common bypass patterns
    if echo "$command" | grep -qE "git\s+.*skip.*hooks"; then
        echo "❌ Skipping hooks is not allowed" >&2
        return 2
    fi

    if echo "$command" | grep -qE "git\s+.*--no-.*hook"; then
        echo "❌ Hook bypass is not allowed" >&2
        return 2
    fi

    # Check for HUSKY=0 environment variable usage
    if echo "$command" | grep -qE "HUSKY=0.*git"; then
        echo "❌ HUSKY=0 bypass is not allowed" >&2
        return 2
    fi

    # Check for SKIP_HOOKS usage
    if echo "$command" | grep -qE "SKIP_HOOKS=.*git"; then
        echo "❌ SKIP_HOOKS bypass is not allowed" >&2
        return 2
    fi

    return 0
}

# Extract git command from JSON input
extract_command_from_json() {
    local json_input="$1"

    # Use grep + sed to extract command field from JSON
    echo "$json_input" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"\([^"]*\)"/\1/'
}

# Main execution
if [ $# -eq 0 ]; then
    # Read JSON from stdin (PreToolUse standard)
    json_input=$(cat)

    # Extract command from JSON
    command=$(extract_command_from_json "$json_input")

    # Validate the command if we got one
    if [ -n "$command" ]; then
        validate_git_command "$command"
        exit $?
    else
        # No command found, allow execution
        exit 0
    fi
else
    # Direct argument mode (fallback)
    command="$1"
    validate_git_command "$command"
    exit $?
fi
