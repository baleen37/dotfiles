# Testing Framework

> **Comprehensive testing strategy and framework for the Nix dotfiles system**

This document describes the complete testing framework, including test categories, platform-specific capabilities, and execution strategies.

## 🧪 Testing Philosophy

### Core Principles

1. **Hierarchical Testing**: Tests are organized in a clear hierarchy from unit to end-to-end
2. **Platform Awareness**: Different platforms have different testing capabilities
3. **CI/CD Alignment**: Local testing mirrors the CI pipeline exactly
4. **Quality Gates**: All tests must pass before code integration

### Test Categories

```
tests/
├── unit/           # Individual component testing
├── integration/    # Module interaction testing  
├── e2e/           # Complete workflow testing
└── performance/   # Build time and resource monitoring
```

## 🏗️ Platform Support Matrix

### Test Availability by Platform

| Test Category | aarch64-darwin | x86_64-darwin | aarch64-linux | x86_64-linux | Command |
|---------------|:--------------:|:-------------:|:-------------:|:------------:|---------|
| **Basic Tests** |
| Smoke Tests | ✅ | ✅ | ✅ | ✅ | `nix run .#test-smoke` |
| Framework Status | ✅ | ✅ | ✅ | ✅ | `make test-status` |
| Test Discovery | ✅ | ✅ | ✅ | ✅ | `nix run .#test-list` |
| **Extended Tests** |
| Unit Tests | ✅ | ✅ | ❌ | ❌ | `nix run .#test-unit` |
| Integration Tests | ✅ | ✅ | ❌ | ❌ | `nix run .#test-integration` |
| E2E Tests | ✅ | ✅ | ❌ | ❌ | `nix run .#test-e2e` |
| Performance Tests | ✅ | ✅ | ❌ | ❌ | `nix run .#test-perf` |
| **Comprehensive** |
| Full Test Suite | ✅ | ✅ | ✅ | ✅ | `nix run .#test` |

### Why Platform Differences?

- **Darwin systems** have full testing capabilities due to complete development tool availability
- **Linux systems** have basic testing to ensure core functionality works but skip resource-intensive extended tests
- This design optimizes CI performance while maintaining quality assurance

## 🔬 Test Categories Detail

### Unit Tests (`tests/unit/`)

**Purpose**: Test individual components and functions in isolation.

#### Available Unit Tests

| Test File | Description | Focus Area |
|-----------|-------------|------------|
| `basic-functionality-unit.nix` | Core system functionality | System basics |
| `claude-config-copy-unit.nix` | Claude configuration copying | File operations |
| `claude-config-force-overwrite-unit.nix` | Force overwrite scenarios | Conflict resolution |
| `claude-config-overwrite-prevention-test.nix` | Overwrite prevention logic | Data protection |
| `claude-config-preserve-user-changes-test.nix` | User change preservation | User data safety |
| `claude-file-copy-test.nix` | File copying mechanisms | File operations |
| `claude-file-overwrite-unit.nix` | File overwrite handling | File safety |
| `configuration-validation-unit.nix` | Configuration validation | Input validation |
| `error-handling-unit.nix` | Error handling mechanisms | Error management |
| `flake-structure-test.nix` | Flake structure validation | Structure integrity |
| `input-validation-unit.nix` | Input validation procedures | Data validation |
| `makefile-usability-test.nix` | Makefile functionality | Build system |
| `module-imports-unit.nix` | Module import mechanisms | Module system |
| `platform-detection-unit.nix` | Platform detection logic | Platform handling |
| `ssh-key-security-test.nix` | SSH key security | Security |
| `sudo-security-test.nix` | Sudo security measures | Security |
| `user-resolution-unit.nix` | User resolution mechanisms | User management |

#### Running Unit Tests

```bash
# Darwin systems only
nix run .#test-unit

# Via Makefile (recommended)
make test-unit

# Individual unit test
nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').basic_functionality_unit
```

### Integration Tests (`tests/integration/`)

**Purpose**: Test module interactions and system-level integrations.

#### Available Integration Tests

