# Check CI

Command to check CI status and wait for completion, with automatic issue resolution.

## Usage
```
/project:check-ci [pr-number]
```

If no PR number is provided, automatically finds and checks the CI for the current branch's PR.

## Execution Steps

Follow these steps to check CI status and resolve issues:

1. **Find PR**: If PR number is provided, use `gh pr view <pr-number>`. If not provided, get current branch name with `git branch --show-current` then find PR with `gh pr list --head <branch-name>`
2. **Check PR status**: Verify PR is open and not in draft mode
3. **Check conflicts**: Use `gh pr view <pr-number> --json mergeable` to check for conflicts
4. **Initial CI assessment**: 
   ```bash
   gh pr checks <pr-number>  # Get current status
   gh pr checks <pr-number> --json  # Get detailed JSON for parsing
   ```
5. **Monitor CI status**: Poll CI status every 30 seconds with progress indicators:
   ```bash
   # Check specific workflow runs
   gh run list --branch <branch-name> --limit 5
   gh run view <run-id> --log  # Get logs if failed
   ```
6. **Wait for completion**: Continue polling until all required checks complete:
   - Lint ✓/✗
   - Core Build ✓/✗  
   - Full Build ✓/✗ (PR only)
   - Unit Tests ✓/✗
7. **Analyze failures**: If CI fails, get detailed error information:
   ```bash
   # Get failing check details
   gh pr checks <pr-number> --json | jq '.[] | select(.conclusion == "failure")'
   # Get specific workflow logs
   gh run view <run-id> --log-failed
   ```
8. **Auto-resolve issues**: Attempt fixes based on failure type (see Auto-Resolution Logic)
9. **Retry CI**: After fixes, trigger new CI run:
   ```bash
   git push  # Triggers new CI run automatically
   # Or manually re-run specific checks
   gh run rerun <run-id>
   ```
10. **Report results**: Provide detailed status and resolution summary

## Auto-Resolution Logic

### This Project's CI Workflow Analysis

Based on the actual CI structure (.github/workflows/):
1. **Lint Job**: Pre-commit hooks validation
2. **Core Build Job**: Basic Nix build and flake validation
3. **Full Build Job**: Complete Darwin system build (PR only)
4. **Unit Tests Job**: Test suite execution

### Common CI Failures and Solutions

#### 1. Lint Failures (lint.yml)
- **Detection**: `make lint` fails on pre-commit hooks
- **Common causes**: 
  - Formatting issues (nixpkgs-fmt, prettier)
  - Nix syntax errors
  - File permission changes
- **Auto-fix commands**:
  ```bash
  make lint                    # Run and auto-fix formatting
  git add .                    # Stage fixed files
  git commit --amend --no-edit # Amend to current commit
  git push --force-with-lease  # Force push safely
  ```

#### 2. Core Build Failures (build.yml - core-build)
- **Detection**: Development shell or core packages fail to build
- **Common causes**:
  - Missing USER environment variable
  - Flake structure issues
  - Nix cache corruption
- **Auto-fix commands**:
  ```bash
  export USER=ci               # Set required environment
  nix flake check --impure --no-build  # Validate structure
  make smoke SYSTEM=x86_64-darwin      # Quick validation
  ```

#### 3. Full Build Failures (build.yml - full-build)
- **Detection**: Complete Darwin system build timeout or failure
- **Common causes**:
  - Homebrew configuration issues
  - Large system rebuild requirements
  - Dependency conflicts
- **Auto-fix commands**:
  ```bash
  nix build --impure .#darwinConfigurations.x86_64-darwin.system --max-jobs 1
  # If timeout, break into smaller builds
  make build-darwin ARGS="--max-jobs 1 --cores 1"
  ```

#### 4. Test Failures (test.yml)
- **Detection**: Unit test suite fails
- **Common causes**:
  - Test environment setup
  - Nix store cache issues
  - Test dependencies missing
- **Auto-fix commands**:
  ```bash
  export USER=ci
  make test ARGS="--max-jobs auto --cores 0"
  # For specific test categories:
  make test-unit
  make test-integration
  make test-e2e
  ```

#### 5. Merge Conflicts
- **Detection**: `gh pr view <pr-number> --json mergeable` returns false
- **Solution**: Update branch from main
- **Auto-fix commands**:
  ```bash
  git fetch origin main
  git merge origin/main  # Or git rebase origin/main
  # Resolve conflicts if any
  git add . && git commit
  git push
  ```

#### 6. Workflow-Specific Issues

##### Concurrency Conflicts (build.yml)
- **Detection**: "cancel-in-progress" terminates jobs
- **Solution**: Wait for current build to complete or restart

##### Cache Corruption
- **Detection**: Nix cache key mismatches
- **Auto-fix**: Clear local cache and retry
  ```bash
  nix store gc
  nix build --no-link .#devShells.x86_64-darwin.default
  ```

### Resolution Strategy

1. **Immediate fixes**: Apply automatic fixes for common issues
2. **Guided resolution**: Provide step-by-step instructions for manual fixes
3. **Escalation**: Alert user for complex issues requiring manual intervention

## Examples

```
/project:check-ci 85
```
Check CI status for PR #85 and wait for completion with auto-resolution

```
/project:check-ci
```
Check CI status for current branch's PR and wait for completion

### Detailed Example Output

