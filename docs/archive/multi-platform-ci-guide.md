# Multi-Platform CI Implementation Guide

**Practical guide for implementing consistent multi-platform testing**

## Quick Start

### Goal
Achieve consistent behavior ("똑같이") between local macOS development and GitHub Actions CI for multi-platform Nix builds.

### Strategy
Use **Hybrid Approach**: linux-builder locally + matrix builds in CI

---

## Part 1: Local Setup (Enable linux-builder)

### Step 1: Add Configuration

**File**: `/Users/baleen/dotfiles/users/shared/darwin.nix`

Add this configuration:

```nix
{ config, pkgs, lib, ... }:
{
  # ... existing darwin configuration ...

  # Linux builder for cross-platform development
  nix.linux-builder = {
    enable = true;

    # Support both x86_64 and aarch64 Linux
    systems = [ "x86_64-linux" "aarch64-linux" ];

    # Ephemeral mode: clean VM state for each build
    ephemeral = true;

    # VM configuration
    config = { lib, ... }: {
      # Enable cross-architecture emulation
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      virtualisation = {
        # Allocate more resources for faster builds
        cores = 6;                              # Use 6 CPU cores
        memorySize = lib.mkForce (1024 * 8);   # 8GB RAM
        diskSize = lib.mkForce (1024 * 16);    # 16GB disk
      };
    };
  };

  # Enable NixOS testing features
  nix.settings = {
    system-features = [ "nixos-test" "apple-virt" "kvm" ];

    # Trust linux-builder as a remote builder
    trusted-users = [ "@admin" config.users.users.${builtins.getEnv "USER"}.name ];
  };
}
```

### Step 2: Apply Configuration

```bash
# Rebuild system with linux-builder
make switch

# Or manually:
darwin-rebuild switch --flake .#macbook-pro
```

### Step 3: Verify Installation

```bash
# Check builder configuration
nix show-config | grep builders

# Should show something like:
# builders = ssh-ng://linux-builder x86_64-linux,aarch64-linux ...

# Test the builder
nix build --impure --expr '
  (with import <nixpkgs> { system = "x86_64-linux"; };
   runCommand "test" {} "uname -a > $out")
'

# Check result
cat result
# Should show: Linux ... x86_64 GNU/Linux
```

### Step 4: Build Linux Configurations

```bash
# Build NixOS configuration using linux-builder
nix build .#nixosConfigurations.vm-test.config.system.build.toplevel

# Build specific packages for Linux
nix build .#packages.x86_64-linux.hello

# Test VM
make test-vm
```

### Troubleshooting Local Setup

**Issue**: Builder not starting

```bash
# Check service status
launchctl list | grep linux-builder

# Check logs
log show --predicate 'subsystem == "org.nixos.linux-builder"' --last 10m

# Restart service
sudo launchctl stop org.nixos.linux-builder
sudo launchctl start org.nixos.linux-builder
```

**Issue**: Permission denied

```bash
# Fix SSH permissions
chmod 600 ~/.ssh/builder_ed25519
chmod 600 ~/.ssh/builder_ed25519.pub

# Verify user is trusted
nix show-config | grep trusted-users
```

**Issue**: VM not found

```bash
# Rebuild darwin configuration
make switch

# Check if VM files exist
ls -la /var/lib/linux-builder/
```

---

## Part 2: Enhanced CI Configuration

### Option A: Simple Matrix (Recommended)

**File**: `.github/workflows/ci.yml`

Add to your existing workflow:

