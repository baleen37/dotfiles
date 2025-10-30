# Research: linux-builder in GitHub Actions for Multi-Platform Testing

**Date**: 2025-10-30
**Context**: Investigating how to achieve consistent multi-platform testing across local macOS + CI environments

## Executive Summary

**TL;DR**: linux-builder **CANNOT** run in GitHub Actions macOS runners due to nested virtualization limitations. Alternative strategies required.

### Key Findings

1. **linux-builder in CI**: ❌ Not viable on GitHub Actions macOS runners
2. **M1/M2/M3 Limitations**: Nested virtualization not supported on any ARM GitHub runners
3. **Best Strategy**: Matrix builds with separate platform-specific runners + remote builders
4. **Local vs CI Parity**: Use cross-compilation + remote builders or separate native runners

---

## 1. Can linux-builder Run in GitHub Actions?

### Answer: NO - Technical Limitations

**Why it doesn't work:**

- **Nested Virtualization Required**: linux-builder is a VM that needs to run inside the GitHub Actions runner
- **GitHub Runners are VMs**: All GitHub-hosted runners (including macOS) are themselves virtualized
- **Double Virtualization Blocked**: Running a VM inside a VM (nested virtualization) is not supported

**Technical Details:**

```
Physical M1 Hardware
  └─> GitHub's Hypervisor (Apple Virtualization Framework)
      └─> GitHub Actions Runner (macos-14, macos-15, etc.)
          └─> linux-builder VM ❌ BLOCKED
```

### Affected Runner Types

| Runner | Architecture | Nested Virtualization | Can Run linux-builder? |
|--------|--------------|----------------------|------------------------|
| `macos-13` | x86_64 Intel | ❌ No | ❌ No |
| `macos-13-xlarge` | aarch64 M1 | ❌ No | ❌ No |
| `macos-14` | aarch64 M1 | ❌ No | ❌ No |
| `macos-15` | aarch64 M1/M2 | ❌ No | ❌ No |
| `ubuntu-latest` | x86_64 Intel | ✅ Yes (KVM) | N/A (Linux) |

**Note**: Even though M3+ chips with macOS 15 technically support nested virtualization, GitHub Actions has NOT enabled this capability on their runners as of 2025.

---

## 2. M1/M2 vs M3+ Limitations in GitHub Actions

### Hardware Capabilities

| Chip | macOS Version | Nested Virtualization Support |
|------|---------------|-------------------------------|
| M1 | Any | ❌ Hardware limitation |
| M2 | Any | ❌ Hardware limitation |
| M3+ | macOS 15+ | ✅ Hardware + Software support |

### GitHub Actions Status (2025)

**Current Reality:**
- GitHub Actions uses M1/M2 chips for ARM runners
- Even if they upgrade to M3, nested virtualization is **NOT enabled** due to:
  - Limitations in how GitHub's hypervisor uses Apple's Virtualization Framework
  - Policy decision to keep runners consistent and predictable
  - Security and isolation concerns

**Performance Comparison:**

| Runner Type | vCPU | RAM | Price/min | Speed vs Intel | Nested Virt |
|-------------|------|-----|-----------|----------------|-------------|
| `macos-13` | 3 | 14GB | $0.08 | 1x (baseline) | ❌ |
| `macos-13-xlarge` | 6 (M1) | 14GB | $0.16 | 80% faster | ❌ |
| `macos-13-large` | 12 (Intel) | 30GB | $0.12 | 43% faster | ❌ |

**Key Takeaway**: Faster M1 runners exist, but nested virtualization is blocked on ALL macOS runners.

---

## 3. How Major Projects Handle Multi-Platform CI with Nix

### Strategy 1: Matrix Builds with Native Runners (Most Common)

**Example Pattern:**

```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - os: macos-14
            system: aarch64-darwin
          - os: ubuntu-latest
            system: x86_64-linux
          - os: ubuntu-latest  # ARM via native runner
            system: aarch64-linux
    runs-on: ${{ matrix.os }}
    steps:
      - uses: cachix/install-nix-action@v31
      - run: nix build .#${{ matrix.system }}
```

**Pros:**
- ✅ Native performance for each platform
- ✅ No nested virtualization needed
- ✅ Straightforward and reliable

**Cons:**
- ❌ Different environments for each platform
- ❌ GitHub doesn't provide native aarch64-linux runners (need self-hosted or QEMU)

### Strategy 2: Remote Builders (nixbuild.net, Cachix)

