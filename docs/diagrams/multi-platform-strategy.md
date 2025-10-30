# Multi-Platform CI Strategy: Visual Diagrams

## Architecture Overview

### Current Problem: linux-builder in CI

```
┌─────────────────────────────────────────────────────────────┐
│ GitHub Actions macOS Runner (macos-15)                      │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │ Virtual Machine (GitHub's Hypervisor)          │         │
│  │                                                 │         │
│  │  ┌──────────────────────────────────────┐     │         │
│  │  │ linux-builder VM                     │     │         │
│  │  │                                       │     │         │
│  │  │  ❌ BLOCKED                           │     │         │
│  │  │  (Nested virtualization not supported)│    │         │
│  │  └──────────────────────────────────────┘     │         │
│  │                                                 │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Recommended Solution: Hybrid Strategy

### Local Development (WITH linux-builder)

```
┌─────────────────────────────────────────────────────────────┐
│ Your Mac (Apple Silicon)                                     │
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │ macOS (Host OS)                                 │         │
│  │                                                 │         │
│  │  ┌──────────────────┐    ┌──────────────────┐ │         │
│  │  │ Darwin Build     │    │ linux-builder VM │ │         │
│  │  │                  │    │                   │ │         │
│  │  │ ✅ Native        │    │ ✅ Builds Linux   │ │         │
│  │  │    Performance   │    │    Packages       │ │         │
│  │  │                  │    │                   │ │         │
│  │  └──────────────────┘    └──────────────────┘ │         │
│  │                                                 │         │
│  │  Output: /nix/store/abc123-darwin-system       │         │
│  │  Output: /nix/store/xyz789-nixos-system        │         │
│  │                                                 │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### CI Pipeline (WITHOUT linux-builder)

```
┌──────────────────────────────────────────────────────────────────────┐
│ GitHub Actions - Matrix Strategy                                     │
│                                                                       │
│  ┌──────────────────────────────┐  ┌───────────────────────────┐   │
│  │ Job 1: Darwin                 │  │ Job 2: Linux              │   │
│  │ Runner: macos-15              │  │ Runner: ubuntu-latest     │   │
│  │                               │  │                            │   │
│  │ ┌──────────────────────────┐ │  │ ┌──────────────────────┐  │   │
│  │ │ Build Darwin             │ │  │ │ Build NixOS          │  │   │
│  │ │                          │ │  │ │                      │  │   │
│  │ │ ✅ Native macOS          │ │  │ │ ✅ Native Linux      │  │   │
│  │ │    (No VM needed)        │ │  │ │    (No VM needed)    │  │   │
│  │ │                          │ │  │ │                      │  │   │
│  │ └──────────────────────────┘ │  │ └──────────────────────┘  │   │
│  │                               │  │                            │   │
│  │ Output: /nix/store/abc123... │  │ Output: /nix/store/xyz789 │   │
│  │         ↑                     │  │         ↑                  │   │
│  │         └─────────────────────┼──┼─────────┘                  │   │
│  │              SAME HASH!       │  │   (Nix reproducibility)    │   │
│  └──────────────────────────────┘  └───────────────────────────┘   │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

**Key Insight**: Different build environments, **identical outputs** ✅

---

## Workflow Comparison

### Local Workflow

```
┌─────────────────────────────────────────────────────┐
│                                                      │
│  Developer writes code                               │
│           ↓                                          │
│  make format                     (auto-format)       │
│           ↓                                          │
│  make build-current              (Darwin only)       │
│           ↓                                          │
│  make test-core                  (quick tests)       │
│           ↓                                          │
│  make build-all-platforms        (Darwin + Linux)    │
│           ↓                                          │
│  ┌────────────────┐    ┌────────────────────┐      │
│  │ Darwin Build   │    │ Linux Build        │      │
│  │ Native         │    │ linux-builder (VM) │      │
│  │ 5-10 min       │    │ 10-15 min          │      │
│  └────────────────┘    └────────────────────┘      │
│           ↓                                          │
│  make test-vm                    (VM tests)          │
│           ↓                                          │
│  git commit && git push                              │
│           ↓                                          │
│  Create PR → CI validates                            │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### CI Workflow

