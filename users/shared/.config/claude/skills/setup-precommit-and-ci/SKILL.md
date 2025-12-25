---
name: setup-precommit-and-ci
description: Use when setting up or modifying pre-commit hooks, or when local passes but CI fails
---

# Setting Up Pre-commit and CI

## The Iron Law

```
NO PRE-COMMIT WITHOUT CI
NO CHANGES WITHOUT TESTING
```

**Core principle**: Local and CI must be consistent. If it passes locally, it must pass in CI.

## Workflow

```dot
digraph precommit_setup {
    "Detect stack" [shape=box];
    "Research agent A" [shape=box, style=dotted];
    "Research agent B" [shape=box, style=dotted];
    "Present BOTH options" [shape=box];
    "User selects" [shape=box];
    "Write configs" [shape=box];
    "Setup branch protection?" [shape=diamond];
    "Run script" [shape=box];
    "Test locally" [shape=box];
    "Passes?" [shape=diamond];
    "Fix" [shape=box];
    "Commit & verify CI" [shape=box];

    "Detect stack" -> "Research agent A";
    "Detect stack" -> "Research agent B";
    "Research agent A" -> "Present BOTH options";
    "Research agent B" -> "Present BOTH options";
    "Present BOTH options" -> "User selects";
    "User selects" -> "Write configs";
    "Write configs" -> "Setup branch protection?";
    "Setup branch protection?" -> "Run script" [label="yes"];
    "Setup branch protection?" -> "Test locally" [label="no"];
    "Run script" -> "Test locally";
    "Test locally" -> "Passes?";
    "Passes?" -> "Commit & verify CI" [label="yes"];
    "Passes?" -> "Fix" [label="no"];
    "Fix" -> "Test locally";
}
```

## Step-by-Step

### 1. Detect Tech Stack

```bash
# Check for dependency and config files
ls package.json requirements.txt pyproject.toml Cargo.toml go.mod \
   .eslintrc tsconfig.json 2>/dev/null

# Check existing setup
cat .pre-commit-config.yaml 2>/dev/null
ls .github/workflows/*.yml 2>/dev/null
```

If unclear, check source files (*.py, *.js, *.ts) or ASK USER.

### 2. MANDATORY Competitive Research

**REQUIRED for**: New setup, adding hooks, user requests

**SKIP for**: Updating hook versions (`.pre-commit-config.yaml` `rev:` fields only), removing hooks

**Process**: Launch 2 parallel subagents with Task tool, identical prompts:

```
Research best practices for pre-commit in [TECH_STACK].
You are competing with another agent.

Include:
1. Recommended hooks for 2025
2. Versions (latest stable)
3. Config best practices
4. Common pitfalls

Sources: pre-commit.com, language docs, popular repos, recent guides

Provide specific .pre-commit-config.yaml recommendations.
```

**Present both** to user - let them choose or combine.

### 3. Write Configs

**Pre-commit**: See [templates/precommit-config-template.yml](templates/precommit-config-template.yml)

**CI**: Copy [templates/ci-workflow-template.yml](templates/ci-workflow-template.yml) to `.github/workflows/pre-commit.yml`

### 4. Branch Protection (Recommended)

Run: `bash {baseDir}/scripts/setup-branch-protection.sh`
*({baseDir} is the skill directory; Claude Code resolves this automatically)*

Sets up:
- Direct push to main blocked
- CI must pass to merge
- Force push disabled

Options: `--yes` (auto-confirm), `--branch <name>`

### 5. Test Locally

```bash
pip install pre-commit  # or brew install pre-commit
pre-commit install
pre-commit run --all-files
```

**MUST pass before committing**. Fix issues, re-run until clean.

### 6. Commit & Verify

```bash
git add .pre-commit-config.yaml .github/workflows/pre-commit.yml
git commit -m "Add pre-commit with CI"
git push
```

**Watch CI run**. If CI fails but local passed → investigate inconsistency.

## Modifying Existing Setup

1. Research (for new hooks)
2. Edit config
3. Verify CI has same hooks
4. Test: `pre-commit run --all-files`
5. Commit & verify CI

## Common Mistakes

| Mistake | Why Wrong | Fix |
|---------|-----------|-----|
| "Local only, CI later" | CI never added | CI is mandatory |
| "Quick, skip test" | Breaks everyone | Always test |
| "Local works, ship it" | Env differences | Verify in CI |
| "Use standard" | Undefined, outdated | Research |
| Skip research for "simple" add | Tools evolve | Quick research |

## Red Flags - STOP

- "Quick, skip testing" → Quick done right, not quick and broken
- "CI later" → CI mandatory, period
- "Just one hook" → One hook breaks everything
- "Local works" → Local ≠ CI
- "User wants fast" → Fast = efficient, not careless
- "Ask about research" → Always launch research; user picks result, not whether to research

## Debugging: Local Passes, CI Fails

**Common causes**:
1. Different tool versions → Pin in both
2. Missing dependencies → CI needs same deps
3. File not committed → Check .gitignore
4. Environment variables → CI missing env vars

**Process**: Compare environments → Identify difference → Fix root cause → Test both

## Debugging: CI Fails - Reproduce Locally

**When CI fails**, reproduce it locally before fixing:

### 1. Check CI Failure Details

```bash
# View recent CI runs
gh run list --limit 5

# Get specific run details
gh run view <run-id>

# Download logs for analysis
gh run view <run-id> --log-failed
```

### 2. Reproduce Locally

```bash
# Clean state - remove cached results
pre-commit clean

# Run exact same checks as CI
pre-commit run --all-files

# If specific hook fails in CI, run just that hook
pre-commit run <hook-id> --all-files
```

### 3. Common Gotchas

| Issue | Symptom | Solution |
|-------|---------|----------|
| Stale cache | Local passes, CI fails on same commit | `pre-commit clean` then re-run |
| Tool version mismatch | Different errors local vs CI | Check `.pre-commit-config.yaml` versions match installed tools |
| Missing system deps | CI fails on setup | Install deps: `brew install <tool>` or `pip install <tool>` |
| Files not staged | CI sees files you don't | Check `git status`, stage necessary files |
| Environment differences | CI has different PATH/env | Check CI workflow env vars, replicate locally |

### 4. Systematic Process

```bash
# 1. Sync with remote
git fetch origin
git status

# 2. Clean pre-commit cache
pre-commit clean

# 3. Run all hooks
pre-commit run --all-files

# 4. If passes locally but CI fails
#    → Check CI logs for exact hook and error
#    → Compare tool versions: pre-commit run --verbose
#    → Check for uncommitted files affecting CI
```

**Golden Rule**: If you can't reproduce locally, CI environment differs from yours. Compare:
- Tool versions (`.pre-commit-config.yaml` vs installed)
- Python/Node/etc versions (CI workflow vs local)
- System dependencies (CI runner vs your machine)
- Environment variables (CI secrets vs local env)

## Real Impact

**Without**:
- Devs use `--no-verify`
- CI catches what local missed
- "Works on my machine"

**With**:
- Local and CI always consistent
- Developers trust hooks
- Issues caught before commit
