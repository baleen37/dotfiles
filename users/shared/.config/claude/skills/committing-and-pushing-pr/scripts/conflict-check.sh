#!/usr/bin/env bash
# Check for merge conflicts before pushing

set -euo pipefail

# Get base branch from remote
BASE=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "main")

echo "# Checking for merge conflicts with $BASE"

# Fetch latest base branch
echo "Fetching latest $BASE..."
git fetch origin "$BASE" 2>/dev/null || true

# Check for conflicts without merging
echo
echo "# Merge conflict check"
CONFLICTS=$(git merge-tree "$(git merge-base HEAD "origin/$BASE")" HEAD "origin/$BASE" 2>&1 || true)

if [ -z "$CONFLICTS" ]; then
    echo "✓ No merge conflicts detected"
    echo
    echo "BASE=$BASE"
    exit 0
else
    echo "✗ Merge conflicts detected!"
    echo
    echo "Conflicted files:"
    echo "$CONFLICTS" | grep "CONFLICT" | sed 's/CONFLICT.*: //' || echo "$CONFLICTS"
    echo
    echo "Please resolve conflicts before pushing."
    echo "See CONFLICT_RESOLUTION.md for detailed guide."
    exit 1
fi
