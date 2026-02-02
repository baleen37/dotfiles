# CI/CD Optimization Report

## Executive Summary

This report analyzes the current CI/CD pipeline and provides actionable improvements for the Nix flakes-based dotfiles system.

**Current State Analysis:**
- 3-platform matrix (Darwin ARM64, Linux x64, Linux ARM64)
- Week-based cache rotation (7-day TTL)
- Pre-commit hooks validation
- Container tests (Linux) / Validation mode (macOS)
- Cachix integration for binary cache

**Key Improvement Areas:**
1. Smart test filtering based on changed paths
2. Enhanced test result reporting with metrics
3. Optimized cache strategy
4. Better failure log aggregation
5. PR comments with test summaries

---

## 1. Current CI Architecture Analysis

### 1.1 Workflow Structure

```
.github/workflows/ci.yml
├── Single job (ci) with matrix strategy
│   ├── Checkout
│   ├── Clear Nix store cache
│   ├── Setup Nix with cache (composite action)
│   ├── Install pre-commit
│   ├── Run pre-commit hooks
│   ├── Fast container tests
│   ├── Full test suite (PR/main only)
│   ├── Test secrets backup
│   └── Upload to Cachix (main/tags only)
```

### 1.2 Cache Configuration

**Current Cache Strategy:**
- **Location:** `~/.cache/nix`, `~/.local/state/nix`
- **Key Pattern:** `nix-{os}-{flake.lock.hash}-{week}-v3`
- **Rotation:** Weekly (date +%Y-W%U)
- **Scope:** Per-platform, per-week, per-flake-lock

**Strengths:**
- Weekly rotation prevents stale cache
- Platform-specific keys
- Flake-lock integration ensures cache invalidation on dependency changes

**Weaknesses:**
- Cache clearing every run defeats weekly rotation purpose
- No restore-only mode for PR validation
- Cache upload happens during test execution (potential contention)

### 1.3 Test Coverage

**Test Types:**
- **Unit Tests:** 26 tests in `tests/unit/` (auto-discovered)
- **Integration Tests:** 17 tests in `tests/integration/` (auto-discovered)
- **Container Tests:** 4 NixOS container tests
- **Pre-commit Hooks:** shellcheck, shfmt, nixfmt

**Test Discovery:**
```nix
# Automatic discovery from tests/default.nix
discoverPlatformTests = dir: prefix:
  let discoveredTests = discoverTests dir prefix;
      filteredTests = platformHelpers.filterPlatformTests discoveredTests;
  in extractTestValues filteredTests;
```

### 1.4 Performance Baseline

**Estimated Execution Times:**
- Pre-commit hooks: 30-60 seconds
- Fast container tests (Linux): 2-5 minutes
- Fast validation mode (macOS): 30-60 seconds
- Full test suite: 5-10 minutes
- Cachix upload: 2-5 minutes

**Total CI Time:** ~10-20 minutes per platform

---

## 2. Optimizations Implemented

### 2.1 Smart Test Filtering

**Problem:** All tests run on every change, even for unrelated files.

**Solution:** Path-based change detection with categorized test execution.

```yaml
detect-changes:
  outputs:
    user-config: true/false  # users/, lib/
    nix-files: true/false    # *.nix
    tests: true/false        # tests/
    ci: true/false           # .github/
```

**Benefits:**
- Skip full rebuild for documentation-only changes
- Run relevant tests based on changed components
- Faster feedback for PRs

**Implementation:**
```bash
# Categorize changes using git diff
USER_CONFIGChanged=$(echo "$CHANGED_FILES" | grep -E '^(users/|lib/)')
TESTSChanged=$(echo "$CHANGED_FILES" | grep -E '^tests/')
```

### 2.2 Enhanced Test Reporting

**Problem:** Test failures provide minimal context; no aggregation across platforms.

**Solution:** Structured test results with JSON output and PR comments.