```yaml
build-switch:
  name: Build+Switch ${{ matrix.name }}
  needs: validate
  if: (github.event.pull_request.draft != true) || (github.ref == 'refs/heads/main')
  strategy:
    fail-fast: false
    matrix:
      include:
        # Primary platform: macOS (Darwin)
        - name: Darwin (Apple Silicon)
          system: aarch64-darwin
          os: macos-15
          config: darwinConfigurations.macbook-pro.system
          primary: true

        # Secondary platform: NixOS (Intel)
        - name: NixOS (Intel)
          system: x86_64-linux
          os: ubuntu-latest
          config: nixosConfigurations.vm-test.config.system.build.toplevel

        # Optional: NixOS (ARM) - only if you have ARM configurations
        # Warning: Uses QEMU emulation, much slower
        # - name: NixOS (ARM)
        #   system: aarch64-linux
        #   os: ubuntu-latest
        #   config: nixosConfigurations.pi.config.system.build.toplevel
        #   qemu: true

  runs-on: ${{ matrix.os }}
  steps:
    - uses: actions/checkout@v4

    - name: Setup Nix with cache
      uses: ./.github/actions/setup-nix
      with:
        enable-kvm: ${{ runner.os == 'Linux' }}

    # Set up QEMU for ARM emulation (if needed)
    - name: Set up QEMU
      if: matrix.qemu == true
      uses: docker/setup-qemu-action@v3
      with:
        platforms: arm64

    - name: Build ${{ matrix.name }}
      timeout-minutes: ${{ matrix.qemu && 90 || 60 }}
      run: |
        export USER=${USER:-ci}
        echo "🏗️ Building ${{ matrix.name }} (${{ matrix.system }})"

        # Build the configuration
        nix build --impure .#${{ matrix.config }} --show-trace

        # Show what was built
        nix path-info --recursive ./result | tail -10

    - name: Run integration tests
      if: matrix.primary
      run: |
        export USER=${USER:-ci}
        make test-integration

    - name: Upload to Cachix
      if: github.ref == 'refs/heads/main' || startsWith(github.ref, 'refs/tags/')
      run: |
        nix profile install nixpkgs#cachix
        nix path-info --json --all | jq -r '.[].storePath' | cachix push baleen-nix
```

### Option B: With nixbuild.net (Faster)

**File**: `.github/workflows/ci-fast.yml`

Create a new workflow for faster builds (optional):

```yaml
name: CI (Fast - nixbuild.net)

on:
  pull_request:
    types: [opened, synchronize, reopened]
  workflow_dispatch:

jobs:
  build-all:
    name: Build All Platforms (Remote)
    runs-on: ubuntu-latest
    # Only run on draft PRs or when explicitly triggered
    if: github.event.pull_request.draft == true || github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4

      - name: Install Nix (Quick)
        uses: nixbuild/nix-quick-install-action@v28

      - name: Setup nixbuild.net
        uses: nixbuild/nixbuild-action@v20
        with:
          nixbuild_token: ${{ secrets.NIXBUILD_TOKEN }}

      - name: Build All Configurations
        run: |
          export USER=${USER:-ci}

          echo "🏗️ Building Darwin configuration..."
          nix build --impure .#darwinConfigurations.macbook-pro.system

          echo "🏗️ Building NixOS configurations..."
          nix build --impure .#nixosConfigurations.vm-test.config.system.build.toplevel

          echo "✅ All builds completed"

      - name: Show build results
        run: |
          echo "📊 Build outputs:"
          find . -name result -type l -exec readlink {} \;

      - name: Upload to Cachix
        if: github.event_name == 'workflow_dispatch'
        run: |
          nix profile install nixpkgs#cachix
          nix path-info --json --all | jq -r '.[].storePath' | cachix push baleen-nix
```

### Setup nixbuild.net (if using Option B)

