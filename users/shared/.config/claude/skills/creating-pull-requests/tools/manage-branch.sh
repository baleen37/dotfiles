#!/bin/bash
set -euo pipefail

BRANCH_NAME="${1:-}"
CURRENT_BRANCH=$(git branch --show-current)

# Only act if on main/master
if [[ "$CURRENT_BRANCH" != "main" && "$CURRENT_BRANCH" != "master" ]]; then
    echo "✅ Not on main/master branch, no branch management needed"
    exit 0
fi

echo "🌿 On $CURRENT_BRANCH branch - creating feature branch..."

# Generate branch name if not provided
if [[ -z "$BRANCH_NAME" ]]; then
    TIMESTAMP=$(date +%Y-%m-%d)
    SHORT_HASH=$(git log -1 --pretty=format:'%h')
    BRANCH_NAME="feature/$TIMESTAMP-$SHORT_HASH"
fi

# Create and checkout feature branch
git checkout -b "$BRANCH_NAME"
echo "✅ Created feature branch: $BRANCH_NAME"

# Push feature branch
git push -u origin "$BRANCH_NAME"
echo "✅ Pushed feature branch to remote"

# Main branch cleanup
echo ""
echo "🔧 Main Branch Cleanup Required"
echo "The main branch needs to be reset to clean state."
echo "This will reset main to match origin/main (removes local commits)."
echo ""
read -p "❓ Proceed with main branch cleanup? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 Cleaning up main branch..."

    # Reset main to clean state
    git checkout main
    git reset --hard origin/main
    echo "   ✓ Reset main to origin/main"

    # Return to feature branch
    git checkout "$BRANCH_NAME"
    echo "   ✓ Returned to feature branch '$BRANCH_NAME'"

    echo "✅ Main branch cleanup completed"
else
    echo "⚠️  Skipping main branch cleanup"
    echo "   Consider manually: git checkout main && git reset --hard origin/main"
fi
