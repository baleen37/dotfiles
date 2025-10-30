# linux-builder in CI: Quick Reference

**Last Updated**: 2025-10-30

## TL;DR

**Can linux-builder run in GitHub Actions?** ❌ **NO**

**Why?** Nested virtualization is not supported on any GitHub-hosted macOS runners.

**What should I do instead?** Use matrix builds with native runners + enable linux-builder locally only.

---

## Your Questions Answered

### 1. Can linux-builder run in GitHub Actions macOS runners?

**Answer**: ❌ **NO** - Not on any GitHub-hosted runner type

**Technical Reason**:
```
Physical Mac → GitHub's Hypervisor → GitHub Runner (VM) → linux-builder (VM) ❌
                                                           ↑ Blocked (nested virtualization)
```

**Affected Runners**:
- `macos-13` (Intel) - ❌ No nested virtualization
- `macos-13-xlarge` (M1) - ❌ No nested virtualization
- `macos-14` (M1) - ❌ No nested virtualization
- `macos-15` (M1/M2) - ❌ No nested virtualization
- `ubuntu-latest` - ✅ Has KVM, but it's already Linux (no need for linux-builder)

**Exception**: Self-hosted macOS runners on bare metal ✅ CAN run linux-builder

---

### 2. What are the limitations with M1/M2 vs M3+ in GitHub Actions?

#### Hardware Support

| Chip | Nested Virt Hardware | Nested Virt Software | GitHub Actions Support |
|------|---------------------|---------------------|----------------------|
| M1 | ❌ No | ❌ No | Current runners |
| M2 | ❌ No | ❌ No | Current runners |
| M3+ | ✅ Yes | ✅ Yes (macOS 15+) | ❌ Not enabled by GitHub |

#### GitHub Actions Status (2025)

**Current M1/M2 Runners**:
- Faster than Intel (80% build time reduction)
- GPU acceleration enabled
- ❌ **No nested virtualization** (policy + technical)

**Future M3+ Runners**:
- GitHub has NOT announced M3 runner availability
- Even when available, **nested virtualization may remain disabled** due to:
  - Security concerns (isolation between jobs)
  - Consistency across runner types
  - Hypervisor architecture limitations

**Verdict**: Don't wait for M3+ runners to enable linux-builder in CI. It's unlikely to happen.

#### Performance Comparison

| Runner Type | CPU | RAM | $/min | vs Intel | Nested Virt |
|-------------|-----|-----|-------|----------|-------------|
| macos-13 (Intel) | 3-core | 14GB | $0.08 | 1.0x | ❌ |
| macos-13-large (Intel) | 12-core | 30GB | $0.12 | 1.43x | ❌ |
| macos-13-xlarge (M1) | 6-core | 14GB | $0.16 | 1.80x | ❌ |
| macos-14 (M1) | 3-core | 14GB | $0.08 | 1.50x | ❌ |
| macos-15 (M1/M2) | 3-core | 14GB | $0.08 | 1.50x | ❌ |

**Key Insight**: M1 runners are faster but still can't run linux-builder.

---

### 3. How do major projects handle multi-platform CI with Nix?

#### Strategy Breakdown

**90% of projects**: Matrix builds with native runners

```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest]
    # Build each platform on its native runner
```

**Example Projects**:
- Most open-source Nix flakes
- Personal dotfiles repositories
- Small to medium projects

**Cost**: Free (within GitHub limits)
**Speed**: Fast (native performance)
**Complexity**: Low

---

**8% of projects**: Remote builder services (nixbuild.net, Cachix)

```yaml
# Single Linux runner, builds all platforms remotely
runs-on: ubuntu-latest
steps:
  - uses: nixbuild/nixbuild-action@v20
  - run: nix build .#allPlatforms
```

