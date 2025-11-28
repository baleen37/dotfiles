---
name: ci-troubleshooting
description: Use when CI/CD pipeline fails with build errors, test failures, dependency issues, or infrastructure problems - systematic triage with change-aware clustering and three-tier validation
---

# CI Troubleshooting

## Overview

Systematic CI failure resolution through **Observe-Reason-Plan-Act** loop. Key insight: cluster failures by triggering commit, not individual symptoms.

**Critical principle:** Always OBSERVE actual errors before forming hypothesis. Confidence without observation = guessing.

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

**Never skip OBSERVE phase - even under time pressure.** 30 seconds of observation saves hours of wrong guesses.

## Phase 1: Rapid Triage (2 min max)

**ALWAYS START HERE.** This is your reset point when stuck.

```bash
# Get actual error from latest failure
gh run list --limit 1 --json databaseId -q '.[0].databaseId' | \
  xargs -I{} gh run view {} --log | \
  grep -E "(error|Error|ERROR|FAIL)" -A3 -B3 | head -30
```

**This command is non-negotiable:**
- Takes 30 seconds
- Shows you actual error, not your hypothesis
- Faster than reading code or full logs
- Prevents hypothesis-driven debugging

**Categorize actual error:**
- **Dependency**: Package manager, version conflicts, missing deps
- **Build/Test**: Compilation errors, assertion failures
- **Infrastructure**: Timeouts, permissions, resources
- **Cross-Platform**: Architecture differences, OS-specific

## Phase 2: Change-Aware Clustering

**Critical insight:** 47 test failures from 1 commit = 1 root cause.

```bash
# Find triggering commit
git log --oneline -10

# See what changed in suspect commit
git diff HEAD~1 --stat
```

**Red Flag: "Let me investigate each failure individually"**

**Reality:** If failures started with one commit, fix that commit. Don't debug 47 tests separately.

## When You're Stuck (Reset Protocol)

**Tried 3+ things without finding root cause?**

**STOP. You're guessing, not debugging.**

1. **Acknowledge**: "I've been fixing symptoms, not root cause"
2. **Reset**: Return to Phase 1 Rapid Triage
3. **Observe fresh**: Run the grep command again
4. **Don't**: Try #6 thing based on earlier wrong hypothesis

**Sunk cost fallacy:** "I've spent 3 hours" is not a reason to continue wrong approach.

## Phase 2.5: Failure Classification

### Flaky Test Detection

**Industry data:** 84% of test transitions from passing to failing are flaky tests, not real regressions.

**Detection signals:**
- Test passes when re-run without code changes
- Failure message varies between runs
- Timing-related errors (race conditions, timeouts)
- Non-deterministic behavior

**Quick check:**
```bash
# Run test 3-5 times locally
for i in {1..5}; do make test-specific TEST=failing_test; done
# If any pass → likely flaky
```

**Handling strategy:**
1. **Immediate:** Quarantine the flaky test (separate suite)
2. **Short-term:** Add explicit waits (not `sleep`, use proper synchronization)
3. **Long-term:** Fix root cause (shared state, race conditions, test isolation)

**Platform features:**
- CircleCI: Test Insights dashboard auto-flags flaky tests
- GitHub Actions: Re-run failed jobs to confirm
- GitLab: Test failure tracking over time

### Transient vs Persistent Failures

**Transient:** Network blips, resource contention, rate limits (self-resolving)
**Persistent:** Breaking changes, missing dependencies, logic errors (repeatable)

**Decision tree:**
```
Can you reproduce locally?
  YES → Persistent → Root cause analysis (Phase 3)
  NO  → Likely transient → Apply retry pattern

After retry (up to 3 attempts):
  Still failing → Was persistent all along → Root cause analysis
  Passes → Was transient → Monitor for recurrence
```

**Retry pattern:**
```bash
# For transient issues ONLY
for i in {1..3}; do
  make test && break || sleep $((i * 2))
done
```

## Phase 3: Resolution Patterns