**Features:**
1. **Test Metrics:**
   - Duration tracking per test suite
   - Pass/fail status
   - Platform-specific results

2. **Log Aggregation:**
   - Upload raw test logs as artifacts
   - Parse and structure test results
   - Retain logs for 30-90 days

3. **PR Comments:**
   - Automatic test summary on PRs
   - Update existing comments (no spam)
   - Include change detection results

**Output Format:**
```json
{
  "platform": "Darwin",
  "arch": "aarch64",
  "fast_tests_status": "passed",
  "fast_tests_duration": "45",
  "timestamp": "2026-01-31T12:00:00Z"
}
```

### 2.3 Optimized Cache Strategy

**Problem:** Cache is cleared every run, defeating the purpose of weekly rotation.

**Solution:** Separate cache restore and save operations.

**Changes:**
1. **Remove cache clearing step:**
   ```diff
   - - name: Clear Nix store cache
   -   run: rm -rf ~/.cache/nix ~/.local/state/nix
   ```

2. **Use restore-only mode for tests:**
   ```yaml
   - uses: ./.github/actions/setup-nix
     with:
       cache-mode: restore-only  # Don't save during test execution
   ```

3. **Separate cache upload job:**
   ```yaml
   cache-upload:
     needs: ci  # Runs after tests complete
     cache-mode: full  # Save cache only on main branch
   ```

**Benefits:**
- Cache persists across runs within the same week
- No contention between test execution and cache saving
- Faster CI for PRs (restore-only)

### 2.4 Improved Failure Diagnostics

**Problem:** Test failures show minimal error context.

**Solution:** Enhanced error reporting with structured output.

**Features:**
1. **Detailed error messages:**
   ```yaml
   - name: Run tests with detailed output
     run: |
       make test 2>&1 | tee test-results/fast-tests.log
   ```

2. **Step-level status tracking:**
   ```yaml
   - id: run-tests
     run: |
       echo "fast_tests_status=passed" >> $GITHUB_OUTPUT
       echo "fast_tests_duration=${DURATION}" >> $GITHUB_OUTPUT
   ```

3. **Aggregate failure reports:**
   - Download all platform results
   - Generate consolidated markdown report
   - Comment on PR with summary

### 2.5 Parallel Execution Optimization

**Problem:** Sequential steps create bottlenecks.

**Solution:** Job-level parallelism with dependency management.

**Strategy:**
```
detect-changes (30s)
    |
    +--> ci (Darwin)    -\
    +--> ci (Linux x64)  +--> Parallel execution
    +--> ci (Linux ARM) -/
         |
         +--> cache-upload (Darwin)     -\
         +--> cache-upload (Linux x64)   +--> Only on main
         +--> cache-upload (Linux ARM)   -/
              |
              +--> test-report (aggregate results)
```

**Benefits:**
- 3 platforms run in parallel
- Cache upload doesn't block test reporting
- Faster overall pipeline execution

---

## 3. Test Result Reporting Improvements

### 3.1 Coverage Reporting

**Current State:** No test coverage metrics.

**Proposed Enhancement:** Add test discovery reporting.

```yaml
- name: Report test coverage
  run: |
    # Count tests by category
    UNIT_TESTS=$(find tests/unit -name "*-test.nix" | wc -l)
    INTEGRATION_TESTS=$(find tests/integration -name "*-test.nix" | wc -l)
    CONTAINER_TESTS=$(find tests/containers -name "*.nix" | wc -l)

    echo "::notice::Test Coverage:"
    echo "::notice::  Unit: $UNIT_TESTS"
    echo "::notice::  Integration: $INTEGRATION_TESTS"
    echo "::notice::  Container: $CONTAINER_TESTS"
    echo "::notice::  Total: $((UNIT_TESTS + INTEGRATION_TESTS + CONTAINER_TESTS))"
```

### 3.2 Performance Metrics