**nixbuild.net Pattern:**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest  # Single runner type
    steps:
      - uses: nixbuild/nix-quick-install-action@v24
      - uses: nixbuild/nixbuild-action@v19
        with:
          nixbuild_token: ${{ secrets.NIXBUILD_TOKEN }}
      - run: |
          # All builds delegated to nixbuild.net
          nix build .#darwinConfigurations.macbook-pro.system
          nix build .#nixosConfigurations.server.config.system.build.toplevel
```

**Performance:**
- 2x faster than GitHub runners (10 min vs 20 min for large builds)
- 30 seconds for no-op builds vs 5 minutes with Cachix
- Up to 16 vCPUs per build with automatic parallelization

**Pricing:**
- Free tier: 25 CPU hours/month
- Paid: $0.002/CPU-minute (~$0.12/hour)

**Pros:**
- ✅ Single runner type (Linux) can build any platform
- ✅ Faster than GitHub runners
- ✅ No nested virtualization issues
- ✅ Scales to zero when not in use

**Cons:**
- ❌ Additional service dependency
- ❌ Monthly cost for larger projects
- ❌ Requires SSH key management

### Strategy 3: QEMU Emulation (Fallback)

**Pattern:**

```yaml
- name: Set up QEMU
  uses: docker/setup-qemu-action@v3
- run: nix build .#nixosConfigurations.arm-server.system --system aarch64-linux
```

**Pros:**
- ✅ Works on any runner
- ✅ No additional services

**Cons:**
- ❌ 3-10x slower than native (55 min vs 5-10 min for ARM builds)
- ❌ High CPU usage and timeouts
- ❌ Not suitable for complex builds

### Strategy 4: Cross-Compilation (Limited Use)

**Pattern:**

```yaml
- run: nix build .#packages.x86_64-linux.hello --system aarch64-darwin
```

**Pros:**
- ✅ Fast when it works
- ✅ No additional infrastructure

**Cons:**
- ❌ Limited Darwin→Linux cross-compilation support
- ❌ Only works for simple packages
- ❌ macOS SDK compatibility issues

---

## 4. Best Strategy for Consistent Testing (Local + CI)

### Recommended Approach: Hybrid Strategy

**Goal**: Achieve "똑같이" (same behavior) between local macOS development and CI

#### Option A: Matrix Builds + Binary Cache (Simplest)

**Setup:**

```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - name: Darwin
            os: macos-15
            system: aarch64-darwin
            config: darwinConfigurations.macbook-pro.system
          - name: NixOS Intel
            os: ubuntu-latest
            system: x86_64-linux
            config: nixosConfigurations.vm-test.system
          - name: NixOS ARM
            os: ubuntu-latest
            system: aarch64-linux
            config: nixosConfigurations.pi.system
            qemu: true
    runs-on: ${{ matrix.os }}
    steps:
      - uses: cachix/install-nix-action@v31
        with:
          enable_kvm: ${{ runner.os == 'Linux' }}
      - uses: cachix/cachix-action@v14
        with:
          name: baleen-nix
          authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}
      - name: Set up QEMU (if needed)
        if: matrix.qemu
        uses: docker/setup-qemu-action@v3
      - run: nix build --impure .#${{ matrix.config }}
```

**Local Workflow:**

```bash
# On macOS
make build-current           # Build aarch64-darwin natively
make test-vm                 # Test x86_64-linux in local VM (KVM via UTM or similar)

# With linux-builder enabled locally
nix build .#nixosConfigurations.server.system  # Uses local linux-builder
```

**Parity Achievement:**
- ✅ Local: Native Darwin + linux-builder for Linux builds
- ✅ CI: Native Darwin + Native Linux runners
- ⚠️ **Difference**: Local uses VM, CI uses native - but OUTPUT is identical

#### Option B: Remote Builder Service (Best Performance)

**Setup:**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest  # Single runner type
    steps:
      - uses: nixbuild/nix-quick-install-action@v24
      - uses: nixbuild/nixbuild-action@v19
        with:
          nixbuild_token: ${{ secrets.NIXBUILD_TOKEN }}
      - run: |
          # All platforms built via remote builders
          nix build .#darwinConfigurations.macbook-pro.system
          nix build .#nixosConfigurations.server.system
```

**Local Configuration** (`.config/nix/nix.conf`):