```
┌──────────────────────────────────────────────────────┐
│                                                       │
│  PR created/updated                                   │
│           ↓                                           │
│  ┌─────────────────────────────────────────┐        │
│  │ Stage 1: Validate (Ubuntu)              │        │
│  │ - Lint                                   │        │
│  │ - Quick tests                            │        │
│  │ Time: 1-2 min                           │        │
│  └─────────────────────────────────────────┘        │
│           ↓                                           │
│  ┌─────────────────────────────────────────┐        │
│  │ Stage 2: Build (Matrix)                 │        │
│  │                                          │        │
│  │  ┌──────────┐        ┌──────────┐      │        │
│  │  │ Darwin   │        │ Linux    │      │        │
│  │  │ macos-15 │        │ ubuntu   │      │        │
│  │  │ 5-10 min │        │ 5-10 min │      │        │
│  │  └──────────┘        └──────────┘      │        │
│  │                                          │        │
│  └─────────────────────────────────────────┘        │
│           ↓                                           │
│  ┌─────────────────────────────────────────┐        │
│  │ Stage 3: Test (Ubuntu)                  │        │
│  │ - Integration tests                     │        │
│  │ Time: 10-15 min                         │        │
│  └─────────────────────────────────────────┘        │
│           ↓                                           │
│  ┌─────────────────────────────────────────┐        │
│  │ Stage 4: VM Test (Ubuntu)               │        │
│  │ - NixOS VM tests with KVM               │        │
│  │ Time: 10-15 min                         │        │
│  └─────────────────────────────────────────┘        │
│           ↓                                           │
│  ┌─────────────────────────────────────────┐        │
│  │ Stage 5: Cachix Upload (if main)        │        │
│  │ - Upload artifacts to binary cache      │        │
│  │ Time: 2-5 min                           │        │
│  └─────────────────────────────────────────┘        │
│           ↓                                           │
│  CI Complete ✅                                       │
│  Total Time: 25-35 minutes                           │
│                                                       │
└──────────────────────────────────────────────────────┘
```

---

## Alternative Strategy: Remote Builders (Optional)

### With nixbuild.net

```
┌────────────────────────────────────────────────────────────┐
│ Local Development                                           │
│                                                             │
│  ┌──────────────────────────────────────────┐             │
│  │ Your Mac                                  │             │
│  │                                           │             │
│  │  nix build .#allPlatforms                │             │
│  │           ↓                               │             │
│  │  Delegates to remote builder ───────────────┐          │
│  └──────────────────────────────────────────┘  │          │
│                                                 │          │
└─────────────────────────────────────────────────┼──────────┘
                                                  │
                                                  ↓
┌────────────────────────────────────────────────────────────┐
│ nixbuild.net (Remote Builders)                             │
│                                                             │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐│
│  │ Darwin Builder │  │ x86_64 Linux   │  │ ARM64 Linux  ││
│  │ 16 vCPU       │  │ 16 vCPU        │  │ 16 vCPU      ││
│  └────────────────┘  └────────────────┘  └──────────────┘│
│                                                             │
│  ⚡ 2x faster than GitHub Actions                          │
│  💰 Free tier: 25 CPU hours/month                          │
│                                                             │
└────────────────────────────────────────────────────────────┘
                                                  │
                                                  ↓
┌────────────────────────────────────────────────────────────┐
│ GitHub Actions CI                                          │
│                                                             │
│  ┌──────────────────────────────────────────┐             │
│  │ Single Runner: ubuntu-latest              │             │
│  │                                           │             │
│  │  nix build .#allPlatforms                │             │
│  │           ↓                               │             │
│  │  Uses SAME remote builders ──────────────────┐         │
│  └──────────────────────────────────────────┘   │         │
│                                                  │         │
│  ✅ Identical infrastructure                     │         │
│  ✅ Local and CI use same builders               │         │
│                                                  │         │
└──────────────────────────────────────────────────┼─────────┘
                                                   │
                                                   │
                            (Same remote builders)─┘
```

**Benefits**:
- ✅ Truly identical builds (local = CI)
- ✅ Faster (16 vCPU per build)
- ✅ Single runner type (Linux only)

**When to use**: If builds consistently >10 minutes

---

## Decision Tree

```
┌─────────────────────────────────────────────────────────────┐
│ Starting New Project or Enhancing CI?                        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ↓
         ┌──────────────────────────┐
         │ Are builds fast (<5 min)?│
         └──────┬──────────────┬────┘
                │              │
           YES  │              │ NO
                ↓              ↓
    ┌────────────────┐    ┌──────────────────┐
    │ Use Matrix     │    │ Are builds >10m? │
    │ Builds (Free)  │    └────┬──────────┬──┘
    └────────────────┘         │          │
                          YES  │          │ NO
                               ↓          ↓
                    ┌──────────────┐  ┌────────────┐
                    │ Try Caching  │  │ Use Matrix │
                    │ Optimization │  │ + Monitor  │
                    └──────┬───────┘  └────────────┘
                           │
                           ↓
                  ┌─────────────────────┐
                  │ Still slow?          │
                  └──────┬────────┬──────┘
                         │        │
                    YES  │        │ NO
                         ↓        ↓
              ┌─────────────┐  ┌───────────┐
              │ Add         │  │ Keep      │
              │ nixbuild.net│  │ Matrix    │
              └─────────────┘  └───────────┘
```

---

## Build Time Comparison

