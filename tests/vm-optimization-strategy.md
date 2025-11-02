# VM Test Optimization Strategy
## Goal: Reduce VM test execution time from 10 minutes to 3 minutes

## Current VM Test Analysis

### Existing VM Tests (Current State)
- **7+ VM test files** with overlapping functionality
- **Execution time**: ~10 minutes (full VM build + boot + validation)
- **Resource usage**: 4 cores, 8GB RAM, 40GB disk
- **Test coverage**: Comprehensive but with significant duplication

### Current VM Test Files Identified
1. `tests/unit/vm-execution-test.nix` - VM execution validation
2. `tests/unit/vm-environment-analysis-task1-test.nix` - Environment analysis
3. `tests/unit/vm-analysis-test.nix` - VM configuration analysis
4. `tests/e2e/core-vm-test.nix` - Core VM functionality
5. `tests/e2e/nixos-vm-test.nix` - NixOS-specific VM tests
6. `tests/e2e/streamlined-vm-test-suite.nix` - Already optimized (3-min target)
7. `tests/e2e/fast-vm-e2e-test.nix` - Fast E2E VM tests
8. `tests/e2e/vm-e2e-test.nix` - Full E2E VM validation
9. `tests/e2e/vm-analysis-test.nix` - VM analysis tests

## Optimization Strategies

### 1. Test Consolidation (Immediate Impact)

**Problem**: 7+ VM test files with overlapping validation
**Solution**: Consolidate into 3 focused core tests

**Target Structure**:
```nix
# tests/e2e/optimized-vm-suite.nix
{
  core-environment-test    # Essential tools & services
  user-workflow-test       # Complete user workflows
  system-integration-test  # Cross-platform validation
}
```

**Expected Time Savings**: 40% (4 minutes) by eliminating duplication

### 2. VM Configuration Optimization

**Current VM Config Issues**:
- Over-provisioned resources (4 cores, 8GB RAM)
- Heavy package installations
- Unnecessary services enabled

**Optimized VM Config**:
```nix
{
  # Resource optimization
  virtualisation.cores = 2;        # Reduced from 4
  virtualisation.memorySize = 2048; # Reduced from 8192

  # Minimal essential packages
  environment.systemPackages = with pkgs; [
    git vim coreutils systemd  # Only essentials
  ];

  # Disable heavy services
  services.docker.enable = false;    # Remove unless needed
  services.flatpak.enable = false;   # Remove heavy services
}
```

**Expected Time Savings**: 25% (2.5 minutes) through resource optimization

### 3. Build Caching Strategy

**Current Issues**:
- No incremental build optimization
- Full rebuild on every test run
- No shared build cache between tests

**Optimization Strategy**:
```bash
# Use nix-dirent or similar for faster evaluation
# Pre-build common derivations
# Share build artifacts between VM tests
```

**Implementation**:
```nix
{
  # Pre-built base VM image
  baseVm = pkgs.nixos {
    configuration = minimalBaseConfig;
  };

  # Tests use base + overlay
  testVm = baseVm.config.system.build.vm;
}
```

**Expected Time Savings**: 20% (2 minutes) through build caching

### 4. Parallel Test Execution

**Current**: Sequential test execution
**Proposed**: Parallel execution of independent tests

**Test Dependency Analysis**:
```nix
# Independent tests (can run in parallel)
parallelTests = [
  core-environment-test     # 30 seconds
  user-workflow-test        # 60 seconds
  system-integration-test   # 45 seconds
];

# Total parallel time: ~60 seconds (vs 135 seconds sequential)
```

**Expected Time Savings**: 50% (2.5 minutes) through parallelization

### 5. Test Scope Optimization

**Current Over-testing**:
- Testing every package installation
- Validating every service configuration
- Multiple similar configuration tests

**Focused Testing**:
```nix
# Critical path testing only
criticalTests = {
  # Core functionality (must have)
  essentialToolsAvailable = true;    # git, vim, coreutils
  userEnvironmentWorks = true;       # login, shell, paths
  basicNetworkConnectivity = true;   # ping, DNS resolution

  # Remove non-critical tests
  # allPackageVersions = false;      # Skip package version testing
  # allServiceConfigs = false;       # Skip every service detail
  # performanceBenchmarks = false;   # Skip performance tests
};
```

**Expected Time Savings**: 15% (1 minute) through scope optimization

## Implementation Plan

### Phase 1: Immediate Consolidation (Week 1)

**Actions**:
1. Create `tests/e2e/optimized-vm-suite.nix` based on existing `streamlined-vm-test-suite.nix`
2. Remove duplicate VM test files:
   - Delete: `tests/e2e/core-vm-test.nix`
   - Delete: `tests/e2e/nixos-vm-test.nix`
   - Delete: `tests/e2e/vm-e2e-test.nix`
3. Update Makefile to use optimized suite
4. Update CI configuration

