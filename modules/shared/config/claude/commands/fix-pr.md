---
name: fix-pr
description: "Fix PR conflicts and CI failures with automated resolution"
---

# /fix-pr - PR Conflict & CI Failure Resolution

**Purpose**: Automatically resolve PR conflicts, fix CI failures, and ensure PR readiness

## Usage

```bash
/fix-pr                      # Fix current PR conflicts and CI issues
/fix-pr [pr-number]          # Fix specific PR by number
```

## Execution Strategy

- **Status Assessment**: Check PR status, conflicts, and CI failures
- **Conflict Resolution**: Automated rebase and merge conflict resolution
- **CI Analysis**: Identify and fix common CI failures
- **Force Push Safety**: Use --force-with-lease for safe updates
- **Real-time Monitoring**: Watch CI progress and re-trigger if needed

## Resolution Logic

1. **Status Check**: `gh pr status && gh pr checks` - assess current state
2. **Branch Sync**: `git fetch origin main && git rebase origin/main`
3. **Conflict Resolution**: Interactive conflict resolution with file analysis
4. **CI Fix**: Analyze failures and apply common fixes
5. **Safe Push**: `git push --force-with-lease` with verification
6. **Monitoring**: `gh pr checks --watch` until success

## Common Fixes

- **Merge Conflicts**: Auto-resolve simple conflicts, guide complex ones
- **Lint Failures**: Run linters and auto-fix formatting issues
- **Test Failures**: Identify test issues and suggest fixes
- **Build Errors**: Analyze build logs and apply common solutions

## Examples

```bash
/fix-pr                      # Fix conflicts in current branch
/fix-pr 123                  # Fix specific PR #123
```