```
🔄 Checking CI for PR #85...

📊 PR Status:
  ✓ Open and ready for review
  ✓ No merge conflicts  
  ✓ Up to date with main branch

🚦 CI Checks Status:
  🟡 Lint (running)        [2m 15s]
  ⏳ Core Build (pending)  [waiting for lint]
  ⏳ Full Build (pending)  [waiting for core build]
  ⏳ Unit Tests (pending)  [waiting for lint]

⏱️  Estimated completion: 8-12 minutes

🔄 Waiting for CI completion... (polling every 30s)

❌ Lint check failed after 3m 45s
📋 Analyzing failure...

🔧 Auto-resolution attempt:
  - Running: make lint
  - Fixed: 3 formatting issues in .nix files
  - Committing fixes...
  - Pushing updates...

🚀 Triggered new CI run...

✅ All CI checks passed! 
🎉 PR #85 is ready to merge
```

## Monitoring Features

### Real-time Status Display
```
🚦 CI Status Dashboard
┌─────────────────┬─────────────┬──────────────┐
│ Check           │ Status      │ Duration     │
├─────────────────┼─────────────┼──────────────┤
│ Lint            │ ✅ Passed    │ 2m 30s       │
│ Core Build      │ 🟡 Running   │ 5m 15s       │
│ Full Build      │ ⏳ Pending   │ -            │
│ Unit Tests      │ ✅ Passed    │ 4m 02s       │
└─────────────────┴─────────────┴──────────────┘

⏱️ Total elapsed: 7m 45s | ETA: 3-5 minutes
```

### Intelligent Monitoring
- **Progressive timeouts**: Different timeout thresholds for each job type
  - Lint: 5 minutes
  - Core Build: 15 minutes  
  - Full Build: 45 minutes
  - Unit Tests: 10 minutes
- **Early failure detection**: Stop monitoring if critical dependency fails
- **Resource usage alerts**: Warn about high memory/CPU usage patterns

### Failure Analysis Engine
```bash
# Failure pattern matching
if [[ "$error_log" =~ "USER environment variable" ]]; then
  echo "🔧 Detected USER env issue - applying fix..."
  export USER=ci && git push
elif [[ "$error_log" =~ "cache key" ]]; then
  echo "🔧 Detected cache corruption - clearing and retrying..."
  nix store gc
fi
```

### Smart Retry Logic
- **Exponential backoff**: Wait longer between retries after failures
- **Selective retry**: Only retry specific failed jobs, not entire workflow
- **Dependency awareness**: Don't retry downstream jobs if upstream still failing

## Configuration

### Polling Interval
Default: 30 seconds
Can be adjusted based on CI performance

### Timeout Settings
- Maximum wait time: 60 minutes
- Early termination for persistent failures

### Auto-resolution Scope
- Safe fixes only (formatting, linting)
- User confirmation required for structural changes
- Fallback to manual resolution for complex issues

## Integration

### Required Tools and Setup
```bash
# Essential tools (auto-detected)
gh --version     # GitHub CLI for PR/CI operations
git --version    # Git for repository operations
make --version   # Make for build commands
nix --version    # Nix for system builds

# Project-specific commands
make lint        # Pre-commit hooks
make smoke       # Flake validation
make build       # Full system builds
make test        # Test suite execution
```

### Authentication Requirements
```bash
# GitHub CLI authentication (required)
gh auth status   # Check current auth status
gh auth login    # Login if needed

# Required permissions:
# - Repository: read/write access
# - Actions: read access (for CI logs)
# - Pull requests: write access (for auto-fixes)
```

### Environment Setup
```bash
# Required environment variables
export USER=ci   # For Nix builds (critical)

# Optional configuration
export GITHUB_TOKEN="<token>"  # For API rate limiting
export NIX_CONFIG="max-jobs = auto
cores = 0
substituters = https://cache.nixos.org https://nix-community.cachix.org"
```

## Error Handling

### Timeout Scenarios
- Provide partial results if CI takes too long
- Save progress for manual continuation
- Alert user to check CI manually

### Permission Issues
- Graceful degradation to read-only mode
- Clear error messages for permission problems
- Alternative workflows for restricted access

### Network Issues
- Retry logic with exponential backoff
- Offline mode with cached data
- Recovery strategies for connection failures

## Quick Reference

### Command Variations
```bash
# Basic usage
/project:check-ci               # Current branch's PR
/project:check-ci 123           # Specific PR number

# With additional options (implementation dependent)
/project:check-ci --timeout 30  # Custom timeout (minutes)
/project:check-ci --no-fix      # Monitor only, no auto-fixes
/project:check-ci --verbose     # Detailed logging
```

### Common Workflow
```bash
# 1. Create/update PR
git push -u origin feature/my-change
gh pr create

# 2. Monitor CI with auto-resolution
/project:check-ci

# 3. If manual intervention needed
make lint && git add . && git commit --amend --no-edit
git push --force-with-lease

# 4. Continue monitoring
/project:check-ci

# 5. Merge when ready
gh pr merge --auto --squash
```

### Manual Troubleshooting
```bash
# Check current CI status manually
gh pr checks <pr-number>
gh run list --branch <branch-name>
gh run view <run-id> --log

# Run local equivalents of CI checks
export USER=ci
make lint                           # Lint check
make smoke SYSTEM=x86_64-darwin    # Core validation
make build-darwin                  # Full build
make test                          # Test suite

# Common fixes
git fetch origin main && git merge origin/main  # Update branch
nix store gc                                     # Clear cache
pre-commit run --all-files                      # Fix formatting
```

### Integration with Other Commands
```bash
# After fixing issues with other commands
/project:fix-pr 123         # Fix PR issues first
/project:check-ci 123       # Then monitor CI

# Before merging
/project:check-ci 123       # Ensure CI passes
/project:verify-pr 123      # Final verification
```