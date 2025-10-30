# Documentation Index

**Last Updated**: 2025-10-30

## Overview

This directory contains research, guides, and diagrams for the dotfiles project, with a focus on multi-platform CI/CD strategies using Nix.

---

## Quick Navigation

### Start Here

**New to the project?** Start with the summary:
- [linux-builder CI Summary](./linux-builder-ci-summary.md) - Quick answers to common questions

**Ready to implement?** Follow the guide:
- [Multi-Platform CI Guide](./multi-platform-ci-guide.md) - Step-by-step implementation

**Want technical details?** Read the research:
- [linux-builder Research Report](./research-linux-builder-ci.md) - Deep dive into technical details

**Visual learner?** Check the diagrams:
- [Multi-Platform Strategy Diagrams](./diagrams/multi-platform-strategy.md) - Visual architecture

---

## Document Purposes

### 1. linux-builder-ci-summary.md

**Purpose**: Quick reference with direct answers

**Read this if you want to know**:
- ✅ Can linux-builder work in GitHub Actions? (NO)
- ✅ Why not? (Nested virtualization blocked)
- ✅ What should I do instead? (Hybrid strategy)
- ✅ How much does it cost? (Free within limits)
- ✅ What are the alternatives? (Matrix, nixbuild.net, etc.)

**Reading time**: 15-20 minutes

**Best for**: Quick decision making, answering specific questions

---

### 2. multi-platform-ci-guide.md

**Purpose**: Practical implementation guide

**Read this if you want to**:
- 🔧 Set up linux-builder locally
- 🔧 Add Linux builds to CI
- 🔧 Configure nixbuild.net (optional)
- 🔧 Update Makefile with new commands
- 🔧 Test and validate the setup

**Reading time**: 30-45 minutes

**Best for**: Hands-on implementation, following step-by-step instructions

---

### 3. research-linux-builder-ci.md

**Purpose**: Comprehensive research and analysis

**Read this if you want to**:
- 📚 Understand nested virtualization limitations
- 📚 Learn about M1/M2/M3 differences
- 📚 Compare all alternative strategies
- 📚 See cost/performance analysis
- 📚 Understand Nix reproducibility guarantees

**Reading time**: 45-60 minutes

**Best for**: Deep understanding, technical justification, future planning

---

### 4. diagrams/multi-platform-strategy.md

**Purpose**: Visual architecture and workflows

**Read this if you want to**:
- 🎨 See architecture diagrams
- 🎨 Understand workflow comparisons
- 🎨 Visualize build processes
- 🎨 Compare different strategies
- 🎨 Follow decision trees

**Reading time**: 20-30 minutes

**Best for**: Visual learners, presentations, quick reference

---

## Common Questions & Where to Find Answers

