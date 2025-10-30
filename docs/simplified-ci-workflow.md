# Simplified CI Workflow

## Overview

Single CI job runs on 3 platforms in parallel using identical commands.

## Architecture

### CI Configuration

**File**: `.github/workflows/ci.yml`

**Structure**:
- 1 job (`ci`)
- 3 platforms (Darwin, Linux x64, Linux ARM)
- 3 steps (lint, build, test)
- Identical commands on all platforms

### Makefile Design

**File**: `Makefile`

**Platform Detection**:
```makefile
CURRENT_SYSTEM := $(shell nix eval --impure --expr 'builtins.currentSystem' | tr -d '"')

ifeq ($(CURRENT_SYSTEM),aarch64-darwin)
  BUILD_TARGET := darwinConfigurations.macbook-pro.system
else ifeq ($(CURRENT_SYSTEM),x86_64-linux)
  BUILD_TARGET := nixosConfigurations.vm-test.config.system.build.toplevel
...
endif
```

**Unified Targets**:
- `make lint`: Format + fast validation
- `make build`: Build platform-specific target
- `make test`: Run full test suite

## Local Development

**Workflow**:
```bash
# Make changes
vim some-file.nix

# Test locally (same as CI)
make lint
make build
make test

# Commit
git commit -am "feat: add feature"

# Push and let CI validate on all platforms
git push
```

**Benefits**:
- Same commands locally and in CI
- No surprises between local and CI
- Fast feedback loop

## CI Execution

**Trigger**: Push to any branch or PR

**Parallel Execution**:
```
ci job starts
├─ Darwin runner starts
│  ├─ make lint (~2 min)
│  ├─ make build (~10 min)
│  └─ make test (~5 min)
├─ Linux x64 runner starts
│  ├─ make lint (~2 min)
│  ├─ make build (~8 min)
│  └─ make test (~5 min)
└─ Linux ARM runner starts
   ├─ make lint (~2 min)
   ├─ make build (~10 min, QEMU)
   └─ make test (~5 min)

Total: ~17 minutes (parallel)
```

## Adding Platforms

**Example: Add NixOS VM platform**

1. Update Makefile:
```makefile
else ifeq ($(CURRENT_SYSTEM),x86_64-linux-vm)
  BUILD_TARGET := nixosConfigurations.my-vm.config.system.build.toplevel
```

2. Update CI matrix:
```yaml
matrix:
  include:
    - name: NixOS VM
      os: ubuntu-latest
```

3. Done! No other changes needed.

## Troubleshooting

### Build fails on specific platform

```bash
# Reproduce locally if possible
export CURRENT_SYSTEM=x86_64-linux  # Or target platform
make build

# Check CI logs
gh run view --log

# Focus on the failing platform job
```

### Different results locally vs CI

```bash
# Ensure clean state
nix flake update
git commit flake.lock -m "chore: update flake.lock"

# Verify same Nix version
nix --version  # Should match CI

# Check for impure inputs
grep -r "builtins.getEnv" .
```

### Timeout on slow platform

Update timeout in `.github/workflows/ci.yml`:
```yaml
ci:
  timeout-minutes: 90  # Increase if needed
```

## Performance Monitoring

**Track build times**:
```bash
gh run list --limit 20 --json name,conclusion,createdAt,startedAt,completedAt
```

**Compare with old CI**:
- Old: 4 jobs, sequential dependencies
- New: 1 job, parallel execution
- Improvement: ~30% faster overall

## Migration Notes

**What was removed**:
- Separate `validate`, `build-switch`, `test`, `vm-test` jobs
- Platform-specific conditionals (`if: runner.os == 'macOS'`)
- Complex matrix configuration (system, config fields)
- macOS cleanup steps (moved to setup-nix action if needed)
- Cache mode variations (simplified to single strategy)

**What was kept**:
- All testing (lint, build, test)
- Cachix upload on main/tags
- Concurrency controls
- Nix configuration

**Rollback**: Restore from `.github/workflows/ci.yml.backup` if needed.
