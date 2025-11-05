#!/usr/bin/env bash
# Claude Code Hook: Git Command Validator
# Prevents --no-verify usage in git commands

validate_git_command() {
    local command="$1"

    # Check for --no-verify in git commit commands
    if echo "$command" | grep -qE "git\s+commit.*--no-verify"; then
        echo "❌ --no-verify is not allowed in this repository" >&2
        echo "💡 Please use 'git commit' without --no-verify" >&2
        echo "🔒 All commits must pass quality checks" >&2
        return 1
    fi

    # Check for other common bypass patterns
    if echo "$command" | grep -qE "git\s+.*skip.*hooks"; then
        echo "❌ Skipping hooks is not allowed" >&2
        return 1
    fi

    if echo "$command" | grep -qE "git\s+.*--no-.*hook"; then
        echo "❌ Hook bypass is not allowed" >&2
        return 1
    fi

    # Check for HUSKY=0 environment variable usage
    if echo "$command" | grep -qE "HUSKY=0.*git"; then
        echo "❌ HUSKY=0 bypass is not allowed" >&2
        return 1
    fi

    # Check for SKIP_HOOKS usage
    if echo "$command" | grep -qE "SKIP_HOOKS=.*git"; then
        echo "❌ SKIP_HOOKS bypass is not allowed" >&2
        return 1
    fi

    return 0
}

# Main execution
if [ $# -eq 0 ]; then
    # No arguments - likely called incorrectly
    exit 0
fi

# Read command from argument or stdin
if [ -n "$1" ]; then
    command="$1"
else
    # Read from stdin if no argument provided
    command="$(cat)"
fi

# Validate the command
validate_git_command "$command"
