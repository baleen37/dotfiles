#!/bin/bash
set -euo pipefail

COMMIT_MSG="${1:-}"

if [[ -z $(git status --porcelain) ]]; then
    echo "✅ No uncommitted changes found"
    exit 0
fi

echo "📝 Found uncommitted changes - auto-committing..."

# Stage all changes
git add .

# Generate commit message if not provided
if [[ -z "$COMMIT_MSG" ]]; then
    # Analyze changes for message
    CHANGED_FILES=$(git diff --cached --name-only)

    if echo "$CHANGED_FILES" | grep -q "\.nix$"; then
        TYPE="feat"
        SCOPE="nix"
    elif echo "$CHANGED_FILES" | grep -q "\.sh$"; then
        TYPE="feat"
        SCOPE="scripts"
    elif echo "$CHANGED_FILES" | grep -E "\.(md|rst)$"; then
        TYPE="docs"
        SCOPE="documentation"
    else
        TYPE="feat"
        SCOPE="updates"
    fi

    # Match recent commit style
    RECENT_STYLE=$(git log -1 --pretty=format:'%s' 2>/dev/null || echo "feat: changes")
    COMMIT_MSG="$TYPE($SCOPE): automated commit of pending changes"
fi

# Commit with attribution
git commit -m "$COMMIT_MSG

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

echo "✅ Changes committed successfully"
