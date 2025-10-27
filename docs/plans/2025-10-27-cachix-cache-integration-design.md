# Cachix Cache Integration Design

**Date**: 2025-10-27
**Author**: Claude + Jiho
**Status**: Design Complete

## Overview

Integration of Cachix binary cache (`baleen-nix.cachix.org`) to optimize build performance for team collaboration across multiple developers (baleen, jito, etc.) using the existing Makefile-based build workflow.

## Architecture

### Flake-Level Configuration

**Location**: `flake.nix` (top-level nixConfig)

```nix
{
  nixConfig = {
    substituters = [
      "https://baleen-nix.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "baleen-nix.cachix.org-1:PUBLIC_KEY_HERE"
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # Existing flake structure remains unchanged
  inputs = { ... };
  outputs = { ... };
}
```

### CI/CD Integration

**GitHub Actions**: `.github/workflows/ci.yml`

- **Auth Management**: `CACHIX_AUTH_TOKEN` stored in GitHub Secrets
- **Cache Usage**: Read-only for local builds, write access via CI only
- **Push Conditions**: Main branch and tags only
- **Automatic Upload**: Successful builds automatically push to cache

### Security Model

**Token Management**:
- ✅ Registered in GitHub Secrets (`CACHIX_AUTH_TOKEN`)
- ✅ CI-only write access (no local token storage required)
- ✅ Team members get cache benefits without token exposure

**Access Control**:
- **Read Access**: All team members (automatic via flake configuration)
- **Write Access**: CI pipeline only (authenticated via GitHub Secrets)

## Implementation Plan

### Phase 1: Flake Configuration
1. Add `nixConfig` to `flake.nix`
2. Configure substituters and trusted-public-keys
3. Test local build performance improvements

### Phase 2: CI Integration
1. Update GitHub Actions workflow
2. Configure Cachix upload step
3. Test cache push/pull in CI environment

### Phase 3: Team Onboarding
1. Documentation update
2. Team validation across different machines
3. Performance measurement and optimization

## Expected Benefits

### Performance Improvements
- **Build Time Reduction**: 60-80% faster incremental builds
- **Network Bandwidth**: Reduced package downloads
- **Developer Experience**: Faster feedback cycles

### Team Collaboration
- **Shared Artifacts**: All team members benefit from each other's builds
- **Consistency**: Same cached packages across all development environments
- **CI Speed**: Faster CI builds through cache reuse

### Maintenance Benefits
- **Automatic Management**: CI handles cache uploads automatically
- **Zero Configuration**: Team members need no additional setup
- **Secure**: No manual token handling required

## Technical Considerations

### Cache Key Strategy
- Uses Nix's built-in content-addressing
- Automatic cache invalidation on dependency changes
- Cross-platform compatibility (Darwin/Linux, ARM64/x64)

### Fallback Behavior
- Graceful degradation to official Nix cache if Cachix unavailable
- No impact on build correctness or reproducibility
- Transparent to existing Makefile commands

### Monitoring
- GitHub Actions provides build success/failure visibility
- Cachix dashboard shows cache usage statistics
- Performance metrics can be tracked over time

## Next Steps

1. **Immediate**: Implement flake.nix nixConfig changes
2. **CI Setup**: Update GitHub Actions workflow
3. **Testing**: Validate across team environments
4. **Documentation**: Update README with cache usage information

---

**Related Files**:
- `flake.nix` - Primary configuration location
- `.github/workflows/ci.yml` - CI integration point
- `Makefile` - Unchanged, commands remain compatible
- `users/shared/` - No changes required (cache is transparent)