**New Metrics Tracked:**
- Test suite duration (seconds)
- Per-platform execution time
- Cache hit/miss rate
- Build time vs. test time ratio

**Visualization:**
```markdown
## Performance Metrics
| Platform | Duration | Status | Cache Hit |
|----------|----------|--------|-----------|
| Darwin   | 45s      | Pass   | Yes       |
| Linux x64| 180s     | Pass   | Yes       |
| Linux ARM| 185s     | Pass   | No        |
```

### 3.3 Failure Log Analysis

**Enhanced Error Extraction:**
```yaml
- name: Extract failure details
  if: failure()
  run: |
    # Parse test logs for failures
    grep -E "FAIL|ERROR|failed" test-results/*.log > failures.txt || true

    # Count by error type
    grep -c "assertion failed" failures.txt || echo "0"
    grep -c "build failed" failures.txt || echo "0"
```

---

## 4. Cache Optimization Analysis

### 4.1 Cache Hit Rate Improvement

**Before Optimization:**
- Cache cleared every run → 0% hit rate
- Weekly rotation ineffective
- Full rebuild required every time

**After Optimization:**
- Cache persists for 7 days → ~80% hit rate (estimated)
- Restore-only mode for PRs
- Separate save job for main branch

### 4.2 Cache Key Strategy

**Current Key:**
```
nix-{os}-{flake.lock.hash}-{week}-v3
```

