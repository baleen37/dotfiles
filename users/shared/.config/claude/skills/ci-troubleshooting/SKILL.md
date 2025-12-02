---
name: ci-troubleshooting
description: Platform-agnostic CI failure troubleshooting - systematic approach for GitHub Actions, GitLab CI, Jenkins, CircleCI, Azure DevOps. Works across languages: Go, Node.js, Python, Java, Rust, .NET, and advanced environments like Docker, monorepos, cross-platform builds. (user)
---

# CI Troubleshooting (Platform-Agnostic)

## Overview & Core Principles

Fix CI failures systematically across any platform: **Observe actual errors → Cluster by commit → Reproduce locally → Fix → Validate**.

**Critical principle:** Always observe actual CI errors before guessing. 30 seconds of observation beats hours of wrong hypotheses.

**Universal principles:**
1. **Evidence over hypothesis**: Get actual error logs before forming theories
2. **Systematic over heuristic**: Follow the 5-step workflow consistently
3. **Reproduce before fixing**: Confirm local reproduction before making changes
4. **Validate at multiple levels**: Local → Branch → Main
5. **Know when to stop**: Return to Step 1 after 3 failed attempts

## When to Use

**Use for:** Build failures, test failures, dependency issues, CI timeouts, infrastructure problems, cross-platform build issues

**Don't use for:** Local development bugs (use systematic-debugging skill instead)

## Platform Detection & Setup

First, identify your CI platform:

```bash
# Check for common CI environment variables
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "GitHub Actions detected"
elif [ -n "$GITLAB_CI" ]; then
    echo "GitLab CI detected"
elif [ -n "$JENKINS_URL" ]; then
    echo "Jenkins detected"
elif [ -n "$CIRCLECI" ]; then
    echo "CircleCI detected"
elif [ -n "$AZURE_PIPELINES" ]; then
    echo "Azure DevOps detected"
else
    echo "Unknown CI platform - using generic commands"
fi
```

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

**Identify your CI platform first, then find the right tool:**
```bash
# Check which CI platform you're using
if [ -n "$GITHUB_ACTIONS" ]; then
    echo "GitHub Actions - use: gh run list, gh run view"
elif [ -n "$GITLAB_CI" ]; then
    echo "GitLab CI - use: glab ci list, glab ci view"
elif [ -n "$JENKINS_URL" ]; then
    echo "Jenkins - use: jenkins-cli, Jenkins REST API"
elif [ -n "$CIRCLECI" ]; then
    echo "CircleCI - use: circleci workflow, circleci jobs"
elif [ -n "$AZURE_PIPELINES" ]; then
    echo "Azure DevOps - use: az pipelines build"
else
    echo "Unknown platform - check docs or look for log files"
fi
```

**Generic approach when tools aren't available:**
```bash
# Look for log files and error patterns
find . -name "*.log" -o -name "*.out" | xargs grep -l -E "(error|Error|ERROR|FAIL)" 2>/dev/null | head -5

# Check CI environment variables
env | grep -E "(CI|BUILD|PIPELINE|WORKFLOW)" | head -10

# Look at recent build artifacts
ls -la build/ dist/ target/ bin/ 2>/dev/null | head -10
```

**Pro tip:** Search for "[your-platform] CI get failed build logs" if you're not sure which commands to use.

**This is non-negotiable:**
- Takes 30 seconds
- Shows actual error, not your hypothesis
- Prevents "80% confident" guessing

**Enhanced categorization:**
- **Dependency**: Missing packages, version conflicts, network failures
- **Build/Test**: Compilation errors, assertion failures, test framework issues
- **Infrastructure**: Timeouts, permissions, resource limits, service failures
- **Platform**: Works locally, fails in CI (OS/arch differences, environment variables)
- **Concurrency**: Race conditions, parallel test conflicts, resource contention
- **Memory/Performance**: OOM kills, excessive memory usage, performance timeouts

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

**Before reading code or logs, run the failing test with the EXACT command from CI logs:**

