#!/bin/bash
set -euo pipefail

AUTO_MERGE=""
FORCE_IF_NEEDED=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-merge)
            AUTO_MERGE="yes"
            shift
            ;;
        --force-if-needed)
            FORCE_IF_NEEDED="yes"
            shift
            ;;
        *)
            echo "❌ Unknown argument: $1"
            echo "Usage: $0 [--auto-merge] [--force-if-needed]"
            exit 1
            ;;
    esac
done

# Check for existing PR
if gh pr view --json number >/dev/null 2>&1; then
    echo "ℹ️  PR already exists for this branch"
    PR_NUMBER=$(gh pr view --json number --jq '.number')
    echo "📋 Current PR: #$PR_NUMBER"

    # Auto-merge if requested
    if [[ "$AUTO_MERGE" == "yes" ]]; then
        echo "🔄 Enabling auto-merge on existing PR..."
        gh pr merge "$PR_NUMBER" --auto --squash
        echo "✅ Auto-merge enabled on PR #$PR_NUMBER"
    fi

    exit 0
fi

# Determine if force push is needed
BEHIND_COUNT=$(git log --oneline HEAD..origin/main | wc -l)
CURRENT_BRANCH=$(git branch --show-current)

# Push branch
if [[ $BEHIND_COUNT -gt 0 && "$FORCE_IF_NEEDED" == "yes" ]]; then
    echo "🔄 Force pushing with --force-with-lease..."
    git push origin "$CURRENT_BRANCH" --force-with-lease
else
    echo "📤 Pushing branch..."
    git push origin "$CURRENT_BRANCH"
fi

# Generate PR content
echo "📝 Creating pull request..."

TITLE=$(git log -1 --pretty=format:'%s')
COMMITS=$(git log --oneline origin/main..HEAD | sed 's/^/- /')

PR_BODY=$(cat <<EOF
## Summary
Automated pull request with comprehensive changes based on recent commits.

## Changes
$COMMITS

## Test Plan
- [ ] Verify changes work as expected
- [ ] Test edge cases and integration points
- [ ] Confirm CI/CD pipeline passes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)

# Create PR
PR_URL=$(gh pr create --title "$TITLE" --body "$PR_BODY")
echo "✅ PR created: $PR_URL"

# Auto-merge if requested
if [[ "$AUTO_MERGE" == "yes" ]]; then
    echo "🔄 Enabling auto-merge..."
    PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]\+')
    gh pr merge "$PR_NUMBER" --auto --squash
    echo "✅ Auto-merge enabled"
fi
