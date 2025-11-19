---
name: creating-pull-requests
description: Use when creating pull requests - handles uncommitted changes, creates feature branches, rebases safely, prevents duplicate PRs
---

# Creating Pull Requests

**Clean PR creation from any repository state.**

Handles uncommitted changes, creates feature branches from main, rebases safely, prevents duplicate PRs.

## When to Use

- Creating PRs from any repository state
- On main/master with commits that should be in a feature branch
- Have uncommitted changes
- Branch is behind target branch
- User wants to skip safety steps

## Quick Reference

| Situation | Action |
|-----------|--------|
| Uncommitted changes | Auto-commit before PR |
| On main/master | Create feature branch first |
| Branch behind target | Rebase before PR creation |
| Force pushing needed | Use `--force-with-lease` |
| Existing PR? | Check with `gh pr view` first |

## Implementation

### Step 1: Repository Analysis

```bash
# Run these commands in parallel
git status
git log --oneline -5
git fetch origin
```

### Step 2: Handle Uncommitted Changes

```bash
if [[ -n $(git status --porcelain) ]]; then
    echo "Committing uncommitted changes..."
    git add .
    git commit -m "$(cat <<'EOF'
feat: [descriptive message]
EOF
)"
fi
```

### Step 3: Branch Management

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
    echo "Creating feature branch from $CURRENT_BRANCH..."
    FEATURE_BRANCH="feature/$(date +%Y-%m-%d)-$(git log -1 --pretty=format:'%h')"
    git checkout -b "$FEATURE_BRANCH"
    git push -u origin "$FEATURE_BRANCH"

    # Clean up main branch
    git checkout main
    git reset --hard origin/main
    git checkout "$FEATURE_BRANCH"
    echo "✅ Created feature branch and cleaned main"
fi
```

### Step 4: Rebase (Always Required)

```bash
BEHIND_COUNT=$(git log --oneline HEAD..origin/main | wc -l)
if [[ $BEHIND_COUNT -gt 0 ]]; then
    echo "Rebasing $BEHIND_COUNT commits behind main..."
    git rebase origin/main
    if [[ $? -ne 0 ]]; then
        echo "❌ Rebase conflicts. Resolve conflicts and run: git rebase --continue"
        exit 1
    fi
    git push origin "$(git branch --show-current)" --force-with-lease
else
    git push origin "$(git branch --show-current)"
fi
```

### Step 5: Create PR

```bash
# Check if PR exists
if gh pr view --json number >/dev/null 2>&1; then
    echo "ℹ️ PR already exists for this branch"
    PR_NUMBER=$(gh pr view --json number --jq '.number')
    echo "📋 Current PR: #$PR_NUMBER"
    exit 0
fi

# Create PR
PR_URL=$(gh pr create \
    --title "$(git log -1 --pretty=format:'%s')" \
    --body "$(cat <<'EOF'
## Summary
[Summary based on commits and changes]

## Changes
$(git log --oneline origin/main..HEAD | sed 's/^/- /')

## Test Plan
- [ ] Verify key functionality
- [ ] Test edge cases
- [ ] Confirm integration
EOF
)")

echo "✅ PR created: $PR_URL"
```

## Common Rationalizations vs Reality

| Excuse | Reality |
|--------|---------|
| "I'm in a hurry" | Rebase takes 2 minutes. Conflict cleanup takes 30+ minutes. |
| "Just create from main" | Blocks main branch for entire review period. |
| "I can rebase later" | PR will fail CI anyway. You'll be forced to do it under pressure. |
| "Simple change doesn't need rebase" | Simple changes still need integration testing against latest main. |
| "Manual testing is enough" | Manual testing != CI integration. PR must pass automated tests. |

## Red Flags - STOP and Use This Skill

If you catch yourself thinking:
- "Skip the rebase check"
- "Just create PR from main"
- "User is in a hurry, skip safety"
- "This is simple enough to skip verification"
- "I'll handle problems if they come up"

**Use this skill immediately.**

## Auto-Merge (Optional)

```bash
# Enable auto-merge if requested
if [[ "$1" == "--auto-merge" ]]; then
    PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]\+')
    gh pr merge "$PR_NUMBER" --auto --squash
    echo "✅ Auto-merge enabled"
fi
```
