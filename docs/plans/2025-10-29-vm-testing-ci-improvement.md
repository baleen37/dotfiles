# VM Testing CI Improvement Design

## Overview

Add comprehensive VM testing to GitHub Actions CI with simplified Makefile interface and essential caching for performance.

## Requirements

1. **CI Integration**: Run VM tests automatically on PRs
2. **Makefile Simplification**: Reduce to 2 commands only
3. **E2E Validation**: Ensure NixOS development VM works properly
4. **Caching**: Essential for performance

## Design

### Makefile Interface (Simplified)

```makefile
test-vm       # Full VM test (build + boot + E2E validation)
test-vm-quick # Configuration validation only (30 seconds)
```

**Removed commands:**
- `test-vm-full` → merged into `test-vm`
- `test-vm-analysis` → merged into `test-vm-quick`

### GitHub Actions Workflow

**Trigger:** PRs that modify VM-related files
- `machines/**/*.nix`
- `tests/**/*vm*`
- `Makefile`
- `flake.nix`

**Jobs:**
```yaml
vm-test:
  runs-on: ubuntu-latest-4-cores
  timeout-minutes: 15

  steps:
  - Setup KVM/QEMU
  - Build NixOS VM
  - Boot VM with port forwarding
  - Run E2E tests via SSH
  - Collect results
```

### Essential Caching Strategy

**Cachix Integration:**
- Nix store caching for dependencies
- VM build artifacts
- Test results caching

**Performance Targets:**
- CI execution: 10-12 minutes
- Local `test-vm`: 3-5 minutes
- Local `test-vm-quick`: 30 seconds

### E2E Test Scope (Minimal)

1. **VM Boot**: VM starts successfully
2. **SSH Access**: Can connect to localhost:2222
3. **Docker**: Docker daemon runs containers
4. **Development Tools**: Essential packages available

## Implementation Plan

### Phase 1: Makefile Simplification
- Remove `test-vm-full` and `test-vm-analysis`
- Consolidate logic into `test-vm` and `test-vm-quick`
- Update documentation

### Phase 2: CI Workflow
- Create GitHub Actions workflow
- Setup KVM/QEMU environment
- Implement VM testing pipeline
- Add Cachix caching

### Phase 3: E2E Tests
- Write automated test scripts
- SSH connection automation
- Service validation checks
- Result collection and reporting

## Files to Create/Modify

- `.github/workflows/vm-testing.yml` (new)
- `Makefile` (simplify existing)
- `scripts/vm-test-runner.sh` (new)
- `scripts/vm-e2e-tests.sh` (new)

## Success Criteria

- All VM tests pass in CI on PR
- Makefile has exactly 2 VM-related commands
- E2E validation covers NixOS development workflow
- CI runs under 15 minutes consistently

---

*Design approved: 2025-10-29*