**Find the right test command for your language:**
```bash
# Identify your language framework
if [ -f "package.json" ]; then
    echo "Node.js - try: npm test, yarn test, npm run test"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    echo "Python - try: pytest, python -m pytest, python -m unittest"
elif [ -f "pom.xml" ]; then
    echo "Java Maven - try: mvn test"
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    echo "Java Gradle - try: ./gradlew test"
elif [ -f "Cargo.toml" ]; then
    echo "Rust - try: cargo test"
elif [ -f "go.mod" ]; then
    echo "Go - try: go test ./..."
elif [ -f "*.csproj" ] || [ -f "*.sln" ]; then
    echo ".NET - try: dotnet test"
fi
```

**Copy the EXACT command from CI logs and run it locally.**
Examples of common patterns:
- `pytest tests/path/test_file.py::test_name`
- `npm test -- --testNamePattern="failing test"`
- `mvn test -Dtest=ClassName#methodName`
- `./gradlew test --tests ClassName.methodName`
- `cargo test test_name`
- `go test -v ./package/path -run TestName`
- `dotnet test --filter "TestName"`

**Match CI environment:**
```bash
# Check CI logs for required environment variables
# Look for patterns like: export VAR=value, env.VAR=value, or $VAR

# Common environment variables to match
export NODE_ENV=test
export CI=true
export TZ=UTC

# Match versions from CI logs
# Look for: node --version, python --version, java -version
```

**Why:** Confirms you can reproduce, shows exact error, enables iterative debugging, validates environment assumptions.

**Why BEFORE reading code:** Prevents confirmation bias where you "see" what you expect to see.

## Step 4: Fix

Apply minimal change that fixes the root cause you identified.

**Common patterns:**
- **Dependency**: Clear cache, reinstall dependencies, lock versions
- **Build**: Clean build artifacts, rebuild, check build flags
- **Infrastructure**: Check logs for timeout/memory/permission errors, service availability
- **Environment**: Match CI environment (versions, variables, permissions)
- **Concurrency**: Add synchronization, isolate tests, disable parallel execution
- **Memory**: Optimize memory usage, increase limits, fix memory leaks

## Step 5: Validate (Three Tiers - No Shortcuts)

**Even for "simple fixes." Even under time pressure. No exceptions.**

### Tier 1: Local
Run specific test, then full suite to catch regressions.

### Tier 2: Branch CI
Push to feature branch (NOT main). Watch CI. Wait for green. If fails, return to Step 1.

### Tier 3: Post-Merge
Monitor main CI for 5 minutes. If breaks: REVERT immediately, re-investigate on branch.

## Advanced Scenarios

### Docker/Container Environments

**Reproduce with same container as CI:**
```bash
# Use same image as CI
docker run -v $(pwd):/app -w /app <ci-image> <test-command>

# Use docker-compose if defined
docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit

# Get CI container info
docker inspect <container-id> | grep -A 5 -B 5 "Env\|Mounts"
```

**Container-specific issues:**
- Check if test data volumes are mounted correctly
- Verify container user permissions (UID/GID mismatch)
- Ensure container has necessary system dependencies
- Check for container resource limits (memory, CPU)

### Monorepo Environments

**Run tests for specific packages:**
```bash
# Nx (Angular, React, etc.)
nx test <project-name>

# Lerna (JavaScript packages)
lerna run test --scope <package-name>

# Bazel (Google, Uber)
bazel test //path/to/package:target

# Rush (Microsoft)
rush test --to <package-name>
```

**Monorepo-specific issues:**
- Check for dependency graph changes affecting unrelated packages
- Verify build order and caching is working correctly
- Look for shared resource conflicts between packages
- Check for workspace configuration changes

### Cross-Platform Builds

**Identify platform differences:**
```bash
# Local vs CI environment comparison
echo "Local: $(uname -a)"
echo "Local Node: $(node --version)"
echo "Local Python: $(python --version)"

# In CI logs, find the equivalent info
grep -E "(uname|node.*version|python.*version)" ci-log.txt
```

**Common cross-platform issues:**
- **Path separators**: `/` vs `\` in Windows vs Unix
- **File extensions**: executables, scripts need `.sh`/`.bat` extensions
- **Environment variables**: `PATH` separator differences (`:` vs `;`)
- **Case sensitivity**: filename case sensitivity differences
- **Line endings**: CRLF vs LF issues in text files

**Solutions:**
```bash
# Use cross-platform path handling
path.join() instead of string concatenation
path.resolve() for absolute paths

# Use cross-platform file operations
fs.promises with proper error handling
rimraf for cross-platform directory removal

