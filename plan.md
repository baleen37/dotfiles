# Project Plan: Dotfiles Refactoring

> **Last Updated**: 2025-07-10
> **Status**: In Progress

## 1. Executive Summary
This document outlines the strategic plan for a comprehensive refactoring of the `dotfiles` project. The primary goal is to improve maintainability, reduce complexity, and enhance performance by eliminating code duplication, modularizing large components, and increasing test coverage. The project follows a Test-Driven Development (TDD) approach to ensure stability and a phased rollout to minimize disruption. Key success metrics include reducing code duplication to under 5%, increasing test coverage to over 85%, and achieving a 30% reduction in build times.

## 2. Technology Stack

### Recommendation
**Chosen Stack:** Hybrid (Option 3) - TDD-based Safe Phased Refactoring
**Rationale:** This approach was selected to ensure maximum safety and stability throughout the refactoring process. By leveraging TDD, we can validate that existing functionality is preserved after each change. A phased, module-by-module approach allows for incremental improvements, easy rollbacks via Git tags, and continuous verification, which is critical for a foundational project like `dotfiles`.

## 3. High-Level Architecture
The proposed architecture aims to simplify the project structure by centralizing shared logic and clearly separating concerns.

**New Directory Structure:**
```
apps/
├── common/        # Common application logic
├── platforms/     # Platform-specific minimal differences
└── targets/       # Architecture-specific configurations

scripts/
├── lib/           # Consolidated common library (shared across platforms)
├── platform/      # Platform-specific overrides and implementations
├── build/         # Build-related scripts
└── utils/         # Standalone utility functions
```

This structure eliminates the duplication of entire `lib` directories for each platform, replacing it with a single `scripts/lib` and a `scripts/platform` directory for managing differences.

## 4. Project Phases & Sprints

### Phase 1: Code Consolidation & Deduplication (Completed)
- **Goal:** Eliminate the 36 duplicated files across platform-specific `lib` directories.
- **Status:** ✅ Completed.

### Phase 2: Large Module Decomposition (Completed)
- **Goal:** Break down large, complex modules like `conditional-file-copy.nix` and monolithic shell scripts into smaller, single-responsibility units.
- **Status:** ✅ Completed.
- **Key Achievements:**
    - `conditional-file-copy.nix` (475 lines) was broken into 3 specialized modules.
    - `execute_build_switch` function (112 lines) was decomposed into a 13-line orchestrator and 8 focused sub-functions, reducing complexity by 88%.

### Phase 3: Test Coverage & Quality Enhancement (Completed)
- **Goal:** Achieve over 85% test coverage by reactivating disabled tests and adding new ones.
- **Status:** ✅ Completed.
- **Key Achievements:**
    - **100% Reactivation:** All 24 disabled tests were successfully fixed, re-enabled, and integrated into the CI pipeline.
    - **Coverage Expansion:** 3 additional high-value test suites were created for critical modules.

### Phase 4: Structural Optimization (In Progress)
- **Goal:** Implement the new, logical directory structure and externalize hardcoded configurations.
- **Sprint 4.1:** Improve directory structure.
- **Sprint 4.2:** Externalize configurations from scripts.
- **Sprint 4.3:** Update architecture and development guide documentation.

### Phase 5: Performance Optimization (Not Started)
- **Goal:** Reduce build and script execution times.
- **Sprint 5.1:** Optimize build process for a 30% time reduction.
- **Sprint 5.2:** Improve runtime performance of key scripts by 25%.
- **Sprint 5.3:** Reduce memory footprint by 20%.

## 5. Key Milestones & Deliverables
- **[✅ 2025-07-07] Phase 1 Complete:** All duplicated library code consolidated.
- **[✅ 2025-07-08] Phase 2 Complete:** Major monolithic modules successfully decomposed.
- **[✅ 2025-07-08] Phase 3 Complete:** All disabled tests reactivated and test coverage expanded.
- **[Target: Week 7] Phase 4 Complete:** Project structure is fully optimized.
- **[Target: Week 8] Project Complete:** Performance optimizations are implemented and verified.

## 6. Risk Assessment & Mitigation

| Risk Description | Likelihood | Impact | Mitigation Strategy |
|---|---|---|---|
| Platform Compatibility Issues | Medium | High | Phased, platform-by-platform testing; robust rollback plan using Git tags. |
| Regression of Existing Features | Low | High | Comprehensive TDD cycle for every change; function-level mapping and verification. |
| Build System Failures | Medium | Medium | Incremental migration of build logic; maintain a stable backup branch. |
| Failure to Recover Tests | High | Medium | **(Mitigated)** Prioritized test recovery; focused TDD cycles successfully recovered all tests. |

## 7. Testing & Tooling Strategy

### Testing Strategy
- **Test-Driven Development (TDD):** Adherence to the Red-Green-Refactor cycle for all changes.
- **Layered Testing:**
    - **Unit Tests:** For individual functions and modules.
    - **Integration Tests:** To verify interactions between modules.
    - **E2E Tests:** To validate complete user workflows.
- **Platform-Specific Validation:** All tests are run independently on each supported platform (Darwin, Linux).
- **Performance Benchmarking:** Scripts to monitor build times and memory usage.

### Required Tools
- **Nix:** Primary build and test system.
- **Git:** For version control, branching, and rollback strategies.
- **Shell Scripts:** For platform-specific automation.
- **CI/CD:** For automated testing and validation on every commit.

## 8. Collaboration Guide

### Code Review Standards
- **Functionality Preservation:** Does the change break any existing features?
- **Test Coverage:** Is the new code accompanied by meaningful tests?
- **Platform Compatibility:** Does it work across all supported platforms?
- **Performance Impact:** Does the change introduce any performance regressions?

### Commit Message Convention
```
feat: A new feature
fix: A bug fix
refactor: Code refactoring without functional changes
test: Adding or modifying tests
docs: Updates to documentation
perf: A code change that improves performance
```

## 9. References
- `CLAUDE.md`: Project development and agent guidelines.
- `docs/`: Detailed technical documentation.
- `tests/`: Examples of existing test cases.