### Can linux-builder run in GitHub Actions?
**Answer**: No
**Details**: [Summary](./linux-builder-ci-summary.md#1-can-linux-builder-run-in-github-actions-macos-runners) | [Research](./research-linux-builder-ci.md#1-can-linux-builder-run-in-github-actions)

### Why doesn't nested virtualization work?
**Answer**: GitHub runners are VMs themselves
**Details**: [Summary](./linux-builder-ci-summary.md#technical-reason) | [Diagram](./diagrams/multi-platform-strategy.md#current-problem-linux-builder-in-ci)

### What's the recommended strategy?
**Answer**: Hybrid approach (local linux-builder + CI matrix)
**Details**: [Guide](./multi-platform-ci-guide.md#part-2-enhanced-ci-configuration) | [Diagram](./diagrams/multi-platform-strategy.md#recommended-solution-hybrid-strategy)

### How do I set up linux-builder locally?
**Answer**: Add configuration to darwin.nix
**Details**: [Guide Section 1](./multi-platform-ci-guide.md#part-1-local-setup-enable-linux-builder)

### How do I add Linux to CI?
**Answer**: Add matrix strategy to workflow
**Details**: [Guide Section 2](./multi-platform-ci-guide.md#part-2-enhanced-ci-configuration)

### What if builds are too slow?
**Answer**: Consider nixbuild.net
**Details**: [Summary](./linux-builder-ci-summary.md#nixbuildnet) | [Research](./research-linux-builder-ci.md#strategy-2-remote-builders-nixbuildnet-cachix)

### How much does it cost?
**Answer**: Free within GitHub limits (14 PRs/month)
**Details**: [Research Cost Analysis](./research-linux-builder-ci.md#monthly-cost-analysis) | [Diagram](./diagrams/multi-platform-strategy.md#cost-analysis)

### Will M3 runners support linux-builder?
**Answer**: No, GitHub hasn't enabled nested virtualization
**Details**: [Summary](./linux-builder-ci-summary.md#2-what-are-the-limitations-with-m1m2-vs-m3-in-github-actions)

### How do I achieve identical builds locally and in CI?
**Answer**: Nix guarantees reproducibility despite different environments
**Details**: [Summary](./linux-builder-ci-summary.md#4-whats-the-best-strategy-for-consistent-testing-local-macos--ci) | [Diagram](./diagrams/multi-platform-strategy.md#reproducibility-guarantee)

### What are the alternatives to linux-builder?
**Answer**: Matrix builds, nixbuild.net, QEMU, self-hosted
**Details**: [Research](./research-linux-builder-ci.md#5-alternatives-to-linux-builder-for-ci) | [Summary Comparison](./linux-builder-ci-summary.md#comparison-table)

---

## Reading Paths

### Path 1: Quick Decision (20 minutes)

1. [Summary - Executive Summary](./linux-builder-ci-summary.md#tldr)
2. [Summary - Your Questions Answered](./linux-builder-ci-summary.md#your-questions-answered)
3. [Diagrams - Summary Diagram](./diagrams/multi-platform-strategy.md#summary-diagram)
4. **Decision**: Choose strategy based on needs

---

### Path 2: Implementation (1-2 hours)

1. [Summary - Recommended Strategy](./linux-builder-ci-summary.md#4-whats-the-best-strategy-for-consistent-testing-local-macos--ci)
2. [Guide - Local Setup](./multi-platform-ci-guide.md#part-1-local-setup-enable-linux-builder)
3. [Guide - CI Configuration](./multi-platform-ci-guide.md#part-2-enhanced-ci-configuration)
4. [Guide - Testing](./multi-platform-ci-guide.md#part-5-validation--testing)
5. [Diagrams - Workflows](./diagrams/multi-platform-strategy.md#workflow-comparison)
6. **Action**: Implement step-by-step

---

### Path 3: Deep Understanding (2-3 hours)

1. [Research - Full Report](./research-linux-builder-ci.md)
2. [Summary - All Questions](./linux-builder-ci-summary.md)
3. [Guide - Complete Guide](./multi-platform-ci-guide.md)
4. [Diagrams - All Diagrams](./diagrams/multi-platform-strategy.md)
5. **Outcome**: Comprehensive understanding

---

### Path 4: Visual Overview (30 minutes)

1. [Diagrams - Architecture Overview](./diagrams/multi-platform-strategy.md#architecture-overview)
2. [Diagrams - Workflow Comparison](./diagrams/multi-platform-strategy.md#workflow-comparison)
3. [Diagrams - Decision Tree](./diagrams/multi-platform-strategy.md#decision-tree)
4. [Diagrams - Cost Analysis](./diagrams/multi-platform-strategy.md#cost-analysis)
5. **Result**: Visual understanding

---

## Key Takeaways

### The Problem

**linux-builder cannot run in GitHub Actions** due to nested virtualization limitations on all macOS runners (including M1/M2/M3).

### The Solution

**Hybrid Strategy**:
- Local: Use linux-builder (VM) for Linux builds
- CI: Use matrix builds with native runners (macos-15 + ubuntu-latest)
- Result: Different environments, identical outputs (thanks to Nix reproducibility)

### The Benefits

- ✅ Free (within GitHub limits)
- ✅ Fast (native performance in CI)
- ✅ Consistent (reproducible builds)
- ✅ Simple (low maintenance)
- ✅ Scalable (can add nixbuild.net if needed)

### The Implementation

1. **Week 1**: Enable linux-builder locally
2. **Week 2**: Add Linux to CI matrix
3. **Month 2+**: Monitor and optimize if needed

### The Cost

**Free Tier Capacity**:
- GitHub Actions: ~14 PRs/month
- nixbuild.net: ~300 builds/month (if added)

**Typical Usage**: 5-10 PRs/month → Stays free

---

## Quick Commands

### Test Local Setup

```bash
# Test linux-builder
make test-linux-builder

# Build all platforms locally
make build-all-platforms

# Show builder configuration
make check-builders
```

### Monitor CI

```bash
# View recent runs
gh run list --limit 10

# Watch live build
gh run watch

# View build logs
gh run view --log
```

### Performance Checks

```bash
# Local build time
time make build-all-platforms

# CI build times
gh run list --json durationMs | jq '.[] | .durationMs / 60000'
```

---

## External Resources

### Official Documentation

- [nix-darwin linux-builder](https://github.com/nix-darwin/nix-darwin/blob/master/modules/nix/linux-builder.nix)
- [GitHub Actions runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners)
- [Nix reproducibility](https://reproducible-builds.org/)

### Services

- [nixbuild.net](https://nixbuild.net/) - Remote builder service
- [Cachix](https://www.cachix.org/) - Binary cache service
- [GitHub Actions](https://github.com/features/actions) - CI/CD platform

### Community

- [NixOS Discourse](https://discourse.nixos.org/) - Community forum
- [r/NixOS](https://reddit.com/r/NixOS) - Reddit community
- [Nix Zulip](https://nixos.zulipchat.com/) - Real-time chat

---

## Document Statistics

| Document | Lines | Size | Reading Time |
|----------|-------|------|--------------|
| Summary | 691 | 17KB | 15-20 min |
| Guide | 694 | 16KB | 30-45 min |
| Research | 663 | 21KB | 45-60 min |
| Diagrams | ~600 | 20KB | 20-30 min |
| **Total** | **~2,600** | **~74KB** | **2-3 hours** |

---

## Contributing

Found an issue or have a suggestion?

1. Check existing documentation first
2. Create an issue with:
   - Which document needs updating
   - What's incorrect or missing
   - Suggested improvement
3. Or submit a PR directly

---

## Changelog

### 2025-10-30 - Initial Release

- Created comprehensive research report
- Added step-by-step implementation guide
- Created quick reference summary
- Added visual diagrams and architecture
- Created this index

### Future Updates

- [ ] Add real-world performance metrics after implementation
- [ ] Include screenshots of CI pipelines
- [ ] Add troubleshooting section with common issues
- [ ] Create video walkthrough
- [ ] Add comparison with other dotfiles projects

---

## License

Documentation is part of the dotfiles project and follows the same license as the main repository.

---

**Last Updated**: 2025-10-30
**Maintained by**: baleen
**Status**: Active
