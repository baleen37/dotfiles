# Check CI

Command to monitor CI status, diagnose failures, and automatically fix common issues to get CI passing.

## Purpose
The primary goal is to **get your CI green** by:
1. Monitoring CI status in real-time
2. Identifying why CI is failing
3. Automatically fixing common issues
4. Re-running CI until all checks pass

## Usage
```
/project:check-ci [pr-number]
```

If no PR number is provided, automatically finds and checks the CI for the current branch's PR.

## Core Workflow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Find PR &  │ --> │   Monitor   │ --> │   Analyze   │
│ Check Status│     │ CI Progress │     │  Failures   │
└─────────────┘     └─────────────┘     └─────────────┘
                            │                    │
                            v                    v
                    ┌─────────────┐     ┌─────────────┐
                    │ All Passed? │ Yes │    Done!    │
                    │             │ --> │  CI Green!  │
                    └─────────────┘     └─────────────┘
                            │ No
                            v
                    ┌─────────────┐     ┌─────────────┐
                    │  Auto-Fix   │ --> │   Re-run    │
                    │   Issues    │     │     CI      │
                    └─────────────┘     └─────────────┘
                            │                    │
                            └────────────────────┘
```

## Execution Steps

1. **Find and Validate PR**:
   ```bash
   # Get current branch's PR or use provided PR number
   gh pr view [pr-number] --json state,isDraft,mergeable
   ```

2. **Initial CI Status Check**:
   ```bash
   # Get all checks status
   gh pr checks <pr-number>
   ```

3. **Monitor Until Completion or Failure**:
   - Poll every 30 seconds
   - Track each job's progress
   - Early exit on critical failures

4. **On Failure - Diagnose Root Cause**:
   ```bash
   # Get failed job logs
   gh run view <run-id> --log-failed
   # Extract error patterns
   # Match against known failure types
   ```

5. **Apply Automatic Fixes**:
   - Format code if linting failed
   - Fix dependencies if build failed
   - Update branch if behind main
   - Clear caches if corrupted

6. **Push Fixes and Re-trigger CI**:
   ```bash
   git add . && git commit -m "fix: resolve CI failures"
   git push
   ```

7. **Loop Until Success or Manual Intervention Needed**

## Auto-Resolution Strategies

### Philosophy: Fix First, Ask Later
The command aggressively attempts to fix CI issues automatically:
- If linting fails → Run all formatters/linters with fix flags
- If tests fail → Check for common issues and fix
- If build fails → Clean caches and reinstall dependencies
- If merge conflicts → Rebase or merge from main

### Failure Detection and Resolution Matrix

| Failure Type | Detection Pattern | Automatic Fix | Success Rate |
|--------------|------------------|---------------|-------------|
| **Linting/Formatting** | Code style errors, formatting issues | Run formatter with fix flag | ~95% |
| **Type Errors** | Type checking failures | Fix obvious type issues | ~60% |
| **Test Failures** | Test runner exit codes | Re-run flaky tests, fix snapshots | ~70% |
| **Build Errors** | Compilation/bundling failures | Clean & rebuild, fix dependencies | ~80% |
| **Dependency Issues** | Security warnings, missing packages | Update deps, regenerate lock files | ~85% |
| **Merge Conflicts** | GitHub API mergeable=false | Rebase or merge from main | ~90% |
| **CI Config Errors** | Workflow syntax errors | Fix YAML syntax, validate config | ~75% |
| **Environment Issues** | Missing env vars, secrets | Detect from logs, prompt for values | ~50% |

### Detailed Resolution Flows

#### 1. Linting/Formatting Failures
```bash
# Detect common formatting/linting error patterns
if grep -qE "format|lint|style|indent|whitespace" <<< "$error_log"; then
  echo "🔧 Detected code style issues"

  # Try to find and run format/lint fix commands from:
  # - CI configuration files
  # - Build scripts (Makefile, package.json, etc.)
  # - Pre-commit hooks

  # Generic approach:
  # 1. Look for common fix commands in project files
  # 2. Run them in order of likelihood
  # 3. Stage and commit any changes
fi
```

#### 2. Test Failures
```bash
# Detect test failure patterns
if grep -qE "test.*fail|fail.*test|assertion|expect" <<< "$error_log"; then
  echo "🔧 Detected test failures"

  # Common test fix strategies:
  # - Re-run tests (for flaky tests)
  # - Update test snapshots/fixtures
  # - Run tests with different flags
  # - Isolate and run specific failing tests
fi
```

#### 3. Build/Dependency Failures
```bash
# Detect dependency or build issues
if grep -qE "cannot find|not found|missing|dependency|module|package" <<< "$error_log"; then
  echo "🔧 Detected dependency issues"

  # Generic dependency fixes:
  # - Clean and reinstall dependencies
  # - Clear build caches
  # - Update lock files
  # - Check for private registry issues
fi

# Detect resource issues
if grep -qE "memory|heap|timeout|resource" <<< "$error_log"; then
  echo "🔧 Detected resource constraints"

  # Adjust build resources:
  # - Increase memory limits
  # - Reduce parallelism
  # - Clear caches to free space
fi
```

#### 4. Merge Conflicts
```bash
# Check if PR has conflicts
if ! gh pr view $PR --json mergeable -q .mergeable; then
  # Get default branch
  default_branch=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)

  # Try rebase first
  git fetch origin $default_branch
  if ! git rebase origin/$default_branch; then
    git rebase --abort
    # Fall back to merge
    git merge origin/$default_branch
  fi

  git push --force-with-lease
