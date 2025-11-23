#!/bin/bash
set -euo pipefail

TARGET_BRANCH="${1:-origin/main}"

# Check if rebase is needed
BEHIND_COUNT=$(git log --oneline HEAD.."$TARGET_BRANCH" | wc -l)

if [[ $BEHIND_COUNT -eq 0 ]]; then
    echo "✅ Branch is up to date with $TARGET_BRANCH - no rebase needed"
    exit 0
fi

echo "🔄 Branch is $BEHIND_COUNT commits behind $TARGET_BRANCH - rebasing is MANDATORY..."

# Conflict risk assessment
BASE_COMMIT=$(git merge-base HEAD "$TARGET_BRANCH")
CONFLICT_FILES=$(git diff --name-only "$BASE_COMMIT..HEAD" "$BASE_COMMIT..$TARGET_BRANCH" | sort | uniq -d)

if [[ -n "$CONFLICT_FILES" ]]; then
    echo "⚠️  Potential conflict files detected:"
    echo "$CONFLICT_FILES" | sed 's/^/   - /'
    echo ""
fi

# Perform rebase
echo "🔄 Performing rebase..."
if ! git rebase "$TARGET_BRANCH"; then
    echo ""
    echo "❌ Rebase conflicts detected!"
    echo ""
    echo "🔧 Conflict Resolution Steps:"
    echo "1. Resolve conflicts in the listed files"
    echo "2. Stage resolved files: git add ."
    echo "3. Continue rebase: git rebase --continue"
    echo "4. If stuck: git rebase --abort and start over"
    echo ""
    echo "💡 Tip: Use 'git status' to see conflicting files"
    exit 1
fi

echo "✅ Rebase completed successfully"