| Test File | Description | Focus Area |
|-----------|-------------|------------|
| `auto-update-integration.nix` | Auto-update system integration | Update mechanisms |
| `claude-config-force-overwrite-integration.nix` | Force overwrite integration | Configuration management |
| `claude-config-overwrite-integration.nix` | Overwrite prevention integration | Data protection |
| `claude-config-preservation-integration.nix` | Configuration preservation | User data safety |
| `cross-platform-integration.nix` | Cross-platform compatibility | Platform support |
| `file-generation-integration.nix` | File generation processes | File operations |
| `module-dependency-integration.nix` | Module dependency resolution | Module system |
| `network-dependencies-integration.nix` | Network dependency handling | Network operations |
| `package-availability-integration.nix` | Package availability across platforms | Package management |
| `recovery-mechanisms-integration.nix` | System recovery procedures | Error recovery |
| `system-build-integration.nix` | System build processes | Build system |

#### Running Integration Tests

```bash
# Darwin systems only  
nix run .#test-integration

# Via Makefile (recommended)
make test-integration
```

### End-to-End Tests (`tests/e2e/`)

**Purpose**: Test complete workflows and user scenarios.

#### Available E2E Tests

| Test File | Description | Scenario |
|-----------|-------------|----------|
| `build-switch-auto-update-e2e.nix` | Auto-update with build-switch | Automated updates |
| `claude-config-force-overwrite-e2e.nix` | Force overwrite complete workflow | Configuration management |
| `claude-config-overwrite-e2e.nix` | Configuration overwrite scenarios | User protection |
| `claude-config-workflow-e2e.nix` | Complete Claude configuration workflow | Configuration lifecycle |
| `complete-workflow-e2e.nix` | Full system deployment workflow | System deployment |
| `legacy-system-integration-e2e.nix` | Legacy system integration | Backward compatibility |
| `legacy-workflow-e2e.nix` | Legacy workflow compatibility | Migration support |
| `system-build-e2e.nix` | Complete system build process | Build lifecycle |
| `system-deployment-e2e.nix` | System deployment procedures | Deployment process |

#### Running E2E Tests

```bash
# Darwin systems only
nix run .#test-e2e

# Via Makefile (recommended)  
make test-e2e
```

### Performance Tests (`tests/performance/`)

**Purpose**: Monitor build times, resource usage, and system performance.

#### Available Performance Tests

| Test File | Description | Metrics |
|-----------|-------------|---------|
| `build-time-perf.nix` | Build time monitoring | Time measurements |
| `resource-usage-perf.nix` | Resource usage profiling | Memory, CPU, disk |

#### Running Performance Tests

```bash
# Darwin systems only
nix run .#test-perf

# Via Makefile (recommended)
make test-perf
```

## 🚀 Test Execution Strategies

### Local Development Testing

#### Quick Validation
```bash
# Fast syntax and structure check
make smoke

# Check test framework health
make test-status
```

#### Comprehensive Local Testing
```bash
# Mirror CI pipeline exactly
./scripts/test-all-local
```

**Output example:**
```
========================
    TEST RESULTS SUMMARY  
========================
Total Tests: 7
Passed: 7
Failed: 0
Log File: test-results-20240106-143022.log
========================
```

#### Platform-Specific Testing

**On Darwin systems (full capabilities):**
```bash
# Run all test categories
make test           # Comprehensive suite
make test-unit      # Unit tests  
make test-integration  # Integration tests
make test-e2e       # End-to-end tests
make test-perf      # Performance tests
```

**On Linux systems (basic capabilities):**
```bash
# Run available tests
make test           # Basic comprehensive suite
make smoke          # Quick validation
make test-status    # Framework health check
```

### CI/CD Pipeline Testing

The CI pipeline runs tests in this order:

1. **Lint & Validation**
   ```bash
   make lint     # Pre-commit hooks
   make smoke    # Flake validation
   ```

2. **Build Matrix** (parallel across platforms)
   ```bash
   make build-darwin   # macOS configurations
   make build-linux    # Linux configurations  
   ```

