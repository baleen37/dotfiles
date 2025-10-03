<!--
  Sync Impact Report:
  - Version change: None → 1.0.0 (Initial constitution creation)
  - Added sections: All core principles and governance
  - Modified principles: None (new constitution)
  - Templates requiring updates: ✅ all templates already align with constitution principles
  - Follow-up TODOs: None
-->

# Dotfiles Constitution

## Core Principles

### I. Nix-First Architecture
System configuration MUST be declarative and reproducible through Nix flakes. All packages, services, and system state MUST be managed through Nix expressions. Manual system modifications are FORBIDDEN except for debugging purposes. This ensures complete environment reproducibility across development machines and eliminates configuration drift.

### II. Cross-Platform Compatibility  
All configurations MUST support both macOS (Intel/ARM) and NixOS (x86_64/ARM64) platforms. Platform-specific code MUST be isolated in dedicated modules (`modules/darwin/`, `modules/nixos/`) with shared functionality in `modules/shared/`. No platform-exclusive features without documented platform parity alternatives.

### III. Test-Driven Development (NON-NEGOTIABLE)
ALL changes MUST follow TDD methodology: write failing tests → implement minimal code → refactor. Test coverage spans unit, integration, end-to-end, and performance testing. NO code changes without corresponding tests. Pre-commit hooks enforce test execution and code quality standards.

### IV. Modular Design
System MUST maintain strict separation of concerns through modular architecture. Each module MUST have single responsibility and clear interfaces. Host-specific configurations MUST remain in `hosts/` directory. Shared utilities MUST reside in `lib/` directory with reusable functions.

### V. Automation and Quality Gates
ALL development processes MUST be automated through make targets and scripts. Code quality MUST be enforced through automated formatting (`make format`), linting, and pre-commit hooks. Build processes MUST be optimized for performance with parallel execution and intelligent caching.

## Development Standards

### Configuration Management
External configuration files in `config/` directory provide environment-specific overrides via YAML. Environment variables MUST override configuration values for flexibility. Configuration validation MUST occur before system application. All sensitive data MUST use environment variables or external secret management.

### Documentation Requirements
ALL new features MUST include comprehensive documentation. Breaking changes MUST be documented with migration guides. API contracts MUST be defined in OpenAPI/GraphQL schemas. README files MUST remain current with functionality changes.

### Performance Standards
Build times MUST be optimized for developer productivity. Resource usage MUST be monitored and optimized. Parallel execution MUST be utilized where possible. Cache strategies MUST minimize redundant operations. Performance regressions are not acceptable without justification.

## Governance

Constitution supersedes all other development practices and guidelines. ALL code reviews MUST verify constitutional compliance before approval. Complexity additions MUST be justified against simplicity principles (YAGNI, DRY, KISS). 

Amendment procedure requires documentation in this constitution, approval through pull request review, and migration plan for existing code. Version increments follow semantic versioning: MAJOR for breaking governance changes, MINOR for new principles, PATCH for clarifications.

Compliance reviews occur during all pull requests and major releases. Non-compliance blocks deployment until resolved. Runtime development guidance found in `CLAUDE.md` provides implementation details while this constitution provides immutable principles.

**Version**: 1.0.0 | **Ratified**: 2025-10-02 | **Last Amended**: 2025-10-02