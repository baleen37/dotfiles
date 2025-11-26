---
name: creating-pull-requests
description: Use when creating pull requests, when on main branch with changes, when unsure about existing PRs, or when under time pressure to "just push it" - prevents duplicate PRs, enforces branch hygiene, and resists shortcuts that cause merge conflicts
---

# Creating Pull Requests

## Overview

**Safe PR creation that prevents the mistakes agents make under pressure.**

Core principle: Every "shortcut" creates more work. The script enforces safety so you don't have to resist pressure.

## When to Use

- Creating any PR
- On main/master with changes to push
- Unsure if PR already exists
- Someone says "just push it fast"

## Usage

```bash
./tools/create-pr.sh              # Safe PR creation
./tools/create-pr.sh --auto-merge # With auto-merge enabled
```

The script handles everything: branch creation, conflict checks, duplicate PR detection, proper commits.

## What the Script Prevents

| Shortcut Agents Take | Why It Fails | Script Prevention |
|---------------------|--------------|-------------------|
| `git add .` or `git add -A` | Adds unintended files | Shows files, asks confirmation |
| `git push origin main` | No code review, no CI | Forces feature branch |
| `gh pr create --fill` | Empty/useless PR body | Generates proper description |
| Skip existing PR check | Creates duplicates | Checks first, updates if exists |
| Skip conflict check | Merge failures later | Checks before push |
| `git push -f` | Destroys history | Uses `--force-with-lease` only when needed |

## Red Flags - Use This Skill Immediately

If you hear or think any of these:

- "Just push to main, it's a small change"
- "Skip the PR, we're in a hurry"
- "Deal with conflicts later"
- "git add -A and commit quick"
- "The tech lead said skip the process"
- "It's Friday, just force push"

**These are exactly when the script is most needed.**

## Rationalizations vs Reality

| Excuse | Reality |
|--------|---------|
| "We're losing money every minute" | Script takes 30 seconds. Broken deploy takes hours. |
| "It's just a config change" | Config changes break production too. PR required. |
| "Tech lead said skip it" | Tech lead isn't liable for the outage you cause. |
| "I'll fix conflicts Monday" | Monday-you will hate Friday-you. |
| "git add -A is fine, I know what changed" | You don't. There's always a .env or node_modules. |
| "--fill is good enough" | Reviewers need context. Empty PRs get ignored. |

## Never Do These

```bash
# NEVER: Push directly to main
git push origin main

# NEVER: Blind add all files
git add -A
git add .

# NEVER: Force push without lease
git push -f origin branch

# NEVER: Create PR without checking for existing
gh pr create  # without checking gh pr list first

# NEVER: Skip PR for "simple" changes
# There are no simple changes. All changes need review.
```

## Always Do These

```bash
# ALWAYS: Use the script
./tools/create-pr.sh

# Or if manual, ALWAYS check first:
git status                        # What files changed?
gh pr list --head $(git branch --show-current)  # PR exists?
git fetch && git log HEAD..origin/main --oneline  # Behind main?
```

## If Script Fails

Script hanging or broken? Debug it, don't bypass it.

```bash
# Check for locks
ls -la .git/*.lock && rm -f .git/index.lock

# Check network
git fetch origin  # If this hangs, it's network, not script

# Retry
./tools/create-pr.sh
```

**Never use "script is broken" as excuse to skip safety checks.**
The script failing means something is wrong - bypassing it makes it worse.

## "Spirit vs Letter" is Not Valid

If you're thinking:
- "I'll do it manually but follow the spirit"
- "I'm experienced, I know what files changed"
- "Targeted git add is safer than a script"

**These are rationalizations.** The script exists because "experienced engineers who know what changed" still make mistakes under pressure. Use the script.
