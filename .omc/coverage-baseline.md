# Test Coverage Baseline

**Date**: 2026-01-31
**Repository**: dotfiles (Nix flakes-based configuration)
**Purpose**: Establish current test coverage status and identify gaps

## Overview

This document provides a comprehensive baseline of the current test coverage across the dotfiles codebase. The analysis covers library modules, user configuration files, and machine configurations.

### Current Statistics

| Category | Total | Tested | Coverage |
|----------|-------|--------|----------|
| Library Modules | 6 | 5 | 83% |
| User Configuration Modules | 12 | 9 | 75% |
| Machine Configurations | 5 | 1 | 20% |
| **Overall** | **23** | **15** | **65%** |

### Test Files Distribution

| Test Type | Count |
|-----------|-------|
| Unit Tests | 22 |
| Integration Tests | 14 |
| E2E Tests | 17 |
| Container Tests | 5 |
| **Total Test Files** | **84** |

---

## Module Coverage Status

### Library Modules (lib/*.nix)

| Module | Purpose | Tested | Test File |
|--------|---------|--------|-----------|
| lib/mksystem.nix | System factory function | ✅ | tests/unit/mksystem-test.nix |
| lib/user-info.nix | User information centralization | ✅ | tests/unit/user-info-test.nix |
| lib/performance.nix | Performance measurement framework | ✅ | tests/unit/performance-test.nix |
| lib/performance-baselines.nix | Performance baseline data | ✅ | tests/unit/performance-baselines-test.nix |
| lib/trend-analysis.nix | Trend analysis system | ✅ | tests/unit/trend-analysis-test.nix |
| lib/monitoring.nix | Monitoring utilities | ❌ | **N/A** |

**Coverage**: 83% (5/6)

### User Configuration Modules (users/shared/*.nix)

| Module | Purpose | Tested | Test File |
|--------|---------|--------|-----------|
| home-manager.nix | Main entry point | ✅ | tests/integration/home-manager-test.nix |
| darwin.nix | macOS system settings | ✅ | tests/unit/darwin-test.nix |
| git.nix | Git configuration | ✅ | tests/unit/git-test.nix |
| vim.nix | Vim/Neovim setup | ✅ | tests/unit/vim-test.nix |
| zsh.nix | Zsh shell configuration | ✅ | tests/unit/zsh-test.nix |
| tmux.nix | Tmux configuration | ✅ | tests/unit/tmux-test.nix |
| starship.nix | Starship prompt | ✅ | tests/unit/starship-test.nix |
| claude-code.nix | Claude Code setup | ✅ | tests/unit/claude-code-test.nix |
| opencode.nix | OpenCode configuration | ✅ | tests/unit/opencode-test.nix |
| hammerspoon.nix | Hammerspoon automation | ✅ | tests/unit/hammerspoon-test.nix |
| karabiner.nix | Karabiner key remapping | ❌ | **N/A** |
| ghostty.nix | Ghostty terminal | ❌ | **N/A** |

**Coverage**: 75% (9/12)

### Machine Configurations (machines/*.nix)

| Module | Purpose | Tested | Test File |
|--------|---------|--------|-----------|
| macbook-pro.nix | Primary macOS machine | ✅ | Build test only |
| baleen-macbook.nix | Secondary macOS machine | ❌ | **N/A** |
| kakaostyle-jito.nix | Work machine (jito.hello) | ❌ | **N/A** |
| nixos/vm-aarch64-utm.nix | ARM64 NixOS VM | ❌ | **N/A** |
| nixos/vm-x86_64-utm.nix | x86_64 NixOS VM | ❌ | **N/A** |

**Coverage**: 20% (1/5) - Note: Machine configs primarily use build verification

---

## Untested Modules

### High Priority

1. **lib/monitoring.nix**
   - Purpose: Monitoring utilities for system health and performance
   - Impact: Affects performance tracking and alerting
   - Risk: Medium - Core functionality not validated

2. **users/shared/karabiner.nix**
   - Purpose: Karabiner-Elements key remapping configuration
   - Impact: Affects keyboard behavior and productivity workflows
   - Risk: Medium - Configuration errors can break keyboard shortcuts

### Medium Priority

3. **users/shared/ghostty.nix**
   - Purpose: Ghostty terminal emulator configuration
   - Impact: Modern terminal experience
   - Risk: Low - Newer module, less critical

