# Parallel Test Groups

This document defines the parallel execution strategy for the dotfiles test suite.

## Test Group Definitions

### Group 1: Pure Unit Tests (Fully Parallelizable)

**Worker Count**: 8
**Estimated Runtime**: 5-10 seconds
**Dependencies**: None (test-only, no external state)

```bash
# Execution command
nix flake show --impure 2>/dev/null | \
  grep -E "checks\.aarch64-darwin\.(unit-|smoke)" | \
  sed 's/.*\.//' | \
  xargs -P 8 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link
```

#### Tests in this group:

- `smoke`
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
- `unit-build-performance`
- `unit-test-runner-testRunnerBasic`
- `unit-test-runner-testRunnerFiltered`
- All `unit-lib-mksystem-detailed-*` tests (60 tests)
- All `unit-lib-user-info-*` tests
- All `unit-functions-*` tests

**Total**: ~60 tests

### Group 2: Integration Tests (Moderately Parallelizable)

**Worker Count**: 4
**Estimated Runtime**: 15-30 seconds
**Dependencies**: Shared module imports, but no state mutation

```bash
# Execution command
nix flake show --impure 2>/dev/null | \
  grep -E "checks\.aarch64-darwin\.integration-" | \
  sed 's/.*\.//' | \
  xargs -P 4 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link
```

#### Tests in this group:

- `integration-npm-global-path`
- `integration-git-configuration`
- `integration-home-manager-test`
- `integration-home-manager-git-config-generation`
- `integration-zsh`
- `integration-vim`
- `integration-tmux-functionality`
- `integration-starship-configuration`
- `integration-ghostty`
- `integration-karabiner`
- `integration-hammerspoon`
- `integration-opencode`
- `integration-claude-plugin`
- `integration-macos-optimizations`
- `integration-switch-user`
- `integration-build`
- And more...

**Total**: ~25 tests

### Group 3: Container Tests (Platform-Dependent)

**Worker Count**: 1 (sequential on macOS, parallel on Linux)
**Estimated Runtime**: Skipped on macOS, 20-60s on Linux
**Dependencies**: Linux VM/container infrastructure

```bash
# Execution command (Linux only)
nix flake show --impure 2>/dev/null | \
  grep -E "checks\.(aarch64-linux|x86_64-linux)\." | \
  grep -E "(smoke-test|basic|services|packages)" | \
  sed 's/.*\.//' | \
  xargs -P 1 -I {} nix build ".#checks.{}.{}" --impure --no-link
```

#### Tests in this group:

- `container-smoke`
- `basic`
- `services`
- `packages`

**Total**: 4 tests

**Note**: These are skipped on macOS with validation mode.

### Group 4: E2E Tests (Separate Workflow)

**Worker Count**: 1 (sequential)
**Estimated Runtime**: 5-15 minutes
**Dependencies**: VM infrastructure, external services

**Not included in automatic test discovery** - run manually or in separate CI workflow.

#### Tests in this group:

All tests in `tests/e2e/`:
- `build-switch-test.nix`
- `complete-vm-bootstrap-test.nix`
- `multi-user-support-test.nix`
- `package-management-test.nix`
- `secret-management-test.nix`
- `service-management-test.nix`
- `tool-integration-test.nix`
- `cache-configuration-test.nix`
- `cross-platform-build-test.nix`
- `machine-specific-config-test.nix`
- `system-factory-validation-test.nix`
- `environment-replication-test.nix`
- `fresh-machine-setup-test.nix`
- `real-project-workflow-test.nix`
- `comprehensive-suite-validation-test.nix`
- `optimized-vm-suite.nix`
- `vm-build-only-fallback.nix`

**Total**: ~16 tests

---

## Dependency Graph

```
Group 1 (Unit Tests) - No dependencies
├── Can run fully in parallel
└── Estimated: 5-10s with 8 workers

Group 2 (Integration Tests) - Depends on lib/* modules
├── Can run with moderate parallelism
├── Shared imports: lib/mksystem.nix, lib/user-info.nix
└── Estimated: 15-30s with 4 workers

Group 3 (Container Tests) - Depends on Linux infrastructure
├── Sequential on macOS (skipped)
├── Parallel on Linux
└── Estimated: 20-60s on Linux

Group 4 (E2E Tests) - Depends on VM infrastructure
├── Must run sequentially
├── Separate workflow
└── Estimated: 5-15 minutes
```

---

## Execution Strategies

### Strategy A: Fast Feedback (PR CI)

Run Groups 1 and 2 in parallel for quick feedback.

```bash
# Total time: ~20-40s
make test-parallel
```

### Strategy B: Full Validation

Run Groups 1, 2, and 3 for complete validation.

```bash
# Total time: ~40-90s (macOS), ~60-150s (Linux)
make test-all-parallel
```

### Strategy C: Comprehensive (Nightly CI)

Run all groups including E2E tests.

```bash
# Total time: ~5-15 minutes
make test-e2e
```

---

## Makefile Integration

```makefile
# Fast parallel test execution (PR CI default)
test-parallel:
	@echo "Running unit tests in parallel (8 workers)..."
	@nix flake show --impure 2>/dev/null | \
		grep -E "checks\.aarch64-darwin\.(unit-|smoke)" | \
		sed 's/.*\.//' | \
		xargs -P 8 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link
	@echo "Running integration tests in parallel (4 workers)..."
	@nix flake show --impure 2>/dev/null | \
		grep -E "checks\.aarch64-darwin\.integration-" | \
		sed 's/.*\.//' | \
		xargs -P 4 -I {} nix build ".#checks.aarch64-darwin.{}" --impure --no-link

# Full parallel test execution (including containers)
test-all-parallel: test-parallel
	@echo "Running container tests..."
	@if [ "$(UNAME)" = "Linux" ]; then \
		nix flake show --impure 2>/dev/null | \
			grep -E "checks\.(aarch64-linux|x86_64-linux)\." | \
			grep -E "(smoke-test|basic|services|packages)" | \
			sed 's/.*\.//' | \
			xargs -P 1 -I {} nix build ".#checks.{}.{}" --impure --no-link; \
	else \
		echo "Container tests skipped on macOS"; \
	fi

# E2E tests (separate workflow)
test-e2e:
	@echo "Running E2E tests..."
	@nix build '.#e2e.*' --impure
```

---

## Performance Targets

| Metric | Current | Target | Strategy |
|--------|---------|--------|----------|
| Unit test runtime | ~60s | < 10s | 8x parallelization |
| Integration test runtime | ~40s | < 20s | 4x parallelization |
| Full validation (macOS) | ~110s | < 40s | Combined strategy |
| Full validation (Linux) | ~130s | < 60s | Combined strategy |
| E2E test runtime | N/A | < 10min | Separate workflow |

---

## Monitoring and Metrics

### Track These Metrics

1. **Per-group execution time**
   - Unit tests: Target < 10s
   - Integration tests: Target < 20s
   - Container tests: Target < 30s

2. **Parallelization efficiency**
   - Speedup factor: Target > 3x
   - Worker utilization: Target > 70%

3. **Cache hit rates**
   - Unchanged tests: Target > 80%
    - CI builds: Target > 60%

### Regression Detection

```bash
# Benchmark test performance
time make test-parallel

# Should complete in < 30s on modern hardware
# If > 40s, investigate performance regression
```
