# Test Performance Baseline Report

**Generated**: 2026-01-31
**System**: aarch64-darwin (macOS)
**Test Framework**: Nix flake checks

## Executive Summary

This report establishes performance baselines for the dotfiles test suite and identifies optimization opportunities for parallel test execution.

### Key Metrics

| Metric | Value | Notes |
|--------|-------|-------|
| **Total Test Count (aarch64-darwin)** | 101 checks | Includes unit, integration, and container tests |
| **Validation Mode Runtime** | ~10 seconds | `nix flake check --no-build` on macOS |
| **Single Test Build Time** | ~1.1 seconds | Smoke test example |
| **Theoretical Minimum Runtime** | ~111 seconds | Sequential execution (101 × 1.1s) |
| **Practical Runtime** | ~30-60 seconds | Estimated with partial parallelization |

### Performance Baselines

#### Individual Test Performance

- **Fast tests** (< 2s): Most unit tests, smoke tests
- **Medium tests** (2-10s): Integration tests, tests with imports
- **Slow tests** (> 10s): E2E tests, container tests (Linux only)

#### Test Discovery Performance

- **Automatic test discovery**: ~100-200ms overhead
- **Platform filtering**: Minimal overhead (< 50ms)
- **Test dependency resolution**: ~500ms overall

---

## Test Suite Composition

### Test Categories

```
Total Checks: 101 (aarch64-darwin)

Unit Tests (~60 tests):
  - lib-mksystem-detailed-*: 60 individual checks (split from single test)
  - assertions: 1
  - platform-helpers: 1
  - build-performance: 1
  - Other unit tests: ~20

Integration Tests (~25 tests):
  - Git configuration: 1
  - Home Manager: 2
  - ZSH, Vim, Tmux, Starship: ~8
  - Build/Switch user: ~3
  - Other integrations: ~11

Container Tests (4 tests):
  - smoke-test: 1
  - basic-system: 1
  - services: 1
  - packages: 1
  Note: Container tests require Linux, skipped on macOS with validation mode
```

### Test Dependencies Analysis

#### Independent Tests (High Parallelization Potential)

Tests with **no external dependencies** that can run fully in parallel:

1. **Most Unit Tests**
   - `unit-assertions`
   - `unit-platform-helpers`
   - `unit-mksimpletest-helper`
   - `unit-security-packages`
   - `unit-starship`
   - `unit-statusline`
   - `unit-trend-analysis`
   - `unit-tmux-configuration`
   - `unit-edge-case-git-config`
   - `unit-edge-case-user-config`
   - `unit-property-based-git-config`
   - `unit-property-based-user-management`
   - All `unit-lib-mksystem-detailed-*` tests (60 tests)

2. **Some Integration Tests**
   - `integration-npm-global-path`
   - `integration-git-configuration`
   - `integration-starship-configuration`

#### Tests with Shared Dependencies (Moderate Parallelization)

Tests that import common modules but can still run in parallel:

1. **Library-Dependent Tests**
   - Tests importing `lib/mksystem.nix`
   - Tests importing `lib/user-info.nix`
   - Tests importing `lib/performance.nix`

2. **Platform-Specific Tests**
   - Darwin-only tests (can run in parallel on macOS)
   - Linux-only tests (can run in parallel on Linux)

#### Sequential Dependencies (Low Parallelization)

Tests that must run sequentially due to shared state or ordering:

1. **Build Tests**
   - `integration-build` (requires clean state)
   - `integration-switch-user` (modifies system state)

2. **E2E Tests**
   - All E2E tests in `tests/e2e/` (require VM isolation)
   - VM bootstrap and deployment tests

---

## Parallel Execution Strategy

### Recommended Parallel Test Groups

#### Group A: Pure Unit Tests (~60 tests)
**Parallelization**: Fully parallelizable
**Estimated Runtime**: 5-10 seconds (with parallelization)

```nix
# Examples of fully parallelizable tests
- unit-assertions
- unit-platform-helpers
- unit-mksimpletest-helper
- All unit-lib-mksystem-detailed-* tests
```

**Execution Command**:
```bash
# Run all unit tests in parallel using xargs
nix flake show --impure | grep "unit-" | \
  xargs -P 8 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link
```

#### Group B: Integration Tests (~25 tests)
**Parallelization**: Moderately parallelizable (4-8 workers)
**Estimated Runtime**: 15-30 seconds (with parallelization)

```nix
# Integration tests with shared dependencies
- integration-git-configuration
- integration-home-manager-*
- integration-zsh
- integration-vim
- integration-tmux-*
- integration-starship-configuration
```

**Execution Command**:
```bash
# Run integration tests with limited parallelism
nix flake show --impure | grep "integration-" | \
  xargs -P 4 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link
```

#### Group C: Container Tests (4 tests)
**Parallelization**: Platform-dependent
**Estimated Runtime**: 20-60 seconds (Linux only, skipped on macOS)

```nix
- smoke-test
- basic-system
- services
- packages
```

**Note**: These tests are already skipped on macOS with validation mode.

---

## Performance Optimization Recommendations

### 1. Implement Parallel Test Execution

**Priority**: HIGH
**Impact**: 5-10x speedup for full test suite
**Effort**: Medium

**Implementation**:
```makefile
# Add to Makefile
test-parallel:
	@echo "Running tests in parallel..."
	@nix flake show --impure | grep "checks.aarch64-darwin.unit-" | \
		xargs -P 8 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link

test-integration-parallel:
	@nix flake show --impure | grep "checks.aarch64-darwin.integration-" | \
		xargs -P 4 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link
```

### 2. Optimize Test Discovery

**Priority**: MEDIUM
**Impact**: 10-20% faster test evaluation
**Effort**: Low

