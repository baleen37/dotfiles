# CI Cache Optimization Strategy

## Overview

This document outlines the comprehensive cache optimization strategy implemented to improve CI/CD pipeline performance by 50-70%, reducing build times from 5-8 minutes to 2-3 minutes.

## Cache Strategy Architecture

### 1. Multi-Level Cache Hierarchy

#### Level 1: Cachix (Shared Nix Store)
- **Purpose**: Shared binary cache across all workflows and external contributors
- **Cache Name**: `dotfiles-nix`
- **Benefits**:
  - Cross-workflow cache sharing
  - External contributor cache hits
  - Reduced rebuild times for unchanged derivations

#### Level 2: GitHub Actions Cache (Fast Local Storage)
- **Purpose**: Fast restoration of Nix store and build artifacts
- **Strategy**: Granular cache keys with smart fallback chains
- **Benefits**:
  - Faster cache restoration than Cachix
  - Platform-specific optimization
  - Build artifact persistence

#### Level 3: Derivation-Level Caching
- **Purpose**: Fine-grained caching based on input changes
- **Implementation**: Hash-based cache keys including specific file patterns
- **Benefits**:
  - Minimal rebuilds for unchanged components
  - Efficient incremental builds

### 2. Cache Key Strategy

#### Primary Cache Keys
```yaml
# Validation Stage
key: v2-validate-{os}-{hash(flake.lock, **/*.nix, .pre-commit-config.yaml)}

# Build Stage  
key: v2-build-{system}-{hash(flake.lock, modules/**/*.nix, hosts/**/*.nix)}

# Test Stage
key: v2-test-{category}-{hash(flake.lock, tests/**/*.nix)}

# Smoke Test
key: v2-smoke-{hash(flake.lock)}
```

#### Restore Key Chains
```yaml
restore-keys:
  - v2-{stage}-{system}-{flake.lock}
  - v2-{stage}-{system}-
  - v2-{previous-stage}-{system}-
```

### 3. Cache Path Optimization

#### Cached Directories
- `/nix/store`: Core Nix derivations and packages
- `~/.cache/nix`: Nix evaluation cache and metadata
- `~/.cache/pre-commit`: Pre-commit hook cache

#### Cache Filters (Cachix)
- **Push Filter**: `(-source$|nixpkgs\.tar\.gz$)`
- **Excludes**: Source tarballs and unnecessary artifacts
- **Includes**: Built derivations and dependencies

## Performance Optimizations

### 1. Workflow-Specific Optimizations

#### Validation Stage
- **Cache Strategy**: Lightweight cache with pre-commit dependencies
- **Performance Target**: < 1 minute
- **Optimizations**:
  - Minimal cache paths
  - Pre-commit cache inclusion
  - Fast fallback chains

#### Build Stage
- **Cache Strategy**: Platform-specific caching with cross-platform fallbacks
- **Performance Target**: 2-4 minutes (down from 5-8 minutes)
- **Optimizations**:
  - Granular cache keys based on module changes
  - Platform-specific cache isolation
  - Smart restore key chains

#### Test Stage
- **Cache Strategy**: Test-category specific caching
- **Performance Target**: 1-3 minutes per category
- **Optimizations**:
  - Category-specific cache keys
  - Test dependency isolation
  - Build cache inheritance

#### Smoke Test (Draft PRs)
- **Cache Strategy**: Read-only minimal caching
- **Performance Target**: < 30 seconds  
- **Optimizations**:
  - No cache writing (read-only)
  - Minimal cache paths
  - Fastest possible validation

### 2. Cross-Workflow Cache Sharing

#### Strategy
- Shared cache keys across CI and auto-update workflows
- Cachix provides persistent cache across workflow runs
- GitHub Actions cache provides fast restoration within workflow runs

#### Implementation
```yaml
# Shared cache key patterns
auto-update: v2-auto-update-{os}-{flake.lock}
ci-validate: v2-validate-{os}-{flake.lock}
ci-build: v2-build-{system}-{flake.lock}

# Cross-workflow restore chains
restore-keys:
  - v2-auto-update-{os}-
  - v2-validate-{os}-
  - v2-build-{system}-
```