1. Sign up at [nixbuild.net](https://nixbuild.net/) (free tier: 25 CPU hrs/month)

2. Get SSH token:
   ```bash
   # Follow nixbuild.net instructions to get token
   # Add to GitHub Secrets as NIXBUILD_TOKEN
   ```

3. Configure locally (optional):
   ```bash
   # ~/.config/nix/nix.conf
   builders = ssh://eu.nixbuild.net x86_64-linux,aarch64-linux - 100 1 big-parallel,benchmark
   builders-use-substitutes = true
   ```

4. Test locally:
   ```bash
   nix build .#nixosConfigurations.vm-test.system
   # Should use remote builder
   ```

---

## Part 3: Makefile Updates

Add helper commands for multi-platform workflows:

**File**: `Makefile`

```makefile
# Multi-platform build targets
.PHONY: build-all-platforms build-linux test-linux-builder

# Build all platforms (local)
build-all-platforms: ## Build all platform configurations
	@echo "🏗️ Building all platforms..."
	@echo "📦 Darwin (native)..."
	$(MAKE) build-darwin
	@echo "📦 Linux (via linux-builder)..."
	$(MAKE) build-linux
	@echo "✅ All platforms built"

# Build Linux configuration specifically
build-linux: ## Build NixOS configuration via linux-builder
	@echo "🐧 Building Linux configuration..."
	nix build --impure .#nixosConfigurations.vm-test.config.system.build.toplevel
	@echo "✅ Linux build completed"

# Test linux-builder setup
test-linux-builder: ## Test linux-builder is working
	@echo "🧪 Testing linux-builder..."
	@echo "1. Checking builder configuration..."
	@nix show-config | grep builders || echo "⚠️ No builders configured"
	@echo ""
	@echo "2. Building simple Linux derivation..."
	@nix build --impure --expr '(with import <nixpkgs> { system = "x86_64-linux"; }; runCommand "test" {} "uname -a > $$out")'
	@echo ""
	@echo "3. Result:"
	@cat result
	@echo ""
	@echo "✅ linux-builder is working!"

# Check which builder will be used
check-builders: ## Show configured builders
	@echo "🔍 Configured builders:"
	@nix show-config | grep -A 5 builders
	@echo ""
	@echo "🔍 System features:"
	@nix show-config | grep system-features
```

Usage:

```bash
make test-linux-builder    # Test linux-builder setup
make build-all-platforms   # Build all platforms locally
make check-builders        # Show builder configuration
```

---

## Part 4: Workflow Comparison

### Local Development Workflow

```bash
# Daily development (Darwin only)
make format
make build-current
make test-core

# Multi-platform testing (before PR)
make build-all-platforms    # Darwin + Linux
make test-vm                # Full VM tests

# Quick validation
make smoke                  # 30 seconds
```

### CI Workflow

```bash
# On push to PR:
1. validate (lint + quick tests)          # 1-2 min
2. build-switch (matrix: Darwin + Linux)  # 5-10 min each
3. test (comprehensive)                    # 10-15 min
4. vm-test (NixOS VM)                      # 10-15 min

# Total: ~25-35 minutes for full CI
```

### Performance Comparison

| Task | Local (linux-builder) | CI (native) | CI (QEMU) | nixbuild.net |
|------|----------------------|-------------|-----------|--------------|
| Darwin build | 5-10 min | 5-10 min | N/A | 2-5 min |
| Linux build | 10-15 min | 5-10 min | 30-60 min | 2-5 min |
| Total | 15-25 min | 10-20 min | 35-70 min | 4-10 min |

---

## Part 5: Validation & Testing

### Test Local Setup

```bash
# 1. Verify linux-builder is running
make test-linux-builder

# 2. Build actual configuration
nix build .#nixosConfigurations.vm-test.config.system.build.toplevel

# 3. Compare with CI output
# Local:
nix path-info ./result

# CI (from logs):
# Should show same store paths (proves reproducibility)
```

### Test CI Setup

```bash
# 1. Create test PR
git checkout -b test/multi-platform-ci
git commit --allow-empty -m "test: validate multi-platform CI"
git push -u origin test/multi-platform-ci

# 2. Watch CI workflow
gh pr view --web

# 3. Check build logs
gh run view --log

# 4. Verify all matrix jobs succeed
```

### Validate Reproducibility

```bash
# Build locally
nix build .#nixosConfigurations.vm-test.config.system.build.toplevel
LOCAL_PATH=$(readlink result)
echo "Local: $LOCAL_PATH"

# Get CI path from logs
# Should match (same hash)

# Verify contents
nix path-info --recursive "$LOCAL_PATH" | sort > local.txt
# Compare with CI output
```

---

## Part 6: Troubleshooting

### Common Issues

#### Issue: linux-builder VM won't start

**Symptoms**: Build hangs at "connecting to linux-builder"

**Solutions**:

```bash
# Check if VM is running
ps aux | grep linux-builder

# Check launchd service
launchctl list | grep linux-builder

# Restart service
sudo launchctl stop org.nixos.linux-builder
sudo launchctl start org.nixos.linux-builder

# Check logs
tail -f /var/log/linux-builder.log
```

#### Issue: CI build fails with "builder refused connection"

**Symptoms**: Ubuntu runner can't connect to builder

**Explanation**: This is expected in CI - linux-builder is local-only

**Solution**: Ensure matrix uses native runners, not linux-builder:
```yaml
- os: ubuntu-latest  # ✅ Native Linux
  # NOT: - os: macos-15 with linux-builder
```

#### Issue: Different store paths locally vs CI

**Symptoms**: Reproducibility mismatch

**Causes**:
- Different Nix versions
- Different nixpkgs commit
- Non-reproducible derivations

**Solutions**:

```bash
# 1. Pin Nix version (same as CI)
# flake.nix
{
  nixConfig = {
    extra-substituters = [ "https://cache.nixos.org" ];
    extra-trusted-public-keys = [ "cache.nixos.org-1:..." ];
  };
}

# 2. Lock nixpkgs version
nix flake update
git commit flake.lock -m "chore: update flake.lock"

# 3. Check for non-reproducible derivations
nix-diff ./result /nix/store/...-from-ci
```

#### Issue: QEMU build times out

**Symptoms**: ARM builds exceed 60 minutes

**Solutions**:

```yaml
# Increase timeout
timeout-minutes: 90

# Or disable ARM builds
# Comment out aarch64-linux matrix entry

# Or use remote builder
# Use nixbuild.net for ARM builds
```

#### Issue: Cachix push fails

**Symptoms**: "not authorized" error

**Solutions**:

```bash
# 1. Verify token is set
gh secret list
# Should show CACHIX_AUTH_TOKEN

# 2. Test token locally
cachix authtoken $CACHIX_AUTH_TOKEN
cachix push baleen-nix /nix/store/test-path

# 3. Check Cachix cache exists
# Visit: https://app.cachix.org/cache/baleen-nix
```

---

## Part 7: Best Practices

### Development Workflow

1. **Feature development**: Use `make build-current` (Darwin only, fastest)
2. **Before committing**: Run `make format && make test-core`
3. **Before PR**: Run `make build-all-platforms` (test Linux locally)
4. **After PR review**: Let CI validate both platforms

### CI Optimization

1. **Use matrix for free**: GitHub provides generous free minutes
2. **Cache aggressively**: Your current cache setup is good
3. **Fail fast**: Set `fail-fast: false` to see all failures
4. **Monitor build times**: If >10 min regularly, consider nixbuild.net

### Cost Management

**Free Tier Limits:**
- GitHub Actions: 2,000 min/month (Free plan), 3,000 min/month (Pro)
- macOS multiplier: 10x (6 min macOS = 60 min billed)
- Linux multiplier: 1x
- nixbuild.net: 25 CPU hours/month free

**Typical Usage (This Project):**
- Per PR: ~40 min total (10 min macOS × 10 + 10 min Linux × 1 + 20 min tests)
- Billed: ~110 minutes per PR
- **Monthly capacity**: ~18 PRs on Free tier, ~27 PRs on Pro tier

### Monitoring

```bash
# Check CI usage
gh api /repos/OWNER/REPO/actions/billing/usage

# Check cache hit rate
# From CI logs, look for:
# "Restored cache from key: nix-..."

# Monitor build times
gh run list --limit 20 --json conclusion,name,durationMs

# Alert on long builds
# If builds >15 min consistently, investigate
```

---

## Part 8: Migration Path

### Phase 1: Enable Locally (Week 1)

- [x] Add linux-builder to darwin.nix
- [x] Test local Linux builds
- [x] Update documentation
- [ ] Update Makefile with new commands

### Phase 2: Enhance CI (Week 2)

- [ ] Add Linux build to matrix
- [ ] Test in PR
- [ ] Monitor build times and success rate
- [ ] Adjust timeouts if needed

### Phase 3: Optimize (Month 2+)

- [ ] Review CI metrics (build times, cache hit rate, cost)
- [ ] Decide: Keep free tier or add nixbuild.net
- [ ] If using nixbuild.net: Configure locally + in CI
- [ ] Document final setup

### Rollback Plan

If linux-builder causes issues:

```nix
# users/shared/darwin.nix
nix.linux-builder.enable = false;  # Disable
```

If CI enhancement causes issues:

```yaml
# Revert to single Darwin build
strategy:
  matrix:
    include:
      - os: macos-15
        system: aarch64-darwin
```

---

## Summary

**Recommended Setup:**

| Component | Configuration | Why |
|-----------|--------------|-----|
| **Local** | linux-builder enabled | Test Linux locally, unified workflow |
| **CI** | Matrix (Darwin + Linux) | Free, reliable, native performance |
| **Future** | Add nixbuild.net if needed | Performance optimization path |

**Key Insights:**

1. ✅ **Can't use linux-builder in CI**: Nested virtualization blocked
2. ✅ **Don't need identical infra**: Nix reproducibility guarantees identical outputs
3. ✅ **Free tier is sufficient**: Matrix builds work well for dotfiles
4. ✅ **Local parity matters**: linux-builder gives great dev experience

**Next Steps:**

```bash
# 1. Enable linux-builder locally
make switch

# 2. Test it works
make test-linux-builder

# 3. Enhance CI (add Linux to matrix)
# Edit .github/workflows/ci.yml

# 4. Validate in PR
git push && gh pr create

# 5. Monitor and optimize
```

---

## References

- [Main Research Document](./research-linux-builder-ci.md)
- [nix-darwin linux-builder docs](https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/linux-builder.nix)
- [nixbuild.net documentation](https://docs.nixbuild.net/)
- [GitHub Actions billing](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions)