3. **Test Execution** (platform-appropriate)
   ```bash
   # Darwin systems
   make test-unit && make test-integration && make test-e2e

   # Linux systems  
   make test && make smoke
   ```

4. **Final Validation**
   ```bash
   make smoke    # Final flake check
   ```

## 🔧 Test Framework Implementation

### Test App Generation

Tests are generated using `lib/test-apps.nix`:

```nix
# Simplified structure
{
  # Basic tests (all platforms)
  test = mkTestApp "comprehensive test suite";
  test-smoke = mkTestApp "quick validation";
  test-list = mkTestApp "test discovery";

  # Extended tests (Darwin only)
  test-unit = mkExtendedTestApp "unit tests";
  test-integration = mkExtendedTestApp "integration tests";
  test-e2e = mkExtendedTestApp "end-to-end tests";
  test-perf = mkExtendedTestApp "performance tests";
}
```

### Test Discovery

```bash
# List all available tests for current platform
nix run .#test-list

# Check what test categories are available
nix flake show | grep test
```

### Test Framework Status

```bash
# Check framework health and configuration
make test-status

# Detailed framework information
nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').framework_status
```

## 📊 Quality Gates

### Pre-Commit Requirements

Before any commit, these tests must pass:
```bash
make lint     # Code quality
make smoke    # Basic validation  
make build    # System builds
make smoke    # Final check
```

### Pull Request Requirements

All PRs must pass:
- ✅ All lint checks
- ✅ All builds (4 platforms)  
- ✅ Platform-appropriate test suites
- ✅ No test regressions

### Release Requirements

Before releases:
- ✅ Full test suite on Darwin
- ✅ Basic test suite on Linux
- ✅ Performance benchmarks within acceptable ranges
- ✅ All integration tests passing

## 🛠️ Test Development

### Writing New Tests

#### Unit Test Template
```nix
# tests/unit/my-feature-unit.nix
{ pkgs }:

pkgs.runCommand "my-feature-unit-test" {} ''
  echo "Testing my feature..."

  # Test setup
  export TEST_VAR="test-value"

  # Test execution
  ${pkgs.my-package}/bin/my-command --test

  # Test validation
  if [ $? -eq 0 ]; then
    echo "✅ Test passed"
    touch $out
  else
    echo "❌ Test failed"
    exit 1
  fi
''
```

#### Integration Test Template
```nix
# tests/integration/my-integration-test.nix
{ pkgs, lib }:

pkgs.runCommand "my-integration-test" {
  buildInputs = with pkgs; [ git curl ];
} ''
  echo "Testing integration scenario..."

  # Multi-component test
  # ... test logic ...

  echo "✅ Integration test passed"
  touch $out
''
```

### Adding Tests to Framework

1. **Create test file** in appropriate category directory
2. **Add to test framework** in `lib/test-apps.nix`
3. **Test locally** before committing
4. **Update documentation** if needed

## 🔍 Debugging Tests

### Test Failure Investigation

```bash
# Run with verbose output
nix build --impure --show-trace .#checks.$(nix eval --impure --expr 'builtins.currentSystem').my_test

# Check build logs
nix log .#checks.$(nix eval --impure --expr 'builtins.currentSystem').my_test
```

### Common Test Issues

**Environment Variables:**
```bash
# Ensure USER is set for tests
export USER=$(whoami)
nix run --impure .#test
```

**Platform Compatibility:**
```bash
# Check if test is available on current platform
nix flake show | grep -A 20 "$(nix eval --impure --expr 'builtins.currentSystem')"
```

**Test Dependencies:**
```bash
# Clear nix store cache if tests seem stale
nix store gc
```

## 📚 References

- **Test Execution**: See [REFERENCE.md](./REFERENCE.md) for complete command reference
- **Development**: See [DEVELOPMENT-SCENARIOS.md](./DEVELOPMENT-SCENARIOS.md) for test development scenarios
- **CI/CD**: See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution testing requirements
- **Architecture**: See [ARCHITECTURE.md](./ARCHITECTURE.md) for system design details

---

> **Note**: This testing framework ensures reliability across all supported platforms while optimizing for performance and maintainability.
