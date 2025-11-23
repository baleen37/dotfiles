#!/bin/bash
set -euo pipefail

echo "🔍 Checking repository state..."

# Working directory status
echo "📁 Working directory status:"
git status --porcelain

# Recent commits
echo -e "\n📝 Recent commits:"
git log --oneline -5

# Commits analysis
echo -e "\n📊 Branch analysis:"
git fetch origin --quiet

AHEAD_COUNT=$(git log --oneline origin/main..HEAD | wc -l)
BEHIND_COUNT=$(git log --oneline HEAD..origin/main | wc -l)

echo "   Commits ahead of main: $AHEAD_COUNT"
echo "   Commits behind main: $BEHIND_COUNT"

# Current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "   Current branch: $CURRENT_BRANCH"

# Exit code based on state
if [[ -n $(git status --porcelain) ]]; then
    exit 1  # Has uncommitted changes
elif [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    exit 2  # On main branch
elif [[ $BEHIND_COUNT -gt 0 ]]; then
    exit 3  # Behind target
else
    exit 0  # Clean state
fi