### Scenario: Typical Dotfiles Build

```
┌─────────────────────────────────────────────────────────────┐
│                                                              │
│  Platform: Darwin (macOS)                                    │
│                                                              │
│  ┌────────────────┬──────────┬──────────┬─────────────┐    │
│  │ Method         │ Time     │ Cost     │ Complexity  │    │
│  ├────────────────┼──────────┼──────────┼─────────────┤    │
│  │ Native (local) │ 5-10 min │ Free     │ Low         │    │
│  │ Native (CI)    │ 5-10 min │ $0.08/m  │ Low         │    │
│  │ nixbuild.net   │ 2-5 min  │ $0.00/m* │ Low         │    │
│  └────────────────┴──────────┴──────────┴─────────────┘    │
│                                                              │
│  Platform: Linux (NixOS)                                     │
│                                                              │
│  ┌────────────────┬──────────┬──────────┬─────────────┐    │
│  │ Method         │ Time     │ Cost     │ Complexity  │    │
│  ├────────────────┼──────────┼──────────┼─────────────┤    │
│  │ linux-builder  │ 10-15min │ Free     │ Medium      │    │
│  │ Native (CI)    │ 5-10 min │ Free     │ Low         │    │
│  │ QEMU           │ 30-60min │ Free     │ Low         │    │
│  │ nixbuild.net   │ 2-5 min  │ $0.00/m* │ Low         │    │
│  └────────────────┴──────────┴──────────┴─────────────┘    │
│                                                              │
│  * Within free tier (25 CPU hrs/month)                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Cost Analysis

### GitHub Actions (Matrix Builds)

```
┌──────────────────────────────────────────────────────────┐
│ Free Plan: 2,000 minutes/month                            │
│                                                           │
│  Per PR Build:                                            │
│  ┌─────────────────────┬──────────┬─────────────┐       │
│  │ Job                 │ Duration │ Billed      │       │
│  ├─────────────────────┼──────────┼─────────────┤       │
│  │ Validate (Linux)    │ 2 min    │ 2 min       │       │
│  │ Darwin Build (macOS)│ 10 min   │ 100 min (×10)│      │
│  │ Linux Build (Linux) │ 10 min   │ 10 min      │       │
│  │ Tests (Linux)       │ 15 min   │ 15 min      │       │
│  │ VM Test (Linux)     │ 15 min   │ 15 min      │       │
│  └─────────────────────┴──────────┴─────────────┘       │
│                                                           │
│  Total per PR: ~142 billed minutes                        │
│  Capacity: ~14 PRs/month (free tier)                      │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### nixbuild.net (Remote Builders)

```
┌──────────────────────────────────────────────────────────┐
│ Free Tier: 25 CPU hours/month                            │
│                                                           │
│  Per PR Build:                                            │
│  ┌─────────────────────┬──────────┬─────────────┐       │
│  │ Job                 │ Duration │ Billed      │       │
│  ├─────────────────────┼──────────┼─────────────┤       │
│  │ Validate (GitHub)   │ 2 min    │ 2 min       │       │
│  │ All Builds (nixb.)  │ 5 min    │ 5 CPU min   │       │
│  │ Tests (GitHub)      │ 15 min   │ 15 min      │       │
│  └─────────────────────┴──────────┴─────────────┘       │
│                                                           │
│  GitHub Actions: ~22 min/PR                               │
│  nixbuild.net: ~5 CPU min/PR                              │
│                                                           │
│  Capacity:                                                │
│  - GitHub: ~90 PRs/month                                  │
│  - nixbuild.net: ~300 builds/month                        │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

### Comparison

```
┌──────────────────────────────────────────────────────────┐
│                                                           │
│  For typical dotfiles project (5-10 PRs/month):           │
│                                                           │
│  ┌────────────────┬───────────┬──────────┬────────────┐ │
│  │ Strategy       │ Cost/mo   │ Speed    │ Capacity   │ │
│  ├────────────────┼───────────┼──────────┼────────────┤ │
│  │ Matrix (Free)  │ $0        │ Medium   │ 14 PRs     │ │
│  │ nixbuild.net   │ $0*       │ Fast     │ 300 builds │ │
│  │ Both           │ $0*       │ Fastest  │ 90+ PRs    │ │
│  └────────────────┴───────────┴──────────┴────────────┘ │
│                                                           │
│  * Within free tiers                                      │
│                                                           │
│  Recommendation: Start with Matrix, add nixbuild.net      │
│                  only if needed                           │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

---

## Reproducibility Guarantee

### How Nix Ensures "똑같이" (Same Output)

