# Testing System Migration Guide

## Overview
Migrated from multi-tier testing to stable-only testing for faster, more reliable feedback.

## Key Changes

### Before
- Multiple test commands (test-unit, test-integration, test-e2e)
- Mixed stable/unstable tests
- CI ran different tests than local development
- Variable execution times (30s - 10+ minutes)

### After
- Single test command: `make test`
- Only stable, deterministic tests
- Identical execution locally and in CI
- Consistent <30 second execution time

## Test Categories Removed
- Network-dependent tests (external API calls)
- Time-sensitive tests (timeouts, delays)
- Resource-intensive tests (full VM builds in main test suite)
- External service integration (Docker, SSH connections)

## New Test Categories Added
- Flake syntax validation (all .nix files)
- Build possibility checks (dry-run only)
- Configuration file parsing validation
- Cross-platform compatibility checks

## Migration Checklist

### For Developers
- [ ] Use `make test` instead of `make test-all` for daily development
- [ ] Expect sub-30 second test execution
- [ ] Run `make test-vm` only when VM testing is specifically needed
- [ ] Report any test failures immediately (should be 100% reproducible)

### For CI/CD
- [ ] CI now runs identical `make test` command
- [ ] 60-second timeout enforced on stable tests
- [ ] VM tests moved to separate workflow or on-demand execution
- [ ] Caching strategy optimized for sub-minute test runs

## Troubleshooting

### Test Takes Longer Than 30 Seconds
1. Check if Nix store cache is being used
2. Verify no network calls are being made
3. Run `nix flake check --no-build` to isolate slow steps

### CI Passes but Local Fails (or vice versa)
1. This should not happen with stable-only testing
2. Check Nix version differences
3. Verify identical command execution
4. Report as a bug - system aims for 100% consistency

### Missing Test Coverage
1. If you need to test network-dependent features:
   - Create separate integration test outside main suite
   - Use manual testing approach
   - Consider if the feature is truly necessary

## Performance Expectations

| Platform | Expected Time | Actual Time | Status |
|----------|---------------|-------------|---------|
| aarch64-darwin | <30s | TBD | Measure |
| x86_64-linux | <30s | TBD | Measure |
| aarch64-linux | <30s | TBD | Measure |

## Rollback Plan

If needed, restore previous testing system:
```bash
git checkout <commit-before-migration>
mv .github/workflows/ci.yml .github/workflows/ci-stable.yml
mv .github/workflows/ci-original.yml .github/workflows/ci.yml
```