# Handle environment variables consistently
process.env.PATH.split(process.platform === 'win32' ? ';' : ':')
```

### Memory and Resource Issues

**Identify resource problems:**
```bash
# Check memory usage in tests
node --max-old-space-size=4096 node_modules/.bin/jest

# Monitor process resources
htop # interactive process viewer
iotop # I/O monitoring
nvidia-smi # GPU usage if applicable

# Check system limits
ulimit -a  # user limits
cat /proc/meminfo | head -10  # memory info
```

**Common solutions:**
```bash
# Node.js memory limits
export NODE_OPTIONS="--max-old-space-size=4096"

# Java heap size
export JAVA_OPTS="-Xmx4g -Xms2g"

# Python memory profiling
python -m memory_profiler script.py

# Go memory limits
GOMEMLIMIT=4GiB go test ./...
```

### Concurrency and Race Conditions

**Identify race conditions:**
```bash
# Run tests multiple times to detect flaky behavior
for i in {1..10}; do
  npm test || echo "Test failed on run $i"
done

# Run tests sequentially to isolate conflicts
npm test -- --runInBand

# Add delays to expose timing issues
sleep 0.1  # Add in test setup/teardown
```

**Common patterns for race conditions:**
- **Test isolation**: Ensure tests don't share state
- **Resource cleanup**: Proper cleanup in afterEach/afterAll
- **Timeouts**: Increase timeouts for CI environments
- **Retry logic**: Add retry for network-dependent tests
- **Deterministic ordering**: Sort arrays to avoid random ordering

### Environment-Specific Failures

**Debug environment differences:**
```bash
# Compare environment variables
env | sort > local-env.txt
# Compare with CI env variables from logs
diff local-env.txt ci-env.txt

# Check file permissions
ls -la /path/to/problematic/file
stat /path/to/problematic/file

# Network connectivity tests
curl -I https://api.example.com
ping -c 3 external-service.com
```

**Common environment fixes:**
```bash
# Set consistent timezone
export TZ=UTC

# Disable color output in CI
export NO_COLOR=1
export CI=true

# Use deterministic temp directories
export TMPDIR=/tmp/ci-tests
mkdir -p $TMPDIR
```

## When You're Stuck

**Tried 3+ things? STOP. You're guessing, not debugging.**

Return to Step 1. Don't try thing #6. Sunk cost is not a reason to continue wrong approach.

## Quick Reference (Expanded)

| Symptom | First Action | Common Fix |
|---------|-------------|------------|
| **Any failure** | **Step 1: Platform-specific error observation** | **See actual error first** |
| Test passes on retry | Re-run 3-5 times locally | Add retry logic, fix race condition |
| Can't reproduce locally | Retry in CI (3x), compare environments | Environment mismatch, timing issue |
| Consistent failure | Reproduce with exact CI command | Fix the specific test/build issue |
| Docker-related failure | `docker run` with same image, check mounts | Volume issues, user permissions, missing deps |
| Monorepo cross-package failure | Test specific package only | Dependency graph issue, shared state conflict |
| Memory error in CI | Check resource limits, profile memory usage | Increase limits, optimize memory usage |
| Cross-platform build failure | Compare OS/arch differences | Path handling, file extensions, environment vars |
| Concurrency failure | Run tests sequentially, add delays | Race condition, shared resource conflict |
| Package/dependency errors | Clear cache, lock versions, reinstall | Version conflicts, network issues, cache corruption |
| Timeout | Reproduce locally first, profile performance | Fix slowness, optimize operations,合理增加超时 |
| Infrastructure failure | Check service status, logs, permissions | Service outage, resource limits, permissions |
| Test flakiness | Run 10+ times, add deterministic ordering | Random ordering, external dependencies, timing |

### Finding the Right Commands

**CI Platform Commands:**
- Search: "[your-platform] get failed build logs"
- Check platform documentation for CLI tools
- Look for existing scripts in your repo (ci-*.sh, scripts/)

**Language Debug Commands:**
- Search: "[language] debug failing tests"
- Check framework documentation for debug flags
- Look at package.json scripts or Makefile targets
- Common patterns: `--verbose`, `--debug`, `-X`, `--inspect`

**Environment Debugging:**
- Compare local vs CI: `env | sort > local.txt`
- Check versions: `node --version`, `python --version`, `java -version`
- Look for Dockerfile or CI config for environment setup

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