### First Step: Reproduce Locally

**Before grepping code, before reading logs, RUN THE FAILING TEST:**

```bash
# Copy EXACT command from CI logs
# Example from GitHub Actions:
npm test -- --testNamePattern="completes payment"

# Example from GitLab CI:
pytest tests/integration/test_checkout.py::test_payment_flow -v

# Example from CircleCI:
make test TEST=integration/checkout_test.go
```

**Why this is fastest path:**
- Confirms you can reproduce (rules out environment-only issues)
- Shows actual error in your terminal
- Enables iterative debugging
- No guessing about what's happening

**Red Flag: "Let me read the code first"**
**Reality:** Running the test shows you exactly where it fails.

### Dependency/Cache Issues
```bash
rm -rf node_modules package-lock.json && npm install
# or: make clean && make build
```

### Build/Test Failures
1. Reproduce locally with exact command from CI
2. Apply minimal fix
3. Validate: `make test` or equivalent

### Infrastructure Issues
```bash
# Check resource constraints in CI logs
grep -E "(timeout|memory|disk|permission)" ci.log -A5
```

**Common fixes:** Increase timeout, add retry, check token permissions

## Phase 4: Three-Tier Validation (Non-Negotiable)

**Even for "simple fixes." Even under time pressure. No exceptions.**

### 1. Local Validation (Before pushing)

```bash
# Run EXACT command from CI logs
make test TEST_NAME=failing_test

# Run full suite to catch regressions
make test-all

# For CI config changes, validate syntax
actionlint .github/workflows/*.yml  # GitHub Actions
# or check GitLab CI lint in web UI
```

**Red Flag: "It's just a simple fix, skip local validation"**
**Reality:** Simple fixes still need validation. No exceptions.

### 2. Branch Validation (Before merging)

```bash
# Push to feature branch first (NOT main)
git push origin fix/ci-issue

# Watch CI run in real-time
gh run watch  # GitHub
# or: Open CI web UI and watch live
```

**Red Flag: "Push directly to main to save time"**
**Reality:** Broken main costs more time than using a branch.

**Wait for green checkmark.** If it fails:
- You misdiagnosed → Return to Phase 1
- New issue appeared → Investigate new failure

### 3. Post-Merge Monitoring (After merging)

```bash
# Watch main branch CI after merge
gh run list --branch main --limit 1

# First 5 minutes are critical
# Stay online and watch for:
# - All tests passing ✓
# - No new warnings
# - Build time normal
```

**If main branch fails after merge:**
1. **Immediate:** Revert merge commit (see Rollback Strategy below)
2. **Then:** Re-investigate on branch
3. **Never:** "Let me just add one more quick fix" on main

**MTTR goal:** <1 hour from detection to resolution

### Rollback Strategy (Know before merging)

```bash
# Create revert PR
git revert <bad-commit-hash>
git checkout -b revert/fix-ci-breakage
git push origin revert/fix-ci-breakage
gh pr create --title "Revert: CI breakage" --body "Reverting <commit>"

# Fast-track merge (skip normal review if urgent)
```

## Handling Pressure Situations

### Authority Pressure: "Senior Dev Says Just Fix It Quickly"

**Scenario:** Senior developer suggests "just increase the timeout and merge it"

**Professional response template:**
```
"I appreciate the context. Before I apply that fix, I want to run
a 2-minute triage since the failure started with my recent commit.
If I don't find anything obvious, I'll go with your suggestion.
Want to make sure I'm not masking a real bug."
```