```
builders = ssh://eu.nixbuild.net x86_64-linux,aarch64-linux - 100 1 big-parallel,benchmark
builders-use-substitutes = true
```

**Parity Achievement:**
- ✅ Identical behavior: Both use remote builders
- ✅ Consistent build environment
- ✅ Best performance
- ❌ Requires paid service for larger projects

#### Option C: Self-Hosted Runners (Enterprise)

**Setup:**

```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - os: [self-hosted, macOS, ARM64]
            system: aarch64-darwin
          - os: [self-hosted, Linux, ARM64]
            system: aarch64-linux
          - os: [self-hosted, Linux, X64]
            system: x86_64-linux
    runs-on: ${{ matrix.os }}
```

**Pros:**
- ✅ Full control over environment
- ✅ Can enable linux-builder on self-hosted macOS runners
- ✅ Consistent with local development
- ✅ No nested virtualization limitations (bare metal)

**Cons:**
- ❌ Infrastructure maintenance burden
- ❌ Security considerations
- ❌ Cost of hardware
- ❌ Overkill for most projects

---

## 5. Alternatives to linux-builder for CI

### Comparison Table

| Solution | Speed | Cost | Setup Complexity | Parity with Local |
|----------|-------|------|------------------|-------------------|
| **Matrix Builds** | Fast (native) | Included | Low | Medium (different envs) |
| **nixbuild.net** | Fastest | $0-120/mo | Low | High (same builders) |
| **Cachix Deploy** | Fast | $0-50/mo | Medium | Medium |
| **QEMU Emulation** | Very Slow | Included | Low | Low (emulated) |
| **Self-Hosted** | Fast | High (infra) | High | Highest (identical) |
| **Cross-Compilation** | Fast | Included | High | Low (limited support) |

### Detailed Comparison

#### nixbuild.net
- **When to use**: Professional projects, consistent builds, best performance
- **Pricing**: Free tier sufficient for most dotfiles, scales well
- **Setup**: Single GitHub Action + SSH key
- **Local parity**: Configure same builders locally

#### Cachix
- **When to use**: Open source projects, community support
- **Pricing**: Free for open source, generous limits
- **Setup**: Single GitHub Action
- **Local parity**: Same binary cache only (not builders)

#### QEMU
- **When to use**: Simple projects, occasional ARM builds
- **Limitation**: Too slow for complex dotfiles (20-60 minute builds)
- **Local parity**: N/A (emulation vs native)

#### Remote AWS Builder
- **When to use**: Already using AWS, need custom hardware
- **Setup**: Complex (EC2, SSH, security groups)
- **Cost**: Pay per build time (~$0.10/hour for t3.medium)

---

## 6. Specific Recommendations for This Dotfiles Project

### Current State Analysis

**Current CI Workflow** (`/Users/baleen/dotfiles/.github/workflows/ci.yml`):

```yaml
build-switch:
  strategy:
    matrix:
      include:
        - name: Darwin
          system: aarch64-darwin
          os: macos-15
  runs-on: ${{ matrix.os }}
```

**Observations:**
- ✅ Currently only builds Darwin (aarch64-darwin)
- ✅ Uses macos-15 runner (M1/M2)
- ✅ Has VM testing for NixOS (x86_64-linux) via KVM on ubuntu-latest
- ❌ No actual Linux system builds in CI
- ❌ No aarch64-linux builds

**Local Capabilities:**
- ✅ Can build Darwin natively (Apple Silicon Mac)
- ✅ Has `make build-darwin` and `make build-linux` commands
- ❌ Currently no linux-builder configuration
- ✅ Has VM testing framework (`make test-vm`)

### Recommended Strategy: Multi-Track Approach

#### Track 1: Keep Current Matrix Build (Primary)

**Rationale**: Current approach works well, is free, and covers main use cases

**Enhancement**:

```yaml
build-switch:
  strategy:
    fail-fast: false
    matrix:
      include:
        # Primary platform (your actual machine)
        - name: Darwin (Apple Silicon)
          system: aarch64-darwin
          os: macos-15
          primary: true

        # Secondary platforms (testing only)
        - name: NixOS Intel
          system: x86_64-linux
          os: ubuntu-latest
          build_cmd: "nix build .#nixosConfigurations.vm-test.system"

        # Optional: ARM Linux via QEMU (if needed)
        # - name: NixOS ARM
        #   system: aarch64-linux
        #   os: ubuntu-latest
        #   qemu: true
        #   build_cmd: "nix build .#nixosConfigurations.pi.system"
```