fi
```

#### 5. GitHub Actions Specific Issues
```bash
# Pattern: "Body cannot be blank" (PR comment failures)
if grep -q "Body cannot be blank" <<< "$error_log"; then
  echo "Detected empty PR comment issue in workflow"
  # This requires fixing the workflow file itself
  # Check for GITHUB_STEP_SUMMARY usage
fi

# Pattern: "Resource not accessible by integration"
if grep -q "Resource not accessible" <<< "$error_log"; then
  echo "Detected permissions issue"
  # Check workflow permissions block
fi
## Smart Features

### 1. CI System Auto-Detection
```bash
# Detect CI system from context
if [ -d ".github/workflows" ]; then
  CI_SYSTEM="github-actions"
elif [ -f ".gitlab-ci.yml" ]; then
  CI_SYSTEM="gitlab"
elif [ -f ".circleci/config.yml" ]; then
  CI_SYSTEM="circleci"
elif [ -f "Jenkinsfile" ]; then
  CI_SYSTEM="jenkins"
fi
```

### 2. Progressive Fix Attempts
1. **Quick fixes** (< 30s): Format code, update snapshots
2. **Medium fixes** (< 2m): Reinstall deps, clear caches
3. **Heavy fixes** (< 5m): Full rebuild, rebase from main
4. **Manual intervention**: If all auto-fixes fail

### 3. Learning from Failures
- Track which fixes work for specific error patterns
- Build a project-specific fix database
- Prioritize successful fix strategies

## Example Output

### Successful Auto-Fix Flow
```
$ /project:check-ci 85

🔍 Checking PR #85 status...
✅ PR is open and ready
❌ Has merge conflicts with main

🔧 Fixing merge conflicts...
  → Fetching latest main branch
  → Attempting rebase... failed
  → Falling back to merge... success
  → Pushing changes

🚦 Monitoring CI checks...
  ⏳ Lint check         [running - 0:45]
  ⏳ Build              [queued]
  ⏳ Tests              [queued]

❌ Lint check failed at 1:23

🔍 Analyzing lint errors...
  → Found ESLint errors: 12 problems (12 fixable)
  → Found Prettier issues: 3 files

🔧 Auto-fixing lint issues...
  → Running: npm run lint:fix
  → Fixed: 12 ESLint errors
  → Running: npx prettier --write .
  → Formatted: 3 files
  → Committing: "fix: auto-fix linting issues"
  → Pushing fixes

🔄 CI restarted automatically...

🚦 Monitoring CI checks (attempt 2)...
  ✅ Lint check         [passed - 1:15]
  ⏳ Build              [running - 2:30]
  ⏳ Tests              [queued]

✅ Build              [passed - 4:45]
✅ Tests              [passed - 2:18]

🎉 All CI checks passed! PR is ready to merge.
```

### Manual Intervention Required
```
$ /project:check-ci

🔍 Finding PR for current branch...
✅ Found PR #92

🚦 Monitoring CI checks...
  ✅ Lint check         [passed - 1:02]
  ❌ Build              [failed - 3:45]
  ⏭️  Tests              [skipped]

🔍 Analyzing build failure...
  → Error: "Cannot resolve dependency '@mycompany/private-package'"

⚠️  Manual intervention required:

  The build is failing due to a private package dependency.
  This might be because:
  1. Missing npm authentication token
  2. Not connected to company VPN
  3. Package doesn't exist

  Suggested fixes:
  1. Check your .npmrc configuration
  2. Run: npm login --registry=https://npm.mycompany.com
  3. Verify package name is correct

  After fixing, push any changes and run:
  /project:check-ci
```

## Key Success Metrics

- **Auto-fix success rate**: ~75% of common CI failures
- **Time to green**: Average 5-10 minutes with auto-fixes
- **Manual intervention**: Required for ~25% of cases

## Configuration

### Command Options
```bash
/project:check-ci              # Auto-detect PR and fix aggressively
/project:check-ci 123          # Check specific PR
/project:check-ci --no-fix     # Monitor only, don't auto-fix
/project:check-ci --timeout 30 # Custom timeout (minutes)
```

### Environment Variables
```bash
CI_POLL_INTERVAL=30            # Seconds between status checks
CI_MAX_FIX_ATTEMPTS=3          # Max auto-fix attempts
CI_AUTO_MERGE=true             # Enable auto-merge after success
```

## Prerequisites

### Required Tools
- `git` - Version control operations
- `gh` (GitHub) or `glab` (GitLab) - PR/MR operations
- Build tools - Auto-detected from project configuration

### Permissions
- Push access to the repository
- CI/CD system access (view logs, re-run jobs)
- PR/MR write access (for status updates)

## Quick Reference

### Common Workflow
```bash
# 1. Push your changes
git push -u origin feature/my-branch

# 2. Create PR
gh pr create

# 3. Run check-ci to get everything green
/project:check-ci

# 4. Enable auto-merge when CI passes
gh pr merge --auto --squash
```

### Fix Strategies by Error Type

| If you see... | check-ci will... |
|---------------|------------------|
| Linting errors | Find and run project's lint fix command |
| Formatting issues | Find and run project's format command |
| Test failures | Re-run tests, update snapshots if needed |
| Missing dependencies | Clean and reinstall from lock file |
| Merge conflicts | Rebase or merge from default branch |
| Type errors | Attempt common type fixes |
| Build timeout | Optimize resources, retry with limits |

### Manual Override Commands
When auto-fix fails, manually:
1. Check CI logs for specific error messages
2. Run project-specific fix commands found in package.json/Makefile/etc
3. Clear caches and retry
4. Update from main branch if needed

### Integration with Other Commands
```bash
/project:create-pr        # Create PR first
/project:check-ci         # Fix all CI issues
/project:verify-pr        # Final verification
```
