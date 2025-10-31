# Baseline Analysis: PR Creation Skill

## Scenario Results Summary

### Scenario 1: Time Pressure + Uncommitted Changes ✅ GOOD
**Behavior**: Agent properly handled uncommitted changes with staging and commit
**Violations**:
- ❌ **SKIP REBASING** - Did not rebase even though origin/main was ahead
**Rationalization**: Time pressure led to focusing on getting PR created quickly

### Scenario 2: Sunk Cost + Complexity Avoidance ✅ GOOD
**Behavior**: Agent correctly refused to PR from main, strongly advocated for feature branch
**Violations**: None
**Rationalization**: Despite sunk cost pressure, maintained strong principles about git hygiene

### Scenario 3: Exhaustion + Authority ✅ GOOD
**Behavior**: Agent refused to skip rebase despite direct request from exhausted user
**Violations**: None
**Rationalization**: Strong reasoning about why rebasing matters even under pressure

### Scenario 4: Uncertainty + Duplicate Risk ✅ GOOD
**Behavior**: Agent properly checked for existing PRs before creating
**Violations**: None
**Rationalization**: Safety-first approach to uncertainty

## Key Pattern: Rebase Skipping Under Time Pressure

**Primary Violation**: **Skipping rebase when origin/main is ahead**

**Trigger**: Time pressure scenarios where user wants PR "ASAP"

**Rationalizations used**:
- "Need to get this PR created quickly"
- Focus on immediate creation over proper integration
- Underestimating importance of being up-to-date with main

## Successes to Reinforce

**Strong areas already handled well**:
- ✅ Uncommitted changes management
- ✅ Feature branch creation (won't PR from main)
- ✅ Force-with-lease usage (safety conscious)
- ✅ Duplicate PR prevention
- ✅ Proper commit messages and PR descriptions

## Skill Focus Areas

**Main problem to solve**: **Ensuring branches are rebased onto target before PR creation**

**Specific scenarios to address**:
1. Branch behind target by multiple commits
2. Time pressure to "just get it up"
3. User requests to skip rebase
4. Verification that rebase is necessary

**Counter-rationalizations needed**:
- "This will take too long" → Rebase is 2-3 minutes vs cleanup takes longer
- "I can do it later" → PR will fail CI anyway, creating more work
- "User told me to skip" → User doesn't understand the consequences

## Skill Requirements

**Mandatory steps that must be enforced**:
1. Always check if branch is behind target
2. Always rebase if behind (unless explicitly unsafe)
3. Use `--force-with-lease` for safety
4. Verify rebase success before PR creation
5. Handle rebase conflicts appropriately