### Low Priority

4. **Machine-specific configurations**
   - baleen-macbook.nix
   - kakaostyle-jito.nix
   - nixos/vm-*.nix
   - Purpose: Hardware-specific settings
   - Impact: Limited to specific machines
   - Risk: Low - Primarily verified through build tests

---

## Areas for Improvement

### 1. Missing Test Coverage

**Critical Gaps**:
- No tests for `lib/monitoring.nix` despite its role in the performance framework
- Karabiner configuration lacks validation for complex key remapping rules
- Ghostty configuration is untested despite being actively used

**Recommended Actions**:
- Create `tests/unit/monitoring-test.nix`
- Create `tests/unit/karabiner-test.nix`
- Create `tests/unit/ghostty-test.nix`

### 2. Test Quality

**Current State**:
- Unit tests exist for most modules
- Integration tests validate module interactions
- Some tests may have platform-specific limitations

**Recommended Actions**:
- Add cross-platform validation where applicable
- Increase assertion coverage in existing tests
- Add edge case testing for complex configurations

### 3. Machine Configuration Validation

**Current State**:
- Machine configs rely primarily on build tests
- No dedicated unit tests for machine-specific settings

**Recommended Actions**:
- Add machine-specific integration tests
- Validate hardware-dependent configurations
- Test user override functionality

---

## Priority-Based Improvement Plan

### Phase 1: Critical Coverage (Immediate)

1. **Add monitoring.nix tests**
   - Create unit tests for monitoring utility functions
   - Validate performance data collection
   - Test alerting thresholds

2. **Add karabiner.nix tests**
   - Validate key remapping syntax
   - Test complex modification conditions
   - Ensure layer configurations work correctly

**Estimated Effort**: 2-3 hours
**Target Coverage**: 90%+ for library modules

### Phase 2: User Module Completion (Short-term)

3. **Add ghostty.nix tests**
   - Validate terminal configuration syntax
   - Test font and theme settings
   - Ensure key bindings are properly defined

4. **Enhance existing tests**
   - Review and update assertions in existing tests
   - Add edge case coverage
   - Improve error message validation

**Estimated Effort**: 2-3 hours
**Target Coverage**: 85%+ for user modules

### Phase 3: Machine Configuration (Medium-term)

5. **Add machine-specific tests**
   - Integration tests for each machine config
   - Validate user override functionality
   - Test platform-specific settings

6. **Cross-platform validation**
   - Ensure tests work on both macOS and Linux
   - Add CI-specific test variants
   - Validate container tests across platforms

**Estimated Effort**: 3-4 hours
**Target Coverage**: 80%+ for machine configs

---

## Test Infrastructure Notes

### Test Helpers Available

From `tests/lib/test-helpers.nix`:

```nix
assertTest "name" condition "message"
assertFileExists "name" derivation "path"
assertHasAttr "name" attrName set
assertStringContains "name" haystack needle
```

### Platform Support

- **macOS**: Validation mode for container tests, full unit/integration tests
- **Linux**: Full test suite including container tests
- **CI**: Multi-platform validation (macOS-15, Ubuntu x64/ARM64)

### Test Discovery

Tests are automatically discovered:
- Unit tests: `tests/unit/*-test.nix`
- Integration tests: `tests/integration/*-test.nix`
- Container tests: Manual registration in `tests/default.nix`

---

## Success Metrics

### Target Goals

| Metric | Current | Target | Date |
|--------|---------|--------|------|
| Library Module Coverage | 83% | 95%+ | Q1 2026 |
| User Module Coverage | 75% | 90%+ | Q1 2026 |
| Overall Test Coverage | 65% | 85%+ | Q2 2026 |
| Test Execution Time | < 30s | < 60s | Maintained |

### Quality Indicators

- All new modules must include tests before merge
- Pre-commit hooks enforce test execution
- CI runs full test suite on all PRs

---

## Conclusion

The dotfiles repository maintains a strong testing foundation with 84 test files covering 65% of core modules. The primary gaps are in monitoring utilities and newer user configuration modules (Karabiner, Ghostty).

By addressing the identified priorities in three phases, we can achieve 85%+ overall coverage while maintaining fast test execution times and cross-platform compatibility.

**Next Step**: Execute Phase 1 improvements (monitoring.nix and karabiner.nix tests)