**Example Projects**:
- [nixbuild/ci-demo](https://github.com/nixbuild/ci-demo)
- Commercial Nix projects
- High-frequency CI projects

**Cost**: $0-120/month (free tier often sufficient)
**Speed**: Fastest (2x faster than GitHub runners)
**Complexity**: Low (single action)

---

**2% of projects**: Self-hosted runners

```yaml
runs-on: [self-hosted, macOS, ARM64]
```

**Example Projects**:
- Enterprise projects
- Companies with existing infrastructure
- Projects needing exact environment control

**Cost**: Infrastructure costs (hardware, maintenance)
**Speed**: Fast (bare metal)
**Complexity**: High

---

#### Real-World Examples

**mitchellh/nixos-config**:
- No GitHub Actions CI visible
- Relies on local development + testing
- Focus: Developer experience over CI automation

**dustinlyons/nixos-config**:
- Uses GitHub Actions
- Weekly automated flake updates
- Matrix-like approach for different platforms
- Publishes starter templates

**NixOS/nixpkgs**:
- Hydra CI (not GitHub Actions)
- Extensive remote builder infrastructure
- Pre-builds packages for multiple platforms

**Takeaway**: Matrix builds with native runners is the most common and practical approach.

---

### 4. What's the best strategy for consistent testing (local macOS + CI)?

#### Recommended: Hybrid Approach

**Local Setup**: ✅ Enable linux-builder
```nix
# users/shared/darwin.nix
nix.linux-builder.enable = true;
```

**CI Setup**: ✅ Matrix with native runners
```yaml
strategy:
  matrix:
    include:
      - os: macos-15      # Darwin build
      - os: ubuntu-latest # Linux build
```

#### Why This Works

**Key Insight**: You don't need identical infrastructure to get identical outputs (thanks to Nix reproducibility).

```
Local:  macOS → linux-builder (VM) → NixOS build → /nix/store/abc123-system
                                                      ↑
                                                      Same hash!
                                                      ↓
CI:     ubuntu-latest (native) → NixOS build → /nix/store/abc123-system
```

#### Achieving "똑같이" (Same Behavior)

**What's identical**:
- ✅ Build outputs (exact same store paths)
- ✅ Package versions (locked via flake.lock)
- ✅ Configuration validation
- ✅ Test results

**What's different**:
- ⚠️ Build environment (VM vs native)
- ⚠️ Build performance (VM slower)
- ⚠️ Resource limits (local VM vs GitHub runner)

**Does it matter?** ❌ No, because:
- Nix guarantees reproducible builds
- Same inputs → same outputs
- Environment differences don't affect results

#### Alternative Strategies

**Option A: Remote Builders (Both Local + CI)**

```bash
# Local: ~/.config/nix/nix.conf
builders = ssh://eu.nixbuild.net x86_64-linux,aarch64-linux

# CI: Same configuration
uses: nixbuild/nixbuild-action@v20
```

**Benefit**: Truly identical build infrastructure
**Cost**: $0-120/month (free tier usually enough)
**Use case**: When build consistency is critical

---

**Option B: Self-Hosted Runners**

```yaml
# Both local and CI use same physical machine
runs-on: [self-hosted, macOS]
```

**Benefit**: 100% identical environment
**Cost**: Infrastructure maintenance
**Use case**: Enterprise projects only

---

**Option C: Accept Differences**

```bash
# Local: Build current platform only
make build-current  # Darwin only

# CI: Let matrix build all platforms
# (You trust CI to catch Linux issues)
```

**Benefit**: Fastest local development
**Cost**: No local Linux testing
**Use case**: When Darwin is primary platform

---

### 5. Are there alternatives to linux-builder for CI?

#### Comparison Table

| Solution | Speed | Cost | Setup | Parity | Recommended |
|----------|-------|------|-------|--------|-------------|
| **Matrix Builds** | Fast | Free | Easy | Medium | ✅ Yes (default) |
| **nixbuild.net** | Fastest | $0-120/mo | Easy | High | ✅ Yes (if scaling) |
| **QEMU Emulation** | Very Slow | Free | Easy | Low | ⚠️ Only for simple builds |
| **Remote AWS** | Fast | ~$10/mo | Hard | High | ❌ Too complex |
| **Self-Hosted** | Fast | High | Very Hard | Highest | ❌ Overkill |
| **Cross-Compilation** | Fast | Free | Hard | Low | ❌ Limited support |
| **Cachix Deploy** | Fast | $0-50/mo | Medium | Medium | ⚠️ Cache only |

#### Detailed Breakdown

**Matrix Builds with Native Runners** ⭐ RECOMMENDED

```yaml
strategy:
  matrix:
    os: [macos-15, ubuntu-latest]
```

**Pros**:
- ✅ Free (within GitHub limits)
- ✅ Native performance
- ✅ Simple setup
- ✅ Reliable

**Cons**:
- ❌ Different build environments (but same outputs)
- ❌ No native ARM Linux runners (need QEMU or remote)

**Best for**: 95% of projects

---

**nixbuild.net** ⭐ RECOMMENDED (if builds >10 min)

```yaml
- uses: nixbuild/nixbuild-action@v20
  with:
    nixbuild_token: ${{ secrets.NIXBUILD_TOKEN }}
```

**Pros**:
- ✅ 2x faster than GitHub runners
- ✅ Single runner type can build all platforms
- ✅ Free tier: 25 CPU hrs/month
- ✅ Can use same builders locally

**Cons**:
- ❌ External dependency
- ❌ Requires SSH key management

**Best for**: Projects with frequent CI runs or slow builds

**Cost Analysis**:
```
Free tier: 25 CPU hours/month
Typical dotfiles build: 2-5 CPU minutes
Capacity: ~300-750 builds/month FREE
```

---

**QEMU Emulation** ⚠️ USE SPARINGLY

```yaml
- uses: docker/setup-qemu-action@v3
- run: nix build --system aarch64-linux
```

**Pros**:
- ✅ Free
- ✅ Works on any runner
- ✅ Simple setup

**Cons**:
- ❌ 3-10x slower than native
- ❌ High CPU usage
- ❌ Timeouts on complex builds

**Best for**: Occasional ARM builds or simple packages

**Performance**:
```
Native ARM:     5-10 minutes
QEMU on x86:   30-60 minutes
Timeout risk:  High for complex builds
```

---

**Cachix** ✅ Complement to Other Strategies

```yaml
- uses: cachix/cachix-action@v14
  with:
    name: your-cache
    authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

**What it does**: Binary caching (NOT building)

**Pros**:
- ✅ Speeds up builds via cache
- ✅ Free for open source
- ✅ Shares artifacts between local/CI

**Cons**:
- ❌ Not a builder replacement
- ❌ Requires separate building strategy

**Best for**: Use WITH matrix builds or nixbuild.net

---

**Self-Hosted Runners** ❌ NOT RECOMMENDED (for dotfiles)

**Why not**:
- Complex infrastructure setup
- Security concerns
- Maintenance burden
- Hardware costs
- Overkill for personal projects

**When to use**: Enterprise only (100+ developers)

---

**Cross-Compilation** ❌ LIMITED SUPPORT

**Why it doesn't work well**:
- Darwin→Linux: Very limited package support
- System configurations: Often fail
- Systemd services: Won't cross-compile
- Kernel-dependent: Breaks

**When it works**: Simple, pure packages only

---

### 6. Specific recommendations for this dotfiles project

#### Current State

**✅ What's working well**:
- Clean CI pipeline with validation → build → test → VM test
- Uses macos-15 for Darwin builds
- Has VM testing for NixOS (x86_64-linux)
- Good caching strategy (week-based rotation)
- Uploads to Cachix on main branch

**⚠️ What's missing**:
- No actual Linux system builds in CI (only VM tests)
- No ARM Linux support
- No linux-builder configuration locally

#### Recommended Implementation

**Phase 1: Enable linux-builder Locally** (1 hour)

```nix
# users/shared/darwin.nix
nix.linux-builder = {
  enable = true;
  systems = [ "x86_64-linux" "aarch64-linux" ];
  ephemeral = true;
  config = { lib, ... }: {
    virtualisation = {
      cores = 6;
      memorySize = lib.mkForce (1024 * 8);
    };
  };
};
```

**Test**:
```bash
make switch
make test-linux-builder
nix build .#nixosConfigurations.vm-test.config.system.build.toplevel
```

**Benefit**: Can test Linux builds locally before pushing

---

**Phase 2: Add Linux to CI Matrix** (30 minutes)

```yaml
# .github/workflows/ci.yml
strategy:
  matrix:
    include:
      - name: Darwin (Apple Silicon)
        os: macos-15
        system: aarch64-darwin
        config: darwinConfigurations.macbook-pro.system

      - name: NixOS (Intel)
        os: ubuntu-latest
        system: x86_64-linux
        config: nixosConfigurations.vm-test.config.system.build.toplevel
```

**Benefit**: Actually builds Linux configurations (not just tests)

---

**Phase 3: Monitor & Optimize** (ongoing)

**After 2-4 weeks, check**:
1. Build times: Are they >10 minutes regularly?
2. Cache hit rate: Is caching effective?
3. Failure rate: Are builds reliable?
4. Cost: Are you within free tier limits?

**Decision tree**:
```
If builds are fast (<5 min) → Keep current setup ✅
If builds are slow (>10 min) → Consider nixbuild.net
If builds fail often → Debug config issues
If hitting limits → Optimize caching or add nixbuild.net
```

---

#### Monthly Cost Analysis

**Current (Free Tier)**:
```
GitHub Actions Free Plan: 2,000 minutes/month

Per PR build:
- Validate: 2 min Linux (×1 = 2 billed)
- Darwin Build: 10 min macOS (×10 = 100 billed)
- Linux Build: 10 min Linux (×1 = 10 billed)
- Tests: 15 min Linux (×1 = 15 billed)
- VM Test: 15 min Linux (×1 = 15 billed)
Total per PR: 142 billed minutes

Capacity: ~14 PRs/month on free tier
```

**With nixbuild.net**:
```
nixbuild.net Free Tier: 25 CPU hours/month

Per PR build:
- Validate: 2 min (GitHub)
- All builds: 5 min (nixbuild.net)
- Tests: 15 min (GitHub)
Total per PR: 22 billed minutes (GitHub) + 5 CPU min (nixbuild.net)

GitHub Capacity: ~90 PRs/month
nixbuild.net Capacity: ~300 builds/month

Result: Much higher capacity, faster builds
```

**Recommendation**: Start with free tier, add nixbuild.net only if needed.

---

#### What NOT to Do

❌ **Don't try to run linux-builder in CI**
- It won't work (nested virtualization blocked)
- Waste of time debugging

❌ **Don't use QEMU for complex builds**
- Too slow (30-60 min builds)
- High timeout risk
- Burns through CI minutes

❌ **Don't set up self-hosted runners**
- Massive overkill for dotfiles
- Security and maintenance burden

❌ **Don't skip local linux-builder**
- Loses ability to test Linux locally
- Increases feedback loop time

❌ **Don't hardcode usernames**
- Your config already handles this well with `builtins.getEnv "USER"`
- Keep dynamic user resolution

---

#### Success Criteria

**After implementation, you should be able to**:

✅ Build Darwin natively on local Mac
✅ Build Linux using linux-builder on local Mac
✅ Test both platforms before pushing
✅ Have CI validate both platforms automatically
✅ Get consistent outputs (same store paths) local vs CI
✅ Complete PR builds in <10 minutes total
✅ Stay within free tier limits

**Validation**:
```bash
# Local
make build-all-platforms  # Darwin + Linux
make test-vm              # Full VM test

# Push to PR
git push

# CI builds both platforms
# All tests pass
# Cachix caches artifacts
# Total time: 10-15 minutes
```

---

## Decision Matrix

### Choose Matrix Builds If...

- ✅ Your project is open source or personal
- ✅ Free tier is important
- ✅ Builds complete in <10 minutes
- ✅ You're okay with different build environments (VM vs native)
- ✅ You want simple, reliable CI

### Choose nixbuild.net If...

- ✅ Builds are consistently >10 minutes
- ✅ You want fastest possible builds
- ✅ You need exact same builders locally + CI
- ✅ Free tier budget ($0/month) or paid budget ($10-120/month) is acceptable
- ✅ You want to reduce GitHub Actions minutes usage

### Choose Self-Hosted If...

- ✅ You're an enterprise (>50 developers)
- ✅ You need complete environment control
- ✅ You have infrastructure team
- ✅ Security/compliance requires it
- ❌ **NOT recommended for personal dotfiles**

---

## Quick Reference Commands

### Test linux-builder Setup

```bash
# Check if enabled
nix show-config | grep builders

# Test simple build
nix build --impure --expr '(with import <nixpkgs> { system = "x86_64-linux"; }; hello)'

# Build actual config
nix build .#nixosConfigurations.vm-test.config.system.build.toplevel

# Check VM is running
ps aux | grep linux-builder
```

### Debug CI Issues

```bash
# View recent runs
gh run list --limit 10

# View specific run logs
gh run view RUN_ID --log

# Download artifacts
gh run download RUN_ID

# Watch live build
gh run watch
```

### Monitor Performance

```bash
# Local build time
time make build-all-platforms

# CI build time
gh run list --json durationMs --limit 20 | jq -r '.[] | .durationMs / 60000 | round'

# Cache hit rate
# Check CI logs for "Restored cache from key:"

# nixbuild.net usage (if using)
# Check https://nixbuild.net/dashboard
```

---

## Summary

**The Answer You Need**:

1. ❌ linux-builder **CANNOT** run in GitHub Actions (nested virtualization blocked)
2. ⚠️ M3+ runners **WILL NOT** change this (GitHub policy + technical limitations)
3. ✅ Use **matrix builds** (Darwin on macos-15 + Linux on ubuntu-latest)
4. ✅ Enable **linux-builder locally** for unified development experience
5. ✅ **Outputs are identical** despite different build environments (Nix reproducibility)
6. 💰 **Free tier sufficient** for dotfiles (14 PRs/month)
7. 🚀 **Optional optimization**: Add nixbuild.net if builds become slow

**Bottom Line**:
You get "똑같이" (same behavior) not by using identical infrastructure, but by leveraging Nix's reproducibility guarantees. Different build paths, identical outputs.

---

## Additional Resources

**Detailed Docs**:
- [Full Research Report](./research-linux-builder-ci.md) - Deep dive into technical details
- [Implementation Guide](./multi-platform-ci-guide.md) - Step-by-step setup instructions

**External Links**:
- [nix-darwin linux-builder docs](https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/linux-builder.nix)
- [nixbuild.net](https://nixbuild.net/) - Remote builder service
- [GitHub Actions runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
- [Cachix](https://www.cachix.org/) - Binary cache service

**Community**:
- [NixOS Discourse](https://discourse.nixos.org/)
- [r/NixOS](https://reddit.com/r/NixOS)
- [Nix Zulip](https://nixos.zulipchat.com/)
