---
name: ci-troubleshooting
description: Use when CI is broken, failing, or needs fixing - systematic approach that starts with observing actual errors before forming hypotheses, clusters failures by triggering commit, and validates fixes locally before pushing (user)
---

# CI Troubleshooting

## Overview

Fix CI failures systematically: **Observe actual errors → Cluster by commit → Reproduce locally → Fix → Validate**.

**Critical principle:** Always observe actual CI errors before guessing. 30 seconds of observation beats hours of wrong hypotheses.

## When to Use

**Use for:** Build failures, test failures, dependency issues, CI timeouts

**Don't use for:** Local development bugs (use systematic-debugging skill instead)

## Core Workflow

```
1. OBSERVE: Get actual error from CI (30 sec)
2. CLUSTER: Find triggering commit (30 sec)
3. REPRODUCE: Run exact failing command locally (2 min)
4. FIX: Apply minimal change
5. VALIDATE: Local → Branch → Main (no shortcuts)
```

**Start with step 1 every time.** When stuck after 3+ attempts, return to step 1.

## Step 1: Observe Actual Errors

**First action for ANY CI failure:**

```bash
# Get the latest failed run and show error logs
gh run list --limit 20 --json databaseId,conclusion -q '.[] | select(.conclusion=="failure") | .databaseId' | head -1 | xargs -I{} gh run view {} --log | grep -E "(error|Error|ERROR|FAIL|failed)" -A3 -B3 | head -50
```

**If no failures found, check in-progress or all runs:**
```bash
# List recent runs to manually inspect
gh run list --limit 10

# View specific run logs (use run number from list above)
gh run view <run-number> --log
```

**For specific job failures:**
```bash
# View run summary to see which jobs failed
gh run view <run-number>

# Then check logs for errors
gh run view <run-number> --log | grep -E "(error|Error|ERROR|FAIL)" -A5 -B2
```

**This is non-negotiable:**
- Takes 30 seconds
- Shows actual error, not your hypothesis
- Prevents "80% confident" guessing

**Categorize what you see:**
- **Dependency**: Missing packages, version conflicts
- **Build/Test**: Compilation errors, assertion failures
- **Infrastructure**: Timeouts, permissions, resources
- **Platform**: Works locally, fails in CI (OS/arch differences)

## Step 2: Cluster by Triggering Commit

**THE KEY INSIGHT: 47 test failures from 1 commit = 1 root cause, not 47 problems.**

This is the fastest path to resolution. Multiple failures appearing together means clustering by **when they started**, not what they say.

```bash
# Find when it broke
git log --oneline -10

# See what changed in the triggering commit
git diff <suspect-commit>~1 <suspect-commit> --stat
git show <suspect-commit>
```

**If all failures started with one commit → Fix that commit, don't debug each test.**

## Step 3: Reproduce Locally

**Before reading code or logs, run the failing test:**

```bash
# Copy EXACT command from CI logs and run it locally
pytest tests/path/test_file.py::test_name -v
npm test -- --testNamePattern="failing test name"
cargo test test_name
<project test command>
```

**Why:** Confirms you can reproduce, shows exact error, enables iterative debugging.

## Step 4: Fix

Apply minimal change that fixes the root cause you identified.

**Common patterns:**
- Dependency: Clear cache, reinstall dependencies
- Build: Clean build artifacts, rebuild
- Infrastructure: Check logs for timeout/memory/permission errors

## Step 5: Validate (Three Tiers - No Shortcuts)

**Even for "simple fixes." Even under time pressure. No exceptions.**

### Tier 1: Local
Run specific test, then full suite to catch regressions.

### Tier 2: Branch CI
Push to feature branch (NOT main). Watch CI. Wait for green. If fails, return to Step 1.

### Tier 3: Post-Merge
Monitor main CI for 5 minutes. If breaks: REVERT immediately, re-investigate on branch.

## When You're Stuck

**Tried 3+ things? STOP. You're guessing, not debugging.**

Return to Step 1. Don't try thing #6. Sunk cost is not a reason to continue wrong approach.

## Quick Reference

| Symptom | First Action | Common Fix |
|---------|-------------|------------|
| **Any failure** | **Step 1: grep command** | **See actual error first** |
| Test passes on retry | Re-run 3-5 times locally | Likely flaky test (separate issue) |
| Can't reproduce locally | Retry in CI (3x) | Likely transient |
| Consistent failure | Reproduce with exact CI command | Fix the specific test/build |
| Package errors | Clear cache | Clear dependency cache and reinstall |
| Timeout | Reproduce locally first | Fix slowness, don't just increase timeout |

## Red Flags - STOP

- "80% confident, let's try..." → Observe actual error first (30 sec)
- "No time for validation" → Systematic is faster: 15 min vs 30+ min guessing
- "Senior dev says just do X" → Run Steps 1-3 first (3 min triage)
- "Push directly to main" → Always use branch first
- "Skip local testing" → Reproduce locally before pushing
- "I've tried 5 things" → Return to Step 1, don't try #6
- "Investigate each failure" → Cluster by triggering commit first
- "Let me read code first" → Run the failing test first

**All steps required under all pressures. Violating the letter violates the spirit.**