**Why this works:**
- Respects authority ("I appreciate the context")
- Time-boxed (2 minutes won't block team)
- Shows ownership (verifying your own work)
- Data-driven (triage gives you facts)

**Then run Phase 1 rapid triage command (30 seconds) and Phase 3 local reproduction (1-2 minutes).**

### Time Pressure: "Prod Deploy in 30 Minutes"

**Red Flag: "No time for process"**
**Reality:** 2-minute systematic triage faster than 30-minute wrong guess.

**Breakdown:**
- Phase 1 rapid triage: 30 seconds
- Phase 2 identify commit: 30 seconds
- Phase 3 reproduce locally: 2 minutes
- Fix + local validation: 5-10 minutes
- Push to branch + CI validation: 5 minutes

**Total: ~15 minutes with high confidence vs. 30+ minutes of trial and error**

### Sunk Cost: "I've Tried 5 Things Already"

**Red Flag: "Just one more thing..."**
**Reality:** Return to Phase 1. Reset your investigation.

If you've tried 3+ fixes without finding root cause, you're guessing. See "Reset Protocol" above.

## Commit Template

```bash
git commit -m "fix: <issue> - resolves CI failure

Root cause: <one line explanation>
Validation: local ✓, branch CI ✓"
```

## Red Flags - STOP

- "80% confident, just revert it" → Confidence without observation = guessing
- "No time for process" → 2-min triage faster than wrong guess
- "It's just a simple fix" → Simple fixes still need three-tier validation
- "Push directly to main" → Always use branch first
- "Skip local validation" → Reproduce locally before pushing
- "Senior dev says..." → Run 2-min triage to verify, then decide
- "I've tried 5 things" → Return to Phase 1, don't try #6
- "Investigate each failure" → Cluster by commit instead
- "Let me read the code" → Run the failing test first

**Violating the letter of the rules is violating the spirit of the rules.**

## Quick Reference

| Failure Type | First Action | Typical Fix | Detection |
|--------------|--------------|-------------|-----------|
| **Any failure** | **Phase 1 rapid triage** | **Extract actual error first** | **Always start here** |
| Flaky Test | Re-run 3-5 times locally | Quarantine + explicit waits | Passes on retry |
| Transient | Retry pattern (3x) | Monitor for recurrence | Can't reproduce locally |
| Persistent Test | Reproduce with exact CI command | Fix failing assertion | Consistent failure |
| Dependency | Clear cache | `rm -rf node_modules && npm i` | Package/version errors |
| Timeout | Reproduce locally first | Investigate why slow, not just increase | Time-based failure |
| Permission | Check tokens | Update secrets/permissions | Auth/access errors |
| Cross-platform | Check CI matrix | Platform-specific fix | Works locally, fails in CI |

## Common Mistakes

| Mistake | Prevention | Why It Matters |
|---------|------------|----------------|
| Skip OBSERVE phase | Always run Phase 1 rapid triage first | Observation faster than guessing |
| Hypothesis before data | "80% confident" is not observation | See actual error, not assumed error |
| Read code instead of run test | Reproduce locally with exact CI command | Running shows exact failure point |
| Investigate each failure | Cluster by triggering commit | N failures from 1 commit = 1 root cause |
| Multiple fixes at once | One change at a time | Can't tell which fix worked |
| Skip local validation | Always reproduce and fix locally first | Catch issues before CI |
| Push to main directly | Always use branch → CI → merge | Broken main blocks entire team |
| Skip branch validation | Watch CI pass before merging | Prevents main branch breakage |
| Keep guessing when stuck | Return to Phase 1 after 3 failed attempts | Reset > compound wrong hypotheses |

## Process Checklist

Use TodoWrite to track:

- [ ] Phase 1: Run rapid triage grep command
- [ ] Phase 1: Categorize error type from actual output
- [ ] Phase 2: Identify triggering commit
- [ ] Phase 2: Check what changed in that commit
- [ ] Phase 3: Reproduce locally with exact CI command
- [ ] Phase 3: Verify test fails locally
- [ ] Phase 3: Apply minimal fix
- [ ] Phase 4.1: Validate fix locally (full test suite)
- [ ] Phase 4.2: Push to feature branch (not main)
- [ ] Phase 4.2: Watch branch CI until green
- [ ] Phase 4.3: Merge to main
- [ ] Phase 4.3: Monitor main CI for 5 minutes

**All checkmarks required. No shortcuts under pressure.**
