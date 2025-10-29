# VM Testing Design: Simple Local + Comprehensive CI

**Date:** 2025-10-29
**Status:** Approved
**Approach:** Hybrid Two-Path (Local=Fast, CI=Comprehensive)

## Problem Statement

Need to test NixOS VM configurations to ensure they build and work correctly. Requirements:
- **Local:** Fast feedback for development iteration
- **CI:** Comprehensive validation on all PRs
- **Simplicity:** Minimal complexity, leverage existing infrastructure

## Design Overview

### Two-Path Architecture

```
Developer Actions
      |
      ├─── LOCAL PATH ────────────────┐
      |    make test-vm-quick         |
      |    (30 seconds)                |
      |    Configuration Check         |
      |    - Build validation          |
      |    - Config integrity          |
      |                                |
      └─── CI PATH ───────────────────┤
           GitHub Actions              |
           (5-10 minutes)              |
           Full VM Test Suite          |
           - Build + Generate          |
           - Boot VM                   |
           - Service checks            |
```

**Key Principle:** Fast local feedback + comprehensive CI validation

## Implementation Components

### 1. Local Workflow

**Quick Validation (Existing):**
```bash
make test-vm-quick  # 30 seconds
```

**Implementation:**
- Uses existing `nix build .#checks.<system>.unit-vm-analysis`
- Validates VM configuration can be built
- Checks essential service configuration (Docker, SSH)
- No actual VM boot → fast iteration

**Full Test (Optional):**
```bash
make test-vm  # 5-10 minutes
```

**Development Loop:**
1. Edit VM config (`machines/nixos/vm-shared.nix`)
2. Run `make test-vm-quick` (30s feedback)
3. Commit if passing
4. Push → CI runs full validation

### 2. CI Integration

**New Job: `vm-test`**

**Placement:** Parallel with `build-switch` and `test` jobs, after `validate`

**Configuration:**
```yaml
vm-test:
  name: VM Testing (NixOS)
  needs: validate
  runs-on: ubuntu-latest
  if: (github.event.pull_request.draft != true) || (github.ref == 'refs/heads/main')

  steps:
    - uses: actions/checkout@v4

    - name: Setup Nix with KVM
      uses: ./.github/actions/setup-nix
      with:
        enable-kvm: 'true'

    - name: Run VM tests
      timeout-minutes: 15
      run: |
        export USER=${USER:-ci}
        nix build --impure .#checks.x86_64-linux.vm-test-suite
        cat result || true
```

**Execution Conditions:**
- All PRs (except drafts)
- All pushes to main branch
- After validation job succeeds

**Timeout:** 15 minutes (actual: 5-10 minutes)

### 3. Test Suite Components

**Existing Tests (tests/e2e/nixos-vm-test.nix):**

1. **vm-build-test** - VM configuration builds successfully
2. **vm-generation-test** - VM image generation (qcow format)
3. **vm-execution-test** - VM boots and basic operations work
4. **vm-service-test** - SSH, users, Docker configured properly
5. **platform-validation-test** - Platform compatibility checks
6. **vm-config-integrity-test** - Configuration integrity validation

**Required Work:**
- Expose these tests in `flake.nix` checks
- Currently exist but not integrated into `nix flake check`

### 4. Flake Integration

**Changes to flake.nix:**

```nix
outputs = inputs@{ self, nixpkgs, ... }: {
  checks = {
    # Existing checks for darwin platforms...

    # VM tests (x86_64-linux only)
    x86_64-linux = nixpkgs.lib.recursiveUpdate
      (existingChecks.x86_64-linux or {})
      {
        vm-test-suite = (import ./tests/e2e/nixos-vm-test.nix {
          inherit lib;
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          system = "x86_64-linux";
          self = self;
        }).vm-test-suite;
      };
  };
};
```

**Why x86_64-linux only:**
- CI runners are x86_64 with KVM support
- Cross-compilation from Darwin works but no native execution
- Can add aarch64-linux later if needed

## Error Handling

### Local Failures

```bash
$ make test-vm-quick
⚡ Configuration validation only (30 seconds)...
error: VM configuration has issues:
  - Docker service not properly configured
  - Missing required package: openssh
```

**Response:** Developer fixes config immediately with fast feedback

### CI Failures

**Display:**
- GitHub Actions check fails
- Error visible in PR checks
- Logs accessible via workflow run

**Strategy:**
- No automatic retries (config errors should be fixed, not retried)
- Clear error messages from Nix build output
- Link to logs in CI summary

## Platform Support

**Primary Target:** x86_64-linux
- CI has KVM support
- Most common NixOS deployment target
- Existing test infrastructure supports it

**Future Extensions:**
- aarch64-linux (ARM64 servers)
- Cross-platform testing matrix

## Testing Strategy

### Development Phase
1. Run `make test-vm-quick` frequently (30s)
2. Fix issues immediately with fast feedback
3. Optional: Run full `make test-vm` before committing

### CI Phase
1. All tests run on every PR
2. Must pass before merge
3. Comprehensive validation (build, generate, boot, services)

### Coverage
- ✅ Configuration validity
- ✅ VM image generation
- ✅ Boot process
- ✅ Service configuration (SSH, Docker, users)
- ✅ Platform compatibility

## Success Criteria

**Local:**
- `make test-vm-quick` completes in <30 seconds
- Clear error messages for misconfigurations
- No false positives

**CI:**
- VM tests run on all PRs
- Complete in <10 minutes
- Catch configuration errors before merge
- No flaky tests

**Overall:**
- Developers get fast feedback locally
- CI provides comprehensive validation
- Simple to maintain (no custom scripts)
- Easy to extend with new tests

## Alternative Approaches Considered

### Approach 1: Nix-Native Everywhere
- Same tests local and CI
- Rejected: Too slow for local development

### Approach 2: Shell Script Orchestration
- Custom scripts with detailed progress
- Rejected: Added complexity without clear benefit

### Approach 3: Hybrid (Chosen)
- Fast local validation
- Comprehensive CI testing
- Simple Nix-native implementation
- Best balance of speed and coverage

## Implementation Plan

1. **Flake Integration** - Expose VM tests in checks
2. **CI Job Addition** - Add `vm-test` job to workflow
3. **Makefile Verification** - Ensure `test-vm-quick` works
4. **Documentation** - Update CLAUDE.md with VM testing workflow
5. **Testing** - Verify on test branch before merging

## Maintenance

**Low Maintenance:**
- No custom scripts to maintain
- All Nix declarative configuration
- Leverages existing test framework
- GitHub Actions handles orchestration

**Future Enhancements:**
- Add more test cases as needed
- Support additional architectures
- Performance optimization if needed

## References

- Existing: `tests/e2e/nixos-vm-test.nix`
- Existing: `machines/nixos/vm-shared.nix`
- Existing: `.github/workflows/ci.yml`
- Makefile: Lines 102-109 (VM test commands)