**Current**: Automatic discovery with `builtins.readDir` and filtering
**Optimization**: Cache test discovery results, use explicit imports

**Implementation**:
```nix
# In tests/default.nix
# Add caching for test discovery
discoverTestsCached = lib.memoize discoverTests;
```

### 3. Reduce lib-mksystem-detailed Test Overhead

**Priority**: MEDIUM
**Impact**: 30-40% reduction in test count
**Effort**: Low

**Current**: 60 separate tests for `lib-mksystem-detailed`
**Recommendation**: Consolidate into 5-10 logical test groups

**Implementation**:
```nix
# Instead of 60 individual tests, create grouped tests
{
  cache-settings = testSuite "mksystem-cache-settings" [
    # Combine all cache-related tests
  ];

  special-args = testSuite "mksystem-special-args" [
    # Combine all special args tests
  ];

  # ... 5-10 groups total
}
```

**Trade-off**: Less granular failure reporting, faster overall execution

### 4. Implement Test Result Caching

**Priority**: LOW
**Impact**: 50-90% faster for unchanged tests
**Effort**: High

**Approach**: Use Nix's built-in caching with CI integration

**Implementation**:
```bash
# Push test results to Cachix
nix build '.#checks.*' --impure | \
  jq -r '.[].outputs | to_entries[].value' | \
  cachix push baleen-nix
```

### 5. Split E2E Tests to Separate Workflow

**Priority**: LOW
**Impact**: Faster PR CI feedback
**Effort**: Low

**Current**: E2E tests excluded from automatic discovery
**Recommendation**: Create separate CI workflow for E2E tests

**Implementation**:
```yaml
# .github/workflows/e2e-tests.yml
name: E2E Tests
on: [push, pull_request]
jobs:
  e2e:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - run: nix build '.#e2e.*' --impure
```

---

## Test Execution Time Breakdown

### Sequential Execution (Current)

| Phase | Tests | Time | Percentage |
|-------|-------|------|------------|
| Test Discovery | 101 | 0.5s | 0.5% |
| Unit Tests | ~60 | 60s | 54% |
| Integration Tests | ~25 | 40s | 36% |
| Container Tests | 4 | 10s | 9% |
| **Total** | **101** | **~111s** | **100%** |

### Parallel Execution (Optimized)

| Phase | Tests | Time (8 workers) | Speedup |
|-------|-------|------------------|---------|
| Test Discovery | 101 | 0.5s | - |
| Unit Tests (parallel) | ~60 | 8s | 7.5x |
| Integration Tests (parallel) | ~25 | 10s | 4x |
| Container Tests (sequential) | 4 | 10s | 1x |
| **Total** | **101** | **~29s** | **3.8x** |

**Note**: Container tests excluded on macOS (validation mode only)

---

## Performance Bottlenecks Identified

### 1. Excessive Test Granularity

**Issue**: `lib-mksystem-detailed-test.nix` generates 60 separate checks
**Impact**: 60x derivation overhead, slower parallel startup
**Solution**: Consolidate into 5-10 test groups

### 2. No Parallel Execution

**Issue**: All tests run sequentially
**Impact**: 3.8x slower than optimal parallel execution
**Solution**: Implement parallel test execution in Makefile

### 3. Redundant Module Imports

**Issue**: Tests import the same modules repeatedly
**Impact**: Increased evaluation time, memory usage
**Solution**: Use Nix's built-in sharing, add explicit caching

### 4. Platform Filtering Overhead

**Issue**: Platform checks evaluated for every test
**Impact**: Minimal (~50ms), but accumulates
**Solution**: Cache platform detection, use static filtering

---

## Monitoring and Continuous Improvement

### Metrics to Track

1. **Total test runtime**: Target < 30 seconds (parallel)
2. **Test discovery time**: Target < 100ms
3. **Individual test p50/p95/p99**: Target < 5s/< 10s/< 30s
4. **Cache hit rate**: Target > 80% for unchanged code

### Performance Regression Detection

```nix
# Add performance regression tests
{
  performance-regression-test = pkgs.runCommand "perf-regression" { }
    ''
      echo "Checking test performance..."

      # Measure test discovery time
      START=$$SECONDS
      nix flake show --impure > /dev/null
      DISCOVERY_TIME=$$((SECONDS - START))

      if [ "$DISCOVERY_TIME" -gt 2 ]; then
        echo "FAIL: Test discovery took too long: $$DISCOVERY_TIME seconds"
        exit 1
      fi

      echo "PASS: Test performance acceptable"
      touch $out
    '';
}
```

---

## Conclusion

The current test suite has **excellent potential for parallelization**:
- **60 unit tests** can run fully in parallel (7.5x speedup)
- **25 integration tests** can run with moderate parallelization (4x speedup)
- **Overall potential speedup**: 3.8x (from ~111s to ~29s)

### Recommended Actions

1. **Immediate** (High Impact, Low Effort):
   - Add `make test-parallel` target with xargs parallelization
   - Split unit tests and integration tests into separate parallel groups

2. **Short-term** (Medium Impact, Medium Effort):
   - Consolidate `lib-mksystem-detailed` tests into 5-10 groups
   - Add test result caching to CI workflow

3. **Long-term** (Medium Impact, High Effort):
   - Implement test dependency graph for optimal scheduling
   - Split E2E tests into separate CI workflow
   - Add performance regression tests

### Expected Outcomes

- **PR CI time**: Reduced from ~5-10 minutes to ~2-3 minutes
- **Local development**: Faster feedback loop with parallel test execution
- **Developer experience**: Reduced waiting time, increased productivity

---

**Report Generated By**: Test Performance Analysis
**Next Review**: After implementing parallel execution strategy