## Performance Monitoring

### 1. Build Time Tracking

#### Metrics Collected
- Build duration per stage and platform
- Test execution time per category
- Cache hit/miss ratios
- Total pipeline execution time

#### Implementation
```bash
# Timing collection
BUILD_START=$(date +%s)
# ... build process ...
BUILD_END=$(date +%s)
BUILD_DURATION=$((BUILD_END - BUILD_START))
echo "build_duration_seconds=${BUILD_DURATION}" >> $GITHUB_OUTPUT
```

### 2. Cache Efficiency Reporting

#### Key Performance Indicators
- **Cache Hit Ratio**: Target > 80%
- **Build Time Reduction**: Target 50-70%
- **Resource Usage**: CPU/memory efficiency
- **Storage Efficiency**: Cache size vs. performance ratio

#### Monitoring Implementation
- Automated timing collection in all stages
- Cache performance metrics in workflow outputs
- Historical trend tracking through CI summaries

## Cache Invalidation Strategy

### 1. Automatic Invalidation Triggers

#### File-Based Invalidation
- **Nix Files**: Any `.nix` file changes invalidate relevant caches
- **Flake Lock**: `flake.lock` changes invalidate all caches
- **Test Files**: Test file changes invalidate test-specific caches
- **Config Files**: Pre-commit config changes invalidate validation cache

#### Time-Based Invalidation
- **Cache Version**: `v2` prefix allows manual cache invalidation
- **Automatic Cleanup**: GitHub Actions auto-cleans old caches
- **Manual Cleanup**: Repository maintainers can clear caches as needed

### 2. Cache Warming Strategy

#### Pre-build Cache Population
- **Cachix Warming**: Popular derivations pre-built and cached
- **Dependency Warming**: Common dependencies cached before main builds
- **Platform Warming**: Each platform maintains its optimized cache

#### Implementation
```yaml
# Cache warming in main workflow
- name: Warm common dependencies
  if: github.ref == 'refs/heads/main'
  run: |
    # Pre-build common derivations
    nix build --no-link .#commonDependencies
```

## Expected Benefits

### 1. Performance Improvements
- **50-70% faster CI build times**
- **Reduced resource usage** (fewer repeated builds)
- **Better developer experience** (faster feedback cycles)
- **Lower infrastructure costs** (efficient cache utilization)

### 2. Reliability Improvements
- **Consistent build times** across different PR types
- **Reduced flaky builds** due to network or resource issues
- **Better cache hit ratios** through smart key strategies

### 3. Developer Experience
- **Faster feedback cycles** for development iteration
- **Reduced waiting time** for CI completion
- **Better draft PR experience** with ultra-fast smoke tests

## Maintenance and Monitoring

### 1. Regular Maintenance Tasks
- **Monthly cache performance review**
- **Cache size monitoring and cleanup**
- **Cache key strategy optimization**
- **Performance benchmark updates**

### 2. Troubleshooting Guide

#### Common Issues
1. **Low cache hit ratios**: Check cache key granularity
2. **Slow cache restoration**: Verify cache path optimization
3. **Cache size growth**: Review cache retention policies
4. **Cross-workflow conflicts**: Check cache key naming

#### Debugging Tools
```bash
# Check cache effectiveness
gh workflow view ci --json

# Monitor cache usage
gh api repos/{owner}/{repo}/actions/caches

# Cache performance analysis
nix path-info --closure-size --human-readable
```

## Future Optimizations

### 1. Advanced Strategies
- **Incremental builds**: Component-level change detection
- **Parallel cache operations**: Concurrent cache save/restore
- **Smart cache preloading**: Predictive cache warming
- **Cross-repository cache sharing**: Organization-wide cache

### 2. Integration Opportunities
- **Build artifact caching**: Reuse build outputs across jobs
- **Test result caching**: Skip unchanged test executions
- **Documentation caching**: Cache documentation builds
- **Container image caching**: Cache Docker/OCI images