```
┌────────────────────────────────────────────────────────────┐
│                                                             │
│  Input: flake.nix + flake.lock (pinned versions)           │
│         │                                                   │
│         ↓                                                   │
│                                                             │
│  Build Environment 1        Build Environment 2            │
│  ┌─────────────────┐       ┌─────────────────┐           │
│  │ Local macOS     │       │ GitHub Ubuntu    │           │
│  │ + linux-builder │       │ Native Linux     │           │
│  │                 │       │                  │           │
│  │ Apple Silicon   │       │ Intel x86_64     │           │
│  │ VM              │       │ Bare Metal       │           │
│  └────────┬────────┘       └────────┬─────────┘           │
│           │                         │                      │
│           │   Nix Build Process     │                      │
│           │   (Deterministic)       │                      │
│           │                         │                      │
│           ↓                         ↓                      │
│                                                             │
│  /nix/store/abc123-system    /nix/store/abc123-system     │
│           ↑                         ↑                      │
│           └─────────┬───────────────┘                      │
│                     │                                       │
│              SAME HASH ✅                                   │
│              SAME CONTENT ✅                                │
│              REPRODUCIBLE ✅                                │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

**Key Principles**:
1. Same inputs (flake.lock) → Same outputs
2. Build environment doesn't matter (VM vs native)
3. Store paths are content-addressed (hash of contents)
4. Nix guarantees bit-for-bit reproducibility

---

## Summary Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                                                               │
│  Question: Can linux-builder work in GitHub Actions?         │
│                                                               │
│  ┌────────────┐                                              │
│  │    NO      │  Nested virtualization blocked               │
│  └────────────┘                                              │
│                                                               │
│  Question: What's the alternative?                           │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Hybrid Strategy:                                     │    │
│  │                                                      │    │
│  │ Local:  Darwin (native) + linux-builder (VM)        │    │
│  │ CI:     Darwin (native) + Linux (native)            │    │
│  │                                                      │    │
│  │ Result: Different paths, identical outputs ✅        │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  Question: Is it free?                                       │
│                                                               │
│  ┌────────────┐                                              │
│  │    YES     │  Within GitHub free tier (14 PRs/month)      │
│  └────────────┘                                              │
│                                                               │
│  Question: Can I optimize further?                           │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Optional: Add nixbuild.net                           │    │
│  │ - 2x faster builds                                   │    │
│  │ - Still free (25 CPU hrs/month)                      │    │
│  │ - Same builders locally + CI                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Implementation Timeline

```
Week 1: Local Setup
├─ Day 1: Add linux-builder to darwin.nix
├─ Day 2: Test linux-builder locally
├─ Day 3: Build actual NixOS configs
└─ Day 4: Update documentation

Week 2: CI Enhancement
├─ Day 1: Add Linux to CI matrix
├─ Day 2: Test in draft PR
├─ Day 3: Monitor build times
└─ Day 4: Adjust timeouts/caching

Week 3-4: Monitoring
├─ Track build success rate
├─ Monitor costs (GitHub Actions minutes)
├─ Measure build times
└─ Decide: Keep or optimize

Month 2+: Optional Optimization
└─ If needed: Add nixbuild.net
   ├─ Sign up (free tier)
   ├─ Configure locally
   ├─ Add to CI
   └─ Compare performance
```

---

## Final Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ Recommended Setup: Hybrid Strategy                           │
│                                                               │
│  ┌────────────────────────┐  ┌────────────────────────────┐ │
│  │ Local Development      │  │ GitHub Actions CI          │ │
│  │                        │  │                            │ │
│  │ ┌──────────────────┐  │  │ ┌──────────────────────┐  │ │
│  │ │ Darwin           │  │  │ │ Darwin (macos-15)    │  │ │
│  │ │ ✅ Native        │  │  │ │ ✅ Native            │  │ │
│  │ └──────────────────┘  │  │ └──────────────────────┘  │ │
│  │                        │  │                            │ │
│  │ ┌──────────────────┐  │  │ ┌──────────────────────┐  │ │
│  │ │ Linux            │  │  │ │ Linux (ubuntu-latest)│  │ │
│  │ │ ✅ linux-builder │  │  │ │ ✅ Native            │  │ │
│  │ │    (VM)          │  │  │ │                      │  │ │
│  │ └──────────────────┘  │  │ └──────────────────────┘  │ │
│  │                        │  │                            │ │
│  └────────────────────────┘  └────────────────────────────┘ │
│                                                               │
│  Benefits:                                                    │
│  ✅ Can test both platforms locally                          │
│  ✅ Fast CI builds (native performance)                      │
│  ✅ Free (within limits)                                     │
│  ✅ Identical outputs (Nix reproducibility)                  │
│  ✅ Simple setup and maintenance                             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Legend

```
✅ - Supported/Recommended
❌ - Not Supported/Not Recommended
⚠️ - Use with Caution
💰 - Cost-related
⚡ - Performance-related
🔧 - Configuration-related
📊 - Metrics/Monitoring
🚀 - Optimization
```
