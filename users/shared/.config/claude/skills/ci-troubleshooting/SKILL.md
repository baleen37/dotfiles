---
name: ci-troubleshooting
description: Use when CI/CD pipeline fails - systematic approach that starts with observing actual errors before forming hypotheses, clusters failures by triggering commit, and validates fixes locally before pushing
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
# Get actual error from latest run
gh run list --limit 1 --json databaseId -q '.[0].databaseId' | \
  xargs -I{} gh run view {} --log | \
  grep -E "(error|Error|ERROR|FAIL)" -A3 -B3 | head -30
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

**Key insight:** 47 test failures from 1 commit = 1 root cause to fix.

```bash
# Find when it broke
git log --oneline -10

# See what changed
git diff <suspect-commit>~1 <suspect-commit> --stat
```

**Red Flag:** "Let me investigate each failure individually"

**Reality:** If failures started with one commit, fix that commit. Don't debug 47 tests separately.

## Step 3: Reproduce Locally

**Before reading code or logs, run the failing test:**

```bash
# Copy EXACT command from CI logs
npm test -- --testNamePattern="failing test name"
# or: pytest tests/path/test_file.py::test_name -v
# or: make test TEST=specific_test
```

**Why this is fastest:**
- Confirms you can reproduce
- Shows exact error in your terminal
- Enables iterative debugging
- No guessing

**Red Flag:** "Let me read the code first"

**Reality:** Running the test shows exactly where it fails.

## Step 4: Fix

Apply minimal change that fixes the root cause you identified.

**Common fixes by category:**

```bash
# Dependency issues
rm -rf node_modules package-lock.json && npm install

# Build issues
make clean && make build

# Infrastructure
# Check CI logs for resource constraints
grep -E "(timeout|memory|permission)" ci.log -A5
```

## Step 5: Validate (Three Tiers - No Shortcuts)

**Even for "simple fixes." Even under time pressure. No exceptions.**

### Tier 1: Local (before pushing)

```bash
# Run the specific failing test
make test TEST_NAME=failing_test

# Run full suite to catch regressions
make test-all
```

**Red Flag:** "It's a simple fix, skip local validation"

**Reality:** Simple fixes still need validation.

### Tier 2: Branch CI (before merging)

```bash
# Push to feature branch (NOT main)
git push origin fix/ci-issue

# Watch CI run
gh run watch
```

**Red Flag:** "Push directly to main to save time"

**Reality:** Broken main blocks entire team.

Wait for green checkmark. If it fails, return to Step 1.

### Tier 3: Post-Merge Monitoring

```bash
# Watch main CI after merge
gh run list --branch main --limit 1

# Monitor first 5 minutes
# If main breaks: REVERT immediately, then re-investigate on branch
```

## When You're Stuck

**Tried 3+ things without finding root cause?**

**STOP. You're guessing, not debugging.**

1. Acknowledge: "I've been fixing symptoms, not root cause"
2. Reset: Return to Step 1 (observe actual errors)
3. Don't: Try thing #6 based on earlier wrong hypothesis

**Sunk cost fallacy:** "I've spent 3 hours" is not a reason to continue wrong approach.

## Handling Pressure

### Authority: "Senior Dev Says Just Fix It Quickly"

**Professional response:**
```
"I want to run a 2-minute triage since the failure started with my commit.
If I don't find anything obvious, I'll go with your suggestion.
Want to make sure I'm not masking a real bug."
```

Then run Steps 1-3 (takes 3 minutes total).

### Time Pressure: "Prod Deploy in 30 Minutes"

**Red Flag:** "No time for process"

**Reality:** Systematic approach is faster than guessing.

**Breakdown:**
- Step 1 (observe): 30 seconds
- Step 2 (cluster): 30 seconds
- Step 3 (reproduce): 2 minutes
- Step 4 (fix + local test): 5-10 minutes
- Step 5 (branch CI): 5 minutes

**Total: ~15 minutes with confidence vs 30+ minutes of trial and error**

## Quick Reference

| Symptom | First Action | Common Fix |
|---------|-------------|------------|
| **Any failure** | **Step 1: grep command** | **See actual error first** |
| Test passes on retry | Re-run 3-5 times locally | Likely flaky test (separate issue) |
| Can't reproduce locally | Retry in CI (3x) | Likely transient |
| Consistent failure | Reproduce with exact CI command | Fix the specific test/build |
| Package errors | Clear cache | `rm -rf node_modules && npm i` |
| Timeout | Reproduce locally first | Fix slowness, don't just increase timeout |

## Red Flags - STOP

- "80% confident, let's try..." → Observe actual error first
- "No time for validation" → Validation prevents bigger time loss
- "Push directly to main" → Always use branch first
- "Skip local testing" → Reproduce locally before pushing
- "I've tried 5 things" → Return to Step 1, don't try #6
- "Investigate each failure" → Cluster by triggering commit
- "Let me read code first" → Run the failing test first

**Violating the letter of the rules is violating the spirit of the rules.**

## Process Checklist

Use TodoWrite to track:

- [ ] Step 1: Run grep command, see actual CI error
- [ ] Step 1: Categorize error type
- [ ] Step 2: Find triggering commit
- [ ] Step 2: Check what changed in that commit
- [ ] Step 3: Reproduce locally with exact CI command
- [ ] Step 4: Apply minimal fix
- [ ] Step 5: Validate locally (full test suite passes)
- [ ] Step 5: Push to branch, watch CI until green
- [ ] Step 5: Merge to main, monitor for 5 minutes

**All steps required. No shortcuts under pressure.**
