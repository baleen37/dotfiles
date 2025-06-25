# Verify PR

Verify PR status and CI checks quickly.

## Usage
```
/project:verify-pr [pr-number]
```

Auto-detects current branch's PR if no number provided.

## Steps

1. **Find PR**: Use provided number or detect from current branch
2. **Check conflicts**: Verify mergeable status first
3. **Check CI**: Verify all checks pass (lint, smoke, build, integration)
4. **Check reviews**: Confirm approvals and ready status
5. **Report**: Provide summary

## Required for Merge
- [ ] No conflicts
- [ ] All CI checks pass
- [ ] Approved by reviewers
- [ ] Not draft status