**Expected Result**: 6 minutes execution time (40% improvement)

### Phase 2: Resource Optimization (Week 2)

**Actions**:
1. Create minimal VM configuration
2. Reduce resource allocation (2 cores, 2GB RAM)
3. Remove non-essential packages and services
4. Optimize VM boot configuration

**Expected Result**: 4.5 minutes execution time (25% improvement)

### Phase 3: Build Optimization (Week 3)

**Actions**:
1. Implement build caching strategy
2. Create pre-built base VM image
3. Use incremental builds
4. Optimize Nix evaluation

**Expected Result**: 3.5 minutes execution time (20% improvement)

### Phase 4: Parallel Execution (Week 4)

**Actions**:
1. Analyze test dependencies
2. Implement parallel test runner
3. Update test execution framework
4. Optimize test ordering

**Expected Result**: 3 minutes execution time (15% improvement)

## Technical Implementation Details

### Optimized VM Configuration

```nix
# tests/lib/optimized-vm-config.nix
{ pkgs, lib, ... }:
{
  # Minimal boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Resource optimization
  virtualisation.cores = 2;
  virtualisation.memorySize = 2048;
  virtualisation.diskSize = 5120;  # 5GB instead of 40GB

  # Minimal networking
  networking.hostName = "test-vm";
  networking.useDHCP = false;
  networking.firewall.enable = false;

  # Essential services only
  services.openssh.enable = true;
  programs.zsh.enable = true;

  # Minimal packages
  environment.systemPackages = with pkgs; [
    git vim coreutils systemd curl
  ];

  # Test user with minimal setup
  users.users.testuser = {
    isNormalUser = true;
    password = "test123";
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
  };

  system.stateVersion = "24.11";
}
```

### Optimized Test Suite

```nix
# tests/e2e/optimized-vm-suite.nix
{
  # Import optimized configuration
  vmConfig = import ../lib/optimized-vm-config.nix;

  # Three focused tests
  tests = {
    # Test 1: Core environment (30 seconds)
    core-test = {
      name = "Core Environment Validation";
      checks = [
        "essential tools available"
        "basic services enabled"
        "user can login"
      ];
    };

    # Test 2: User workflow (45 seconds)
    workflow-test = {
      name = "User Workflow Validation";
      checks = [
        "git clone works"
        "editor opens files"
        "shell configuration loads"
      ];
    };

    # Test 3: System integration (45 seconds)
    integration-test = {
      name = "System Integration Validation";
      checks = [
        "dotfiles apply correctly"
        "cross-platform compatibility"
        "configuration reloads"
      ];
    };
  };
}
```

### Parallel Test Runner

```bash
#!/bin/bash
# tests/scripts/run-vm-tests-parallel.sh

# Run tests in parallel where possible
run_parallel_tests() {
  echo "Running VM tests in parallel..."

  # Independent tests can run together
  (run_test core-test) &
  CORE_PID=$!

  (run_test workflow-test) &
  WORKFLOW_PID=$!

  # Wait for both to complete
  wait $CORE_PID $WORKFLOW_PID

  # Integration test depends on others
  run_test integration-test
}

# Execute with timeout (3 minutes total)
timeout 180 run_parallel_tests
```

## Success Metrics

### Performance Targets
- **Execution time**: 10 minutes → 3 minutes (70% improvement)
- **Resource usage**: 4 cores/8GB RAM → 2 cores/2GB RAM (75% reduction)
- **Disk usage**: 40GB → 5GB (87% reduction)

### Quality Targets
- **Test coverage**: Maintain 95% of current coverage
- **Reliability**: 98% test pass rate
- **CI execution**: Consistent <5 minute runs

### Monitoring Plan
```bash
# Track execution times
echo "$(date): VM test started" >> vm-test-times.log
# ... run tests ...
echo "$(date): VM test completed" >> vm-test-times.log

# Weekly performance review
grep "VM test" vm-test-times.log | tail -10
```

## Risk Mitigation

### Potential Issues
1. **Test coverage loss** from consolidation
2. **Flaky tests** from resource reduction
3. **CI integration issues** from new structure

### Mitigation Strategies
1. **Coverage validation**: Compare test results before/after optimization
2. **Gradual resource reduction**: Test with 3GB RAM before 2GB
3. **Staging environment**: Test optimized suite in separate branch first

### Rollback Plan
- Keep original VM tests in `tests/e2e/legacy-vm-tests/` for 2 weeks
- Use feature flag to switch between old and new test suites
- Monitor test failure rates and rollback if >5% regression

## Expected Timeline

- **Week 1**: Test consolidation (6 minute target)
- **Week 2**: Resource optimization (4.5 minute target)
- **Week 3**: Build optimization (3.5 minute target)
- **Week 4**: Parallel execution (3 minute target)
- **Week 5**: Validation and monitoring

Total optimization period: **4 weeks** to achieve 70% performance improvement while maintaining test quality.
