---
name: ci-troubleshooting
description: Use when GitHub Actions CI is broken, failing, or needs fixing - systematic approach that starts with observing actual errors before forming hypotheses, clusters failures by triggering commit, and validates fixes locally before pushing (user)
---

# CI Troubleshooting

## Overview

Fix GitHub Actions failures systematically: **Observe → Cluster → Reproduce → Fix → Validate**.

**Critical principle:** Always observe actual CI errors before guessing. 30 seconds of observation beats hours of wrong hypotheses.

**REQUIRED BACKGROUND:** You MUST understand superpowers:systematic-debugging before using this skill.

## When to Use

**Use for:** GitHub Actions build failures, test failures, dependency issues, timeouts, infrastructure problems

**Don't use for:** Local development bugs (use systematic-debugging skill instead)

## Core Workflow

```
1. OBSERVE: Get actual error from GitHub Actions (30 sec)
2. CLUSTER: Find triggering commit (30 sec)
3. REPRODUCE: Run exact failing command locally (2 min)
4. FIX: Apply minimal change
5. VALIDATE: Local → Branch → Main (no shortcuts)
```

**Start with step 1 every time.** When stuck after 3+ attempts, return to step 1.

## Step 1: Observe Actual Errors

```bash
gh run list --limit 10
gh run list --limit 10 --branch <branch-name>  # Filter by branch
gh run view <run-id> --log-failed
```

**Non-negotiable:** Takes 30 seconds, shows actual error not hypothesis, prevents "80% confident" guessing.

## Step 2: Cluster by Triggering Commit

**KEY INSIGHT: 47 test failures from 1 commit = 1 root cause, not 47 problems.**

```bash
git log --oneline -10
git show <suspect-commit>
```

If all failures started with one commit → Fix that commit, don't debug each test.

## Step 3: Reproduce Locally

Copy EXACT command from CI logs and run locally. Match CI environment if needed (`export CI=true`).

**Why BEFORE reading code:** Prevents confirmation bias.

## Step 4: Fix

Apply minimal change that fixes the root cause.

## Step 5: Validate (Three Tiers - No Shortcuts)

**Even for "simple fixes." Even under time pressure. No exceptions.**

1. **Local:** Run specific test, then full suite
2. **Branch CI:** Push to feature branch (NOT main), wait for green, return to Step 1 if fails
3. **Post-Merge:** Monitor main for 5 minutes, REVERT immediately if breaks

## When You're Stuck

**Tried 3+ things? STOP. You're guessing, not debugging.** Return to Step 1. Sunk cost is not a reason to continue.

## Quick Reference

| Symptom | First Action |
|---------|-------------|
| **Any failure** | `gh run view --log-failed` → See actual error |
| Multiple failures | Check triggering commit → Fix commit, not each test |
| Can't reproduce locally | Compare environments (env vars, versions) |
| Flaky test | Run 10+ times locally → Fix race condition |
| Timeout | Reproduce locally → Fix slowness or increase timeout |

## Red Flags - STOP

- "80% confident, let's try..." → Observe actual error first (30 sec)
- "No time for validation" → Systematic is faster (15 min vs 30+ min guessing)
- "Push directly to main" → Always use branch first
- "I've tried 5 things" → Return to Step 1, don't try #6
- "Investigate each failure" → Cluster by triggering commit first

**All steps required under all pressures. Violating the letter violates the spirit.**