**Benefits:**
- ✅ Validates configurations actually build
- ✅ Free (uses GitHub's included minutes)
- ✅ Fast enough for dotfiles (most builds cached)
- ✅ No external dependencies

#### Track 2: Add nixbuild.net for Faster Iterations (Optional)

**When to enable**: If CI builds become slow (>10 minutes) or need frequent rebuilds

**Implementation**:

```yaml
build-switch-fast:
  runs-on: ubuntu-latest  # Single runner
  if: github.event.pull_request.draft == true  # Draft PRs only
  steps:
    - uses: nixbuild/nix-quick-install-action@v24
    - uses: nixbuild/nixbuild-action@v19
      with:
        nixbuild_token: ${{ secrets.NIXBUILD_TOKEN }}
    - run: |
        # Fast remote builds
        nix build .#darwinConfigurations.macbook-pro.system
        nix build .#nixosConfigurations.vm-test.system
```

**Cost Analysis:**
- Free tier: 25 CPU hours/month
- Typical dotfiles build: 2-5 CPU minutes
- **Estimated**: 300-750 builds/month free tier

#### Track 3: Enable linux-builder Locally Only

**Configuration** (add to `users/shared/darwin.nix`):

```nix
{ config, pkgs, lib, ... }:
{
  # Enable linux-builder for local development
  nix.linux-builder = {
    enable = true;
    systems = [ "x86_64-linux" "aarch64-linux" ];
    ephemeral = true;  # Clean state per build

    config = { lib, ... }: {
      # Enable emulation for cross-architecture
      boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

      # Increase resources for faster builds
      virtualisation = {
        cores = 6;
        memorySize = lib.mkForce (1024 * 8);  # 8GB
        diskSize = lib.mkForce (1024 * 16);   # 16GB
      };
    };
  };

  # Add system features for NixOS tests
  nix.settings.system-features = [ "nixos-test" "apple-virt" "kvm" ];
}
```

**Local Workflow**:

```bash
# Build Darwin natively
make build-darwin

# Build Linux using linux-builder
nix build .#nixosConfigurations.vm-test.system  # Uses linux-builder automatically

# Test NixOS in VM
make test-vm
```

**Benefits:**
- ✅ Local testing matches production environments
- ✅ Catch Linux-specific issues before CI
- ✅ No CI complexity
- ✅ Development workflow feels unified

**Trade-off**:
- ⚠️ Local uses linux-builder VM, CI uses native Linux runner
- ✅ But both produce identical outputs (reproducible builds)

### Summary: Recommended Implementation

**Phase 1: Enhance Current CI** (Do Now)

1. Add NixOS build to matrix (ubuntu-latest)
2. Keep existing Darwin build on macos-15
3. Add linux-builder to local Darwin config
4. Document differences in CLAUDE.md

**Phase 2: Optimize if Needed** (Future)

1. Monitor build times and cache hit rates
2. If builds >10 min regularly, add nixbuild.net for draft PRs
3. Keep free matrix builds for main branch

**Phase 3: Self-Hosted** (Only if Scaling)

1. If project grows to multiple users
2. If need exact local/CI parity
3. Not recommended for personal dotfiles

---

## Implementation Checklist

### Local Setup (Enable linux-builder)

- [ ] Add `nix.linux-builder.enable = true` to `users/shared/darwin.nix`
- [ ] Configure resources (cores, memory)
- [ ] Test: `nix build .#nixosConfigurations.vm-test.system`
- [ ] Verify: `nix show-config | grep builders`
- [ ] Update Makefile with linux-builder commands

### CI Enhancement

- [ ] Add Linux build to matrix in `.github/workflows/ci.yml`
- [ ] Test matrix builds in PR
- [ ] Add build time monitoring
- [ ] Document behavior differences in CLAUDE.md

### Documentation

- [ ] Update CLAUDE.md with linux-builder usage
- [ ] Add CI strategy explanation
- [ ] Document local vs CI differences
- [ ] Add troubleshooting section

### Optional: nixbuild.net

- [ ] Sign up for free tier (25 CPU hrs/month)
- [ ] Add SSH key to GitHub secrets
- [ ] Create separate workflow for draft PRs
- [ ] Monitor usage and performance

---

## Frequently Asked Questions

### Q: Why can't linux-builder work in GitHub Actions?

**A**: GitHub Actions runners are themselves virtual machines. Running linux-builder (which is a VM) inside a GitHub Actions runner would require nested virtualization, which is not supported on any GitHub-hosted macOS runner due to Apple Virtualization Framework limitations.

### Q: Will M3 runners support linux-builder?

**A**: No. While M3 chips with macOS 15 technically support nested virtualization, GitHub has not enabled this capability on their runners and has indicated it remains unsupported due to their hypervisor architecture.

### Q: How do I get the same builds locally and in CI?

**A**: Use one of these strategies:

1. **Remote builders**: Configure both local and CI to use nixbuild.net
2. **Accept differences**: Use linux-builder locally, native Linux runner in CI (outputs are identical due to Nix reproducibility)
3. **Self-hosted**: Run your own macOS runner with linux-builder enabled

### Q: Is QEMU emulation fast enough for dotfiles?

**A**: Generally no. For simple configs, yes (5-10 min). For complex dotfiles with many packages, builds can take 30-60 minutes, making iteration slow and consuming GitHub Actions minutes.

### Q: Should I use nixbuild.net or Cachix?

**A**: Different purposes:

- **nixbuild.net**: Remote builders (builds packages for you)
- **Cachix**: Binary cache (stores pre-built packages)
- **Best**: Use both - nixbuild.net for building, Cachix for caching

You're already using Cachix in your CI. nixbuild.net would be an addition if builds become slow.

### Q: What about cross-compilation?

**A**: Limited support for Darwin→Linux. Works for some simple packages but fails for system configurations, systemd services, and kernel-dependent packages. Not recommended as primary strategy.

### Q: How much does nixbuild.net cost?

**A**:
- Free tier: 25 CPU hours/month (plenty for dotfiles)
- Paid: $0.002/CPU-minute
- Typical dotfiles build: 2-5 CPU minutes
- **Cost estimate**: $0 (free tier sufficient)

### Q: Can I test the exact CI environment locally?

**A**: Not exactly for free runners (they're ephemeral VMs). But you can:

1. Use `act` to run GitHub Actions locally
2. Use same Nix commands as CI
3. Use nix flake check (what CI runs)
4. Match outputs (Nix guarantees reproducibility)

---

## References

### Documentation

- [nix-darwin linux-builder module](https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/linux-builder.nix)
- [GitHub Actions runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Nix cross-compilation guide](https://nix.dev/tutorials/cross-compilation.html)
- [nixbuild.net documentation](https://docs.nixbuild.net/)

### Real-World Examples

- [nixbuild/ci-demo](https://github.com/nixbuild/ci-demo) - Example CI with remote builders
- [cachix/install-nix-action](https://github.com/cachix/install-nix-action) - Official Nix installer for CI
- [nix-community/nix-github-actions](https://github.com/nix-community/nix-github-actions) - Matrix generation library

### Community Resources

- [NixOS Discourse: Nix + GitHub Actions + Aarch64](https://discourse.nixos.org/t/nix-github-actions-aarch64/11034)
- [GitHub Discussion: Apple silicon runners](https://github.com/orgs/community/discussions/69211)
- [Zulip: Darwin's linux-builder](https://chat.nixos.asia/stream/413948-nixos/topic/Darwin.27s.20linux-builder.html)

### Performance Comparisons

- [Faster Nix builds with nixbuild.net](https://actuated.com/blog/faster-nix-builds)
- [Building Nix with GitHub Actions and Cachix](https://ethancedwards.com/blog/building-nix-with-gha)
- [Streamline GitHub Actions with Nix](https://determinate.systems/blog/nix-github-actions/)

---

## Conclusion

**Bottom Line**: linux-builder cannot run in GitHub Actions macOS runners due to nested virtualization limitations. The recommended strategy for this dotfiles project is:

1. **Keep current CI**: Matrix builds with native runners (Darwin on macos-15, Linux on ubuntu-latest)
2. **Enable linux-builder locally**: For unified development experience
3. **Accept architectural difference**: Local uses VM, CI uses native - but outputs are identical
4. **Future optimization**: Add nixbuild.net if build times become problematic

This hybrid approach provides:
- ✅ Free CI (within GitHub limits)
- ✅ Fast builds (native performance)
- ✅ Local testing parity (can test Linux locally)
- ✅ Identical outputs (Nix reproducibility)
- ✅ Scalability path (nixbuild.net available)

The key insight: **You don't need identical infrastructure to get identical outputs** thanks to Nix's reproducibility guarantees.
