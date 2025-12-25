# Baseline Test Results

## Scenario 1: New Python Project Setup

### Test Date
2025-12-25

### Agent Actions
1. Created `.pre-commit-config.yaml` with standard hooks
2. Included: pre-commit-hooks, black, ruff
3. Installed pre-commit hooks locally
4. Tested with a commit

### Critical Failures

#### ❌ No CI Workflow Created
**Expected**: Should create `.github/workflows/pre-commit.yml` or similar
**Actual**: Only local pre-commit setup, no CI at all
**Impact**: Local-CI inconsistency guaranteed - CI won't run same checks

#### ❌ No Competitive Research
**Expected**: Launch 2 subagents to research best practices competitively
**Actual**: Used "standard" configuration without research
**Impact**: Potentially outdated or suboptimal hook selection

#### ❌ Hard-coded Versions Without Verification
**Expected**: Research current best versions for 2025
**Actual**: Used specific versions (v4.5.0, 23.12.1, v0.1.9) without verification
**Evidence**:
- `pre-commit-hooks: v4.5.0` - Is this the latest?
- `black: 23.12.1` - Is this the recommended version for 2025?
- `ruff: v0.1.9` - Ruff is at 0.7+ now, this is very outdated

#### ❌ No Technology Stack Detection
**Expected**: Analyze requirements.txt to determine project needs
**Actual**: Added generic hooks without considering project specifics
**Missing**:
- mypy for type checking
- pytest hooks
- dependency checking
- Security scanning

#### ❌ No Documentation of Setup
**Expected**: Create README or document what was set up and why
**Actual**: No documentation

### Rationalizations (verbatim)

> "I need this done quickly, just use whatever is standard"

This user pressure led to:
- Skipping research
- Skipping CI setup
- Using "standard" without defining what that means

### Root Causes

1. **No awareness of local-CI consistency principle**
   - Agent doesn't know CI setup is mandatory, not optional

2. **No competitive research workflow**
   - Agent doesn't know to launch parallel subagents for better results

3. **Time pressure = quality shortcuts**
   - "Quickly" triggered shortcuts instead of systematic approach

4. **"Standard" is undefined**
   - Agent interpreted "standard" as "minimal working setup"
   - Should interpret as "best practices for this tech stack"

### What Skill Must Address

1. **MANDATORY CI setup** - Not optional, always required
2. **Competitive research workflow** - When to use, how to launch
3. **Version verification** - Always check current best versions
4. **Tech stack analysis** - Detect from project files
5. **Resist time pressure** - "Quickly" doesn't mean "skip steps"

---

## Scenario 2: Adding New Hook to Existing Config

### Test Date
2025-12-25

### Agent Actions
1. Edited `.pre-commit-config.yaml` to add ESLint hook
2. Added mirrors-eslint repo with v8.56.0
3. Configured file patterns for JS/TS files
4. That's it - nothing else

### Critical Failures

#### ❌ No Testing Before Completion
**Expected**: Run `pre-commit run --all-files` to verify hook works
**Actual**: File modified but never tested
**Evidence**: git status shows uncommitted changes, no test execution
**Impact**: Could have broken syntax, wrong config, or incompatible version

#### ❌ No CI Update Check
**Expected**: Check if CI workflow exists and needs updating
**Actual**: No CI check at all (and no CI exists)
**Impact**: Hook runs locally but not in CI

#### ❌ No Research for Best ESLint Hook Configuration
**Expected**: Research current best practices for ESLint in pre-commit
**Actual**: Used first known solution (mirrors-eslint)
**Questions not asked**:
- Is mirrors-eslint still the recommended approach in 2025?
- Should we use additional ESLint hooks (prettier, type-aware linting)?
- What ESLint arguments/flags are best practice?

#### ❌ No Dependency Version Verification
**Expected**: Verify ESLint version in hook matches package.json
**Actual**: Used v8.56.0 without checking what's actually in package.json or node_modules
**Risk**: Version mismatch between local dev and pre-commit

#### ❌ Changes Not Committed
**Expected**: Test, verify, then commit the changes
**Actual**: Left as uncommitted modifications

### Rationalizations (verbatim)

> "Quick change - just add ESLint to our pre-commit hooks"

Agent interpreted "quick" as:
- Skip testing
- Skip research
- Skip verification
- Just edit and done

### Root Causes

1. **No verification-before-completion discipline**
   - Agent doesn't know testing is mandatory, even for "quick" changes

2. **"Quick" = "skip quality steps"**
   - Time pressure language triggers shortcut mode

3. **Exhaustion context had no visible effect**
   - Added "after long conversation, tired" but agent didn't show it
   - May need stronger exhaustion pressure

4. **No awareness that changes need testing**
   - Configuration changes are code changes - must be tested

### What Skill Must Address

1. **MANDATORY testing** - `pre-commit run --all-files` before claiming done
2. **Resist "quick" pressure** - Quick done right, not quick and broken
3. **Research even for "simple" additions** - Best practices evolve
4. **Verification workflow** - Test → Verify → Commit pattern

---

## Scenario 3: Local Passes, CI Fails
(To be tested)

---

## Scenario 4: Competitive Research Comparison
(To be tested)