**Optimization Opportunities:**
1. **Add channel version:** Include nixpkgs revision
2. **Add system config hash:** Include machines/* hash
3. **Graduated cache layers:**
   - Layer 1: Nix store (binaries)
   - Layer 2: GC roots (frequent builds)
   - Layer 3: Test artifacts

### 4.3 Cache Size Management

**Estimated Cache Sizes:**
- macOS: ~2-4 GB (includes darwin-system)
- Linux x64: ~1-2 GB
- Linux ARM64: ~1-2 GB

**Strategy:**
- Weekly rotation prevents unbounded growth
- Platform-specific keys prevent cross-contamination
- 90-day retention for test artifacts

---

## 5. Smart Test Filtering Strategy

### 5.1 Path Categories

| Category | Pattern | Tests to Run |
|----------|---------|--------------|
| User Config | `users/*`, `lib/*` | Full suite |
| Nix Files | `*.nix` | Fast + integration |
| Tests | `tests/*` | Full suite (rebuild) |
| CI Config | `.github/*` | Validation only |
| Docs | `*.md` | Skip tests |

### 5.2 Test Selection Matrix

```yaml
# Conditional test execution
- name: Run tests
  if: |
    needs.detect-changes.outputs.user-config == 'true' ||
    needs.detect-changes.outputs.tests == 'true' ||
    needs.detect-changes.outputs.has-changes == 'false'  # Run on no changes too
  run: make test
```

### 5.3 PR Label Integration (Future)

**Proposed Labels:**
- `skip-tests`: Skip test execution (documentation-only changes)
- `run-full`: Force full test suite regardless of changes
- `performance`: Enable performance profiling

---

## 6. Implementation Roadmap

### Phase 1: Core Optimizations (Implemented)
- [x] Smart test filtering via `detect-changes` job
- [x] Enhanced test reporting with JSON output
- [x] Separate cache upload job
- [x] PR comments with test summaries
- [x] Remove cache clearing step

### Phase 2: Enhanced Metrics (Recommended)
- [ ] Test coverage reporting
- [ ] Performance trend tracking
- [ ] Cache hit rate metrics
- [ ] Flaky test detection

### Phase 3: Advanced Features (Future)
- [ ] PR label integration
- [ ] Graduated cache layers
- [ ] Performance regression detection
- [ ] Historical test result dashboard

---

## 7. Expected Impact

### 7.1 Performance Improvements

**Before:**
- Average CI time: 15-20 minutes
- Cache hit rate: ~0%
- Full rebuild every run

**After:**
- Average CI time: 5-10 minutes (PRs with cache hit)
- Cache hit rate: ~80%
- Incremental builds for most changes

**Time Savings:**
- PR validation: 50-70% faster
- Main branch builds: 30-50% faster
- Weekly time savings: ~2-4 hours

### 7.2 Developer Experience

**Improvements:**
1. Faster feedback on PRs
2. Clearer test failure messages
3. Aggregate test results in PR comments
4. Less noise from irrelevant test failures

### 7.3 Resource Efficiency

**GitHub Actions Minutes:**
- Current: ~60 minutes per run (3 platforms × 20 min)
- Optimized: ~30 minutes per run (3 platforms × 10 min)
- Savings: ~50%

**Cachix Storage:**
- Weekly rotation limits storage growth
- Platform-specific keys prevent duplication
- Estimated monthly storage: ~10-15 GB

---

## 8. Configuration Files

### 8.1 New Files Created

1. **`.github/workflows/ci-improved.yml`**
   - Enhanced CI workflow with all optimizations
   - Drop-in replacement for existing ci.yml

### 8.2 Modified Files

**To apply optimizations:**
```bash
# Backup current workflow
mv .github/workflows/ci.yml .github/workflows/ci.yml.backup

# Use improved workflow
cp .github/workflows/ci-improved.yml .github/workflows/ci.yml
```

**Or run side-by-side for comparison:**
```bash
# Keep both workflows temporarily
# - ci.yml (original)
# - ci-improved.yml (new)
# Compare results before switching
```

---

## 9. Validation and Testing

### 9.1 Validation Checklist

- [ ] Test workflow runs successfully on all platforms
- [ ] Verify cache restore works for PRs
- [ ] Verify cache save works on main branch
- [ ] Confirm PR comments are posted correctly
- [ ] Check test report artifacts are uploaded
- [ ] Validate change detection accuracy

### 9.2 Rollback Plan

If issues occur:
```bash
# Restore original workflow
git checkout .github/workflows/ci.yml

# Or disable improved workflow
mv .github/workflows/ci-improved.yml .github/workflows/ci-improved.yml.disabled
```

---

## 10. Next Steps

1. **Review the improved workflow** (`.github/workflows/ci-improved.yml`)
2. **Test in a feature branch** before merging to main
3. **Monitor cache hit rates** and adjust strategy if needed
4. **Iterate on test reporting** based on team feedback
5. **Consider Phase 2 features** after core optimization is stable

---

## Appendix A: Test Helper Functions

The project uses extensive test helpers from `tests/lib/test-helpers.nix`:

- `assertTest`: Basic assertion with custom messages
- `assertFileExists`: File readability validation
- `assertHasAttr`: Attribute existence checks
- `assertContains`: String content matching
- `assertBuilds`: Derivation build validation
- `propertyTest`: Property-based testing
- `assertPerformance`: Performance benchmarking

These helpers provide the foundation for comprehensive test coverage and enable the enhanced reporting proposed in this optimization.

## Appendix B: Platform-Specific Considerations

### macOS (Darwin)
- Container tests run in validation mode only
- Uses darwin-rebuild for system builds
- Faster due to smaller dependency tree

### Linux
- Full container test execution
- Uses nixos-rebuild for system builds
- Supports cross-platform emulation (binfmt_misc)

## Appendix C: Monitoring Dashboard Metrics

Recommended metrics to track over time:

1. **Pipeline Duration**
   - P50: Median run time
   - P95: 95th percentile
   - Trend: Week over week

2. **Cache Effectiveness**
   - Hit rate: Successful cache restores / Total runs
   - Miss reasons: Key change, expiration, unavailable

3. **Test Reliability**
   - Flaky test rate: Intermittent failures
   - Failure rate: Failed builds / Total builds

4. **Developer Productivity**
   - Average time to PR validation
   - Time to merge after approval
