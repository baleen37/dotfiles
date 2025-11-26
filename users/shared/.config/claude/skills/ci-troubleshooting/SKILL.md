---
name: ci-troubleshooting
description: Use when CI/CD pipeline fails with build errors, test failures, dependency issues, or infrastructure problems - systematic triage with change-aware clustering and three-tier validation
---

# CI Troubleshooting

## Overview

Systematic CI failure resolution through **Observe-Reason-Plan-Act** loop. Key insight: cluster failures by triggering commit, not individual symptoms.

## When to Use

**Use for:** Build errors, test failures, dependency issues, timeouts, cross-platform failures

**Don't use for:** Local development (use systematic-debugging), feature work (use test-driven-development)

## Core Loop: Observe-Reason-Plan-Act

```
1. OBSERVE: Extract error patterns (30s)
2. REASON: Cluster by triggering commit (30s)
3. PLAN: Single targeted fix (30s)
4. ACT: Validate locally → commit → monitor
```

**Repeat until resolved.** Each cycle: 30-60 seconds.

## Phase 1: Rapid Triage (2 min)

```bash
# Get latest failure
gh run list --limit 1 --json databaseId -q '.[0].databaseId' | xargs -I{} gh run view {} --log | grep -E "(error|Error|ERROR)" -A3 -B3 | head -30
```

**Categorize:**
- **Dependency**: Package manager, version conflicts
- **Build/Test**: Compilation, assertion failures
- **Infrastructure**: Timeouts, permissions, resources
- **Cross-Platform**: Architecture differences

## Phase 2: Change-Aware Clustering

**Critical insight:** 50 test failures from 1 commit = 1 root cause.

```bash
# Find triggering commit
git log --oneline -10
git diff HEAD~1 --stat  # What changed?
```

**Don't:** Investigate each failure individually.
**Do:** Find common ancestor commit, fix there.

## Phase 3: Resolution Patterns

### Dependency/Cache
```bash
rm -rf node_modules package-lock.json && npm install
# or: make clean && make build
```

### Build/Test Failures
1. Reproduce locally with exact command from CI
2. Apply minimal fix
3. Validate: `make test` or equivalent

### Infrastructure
```bash
# Check resource constraints in CI logs
grep -E "(timeout|memory|disk|permission)" ci.log -A5
```

**Common fixes:** Increase timeout, add retry, check token permissions

## Phase 4: Three-Tier Validation

1. **Local**: Run exact failing command
2. **Edge cases**: Test related functionality
3. **Monitor**: Watch CI after push

## Commit Template

```bash
git commit -m "fix: <issue> - resolves CI failure

Root cause: <one line>
Validation: local ✓"
```

## Red Flags - STOP

- "Just a simple fix" → Complex interactions exist
- "It worked locally" → Environment differences matter
- "No time for process" → You're about to make it worse
- Multiple fixes at once → One change at a time

**Violating the letter of the rules is violating the spirit of the rules.**

## Quick Reference

| Failure Type | First Action | Typical Fix |
|--------------|--------------|-------------|
| Dependency | Clear cache | `rm -rf node_modules && npm i` |
| Test | Reproduce locally | Fix failing assertion |
| Timeout | Check resources | Increase limit or optimize |
| Permission | Check tokens | Update secrets/permissions |
| Cross-platform | Check CI matrix | Platform-specific fix |

## Common Mistakes

| Mistake | Prevention |
|---------|------------|
| Reading full logs | grep for errors only |
| Multiple fixes | One change at a time |
| Skip local validation | Always reproduce first |
| No rollback plan | Know your revert command |
