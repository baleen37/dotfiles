<!--
Sync Impact Report:
Version change: Template → 1.0.0
Modified principles: Template → All 5 principles defined
Added sections: All sections filled from template
Removed sections: None (all template sections preserved)
Templates requiring updates: All referenced templates confirmed compatible (✅)
Follow-up TODOs: None
-->

# Nix Dotfiles Constitution

## Core Principles

### I. Declarative Configuration

All system configurations must be declared through Nix expressions, with externalized YAML settings for environment-specific values. No imperative state changes or manual configuration files outside the Nix ecosystem. External dependencies require explicit package definitions with version pinning and integrity checks.

**Rationale**: Ensures reproducible environments across platforms and prevents configuration drift that leads to "works on my machine" issues.

### II. Platform Modularity

Separate platform-specific code (`modules/{darwin,nixos}/`) from shared functionality (`modules/shared/`). Each module must be self-contained with clear interfaces and dependencies. Host configurations define only machine-specific overrides, not core functionality.

**Rationale**: Enables code reuse across macOS and NixOS while maintaining platform-specific optimizations and preventing configuration conflicts.

### III. Test-First Development (NON-NEGOTIABLE)

All configuration changes require tests before implementation. TDD cycle mandatory: Write failing test → Implement minimal change → Verify test passes → Refactor if needed. Multi-tier testing required: unit (module validation), integration (cross-module compatibility), end-to-end (full system validation).

**Rationale**: Configuration errors can break entire development environments. Testing prevents catastrophic failures and ensures reliable rollbacks.

### IV. Performance Optimization

Build times must be minimized through parallel execution, intelligent caching, and platform-specific targeting. Memory usage during builds must be monitored and optimized. Cache management with automatic cleanup and size limits required. Performance regressions must be detected and addressed immediately.

**Rationale**: Developer productivity depends on fast feedback loops. Slow builds reduce development velocity and system adoption.

### V. Security and Reproducibility

Never commit secrets, API keys, or sensitive data to the repository. All dependencies must use SHA256 integrity checks and version pinning. Configuration changes must preserve security settings and maintain backwards compatibility. User-specific data must be externalized through environment variables or secure configuration files.

**Rationale**: Security breaches and unreproducible builds undermine the entire system's trustworthiness and violate enterprise requirements.

## Development Workflow

All changes follow strict TDD methodology with multi-tier testing validation. Configuration updates require comprehensive testing across supported platforms (macOS Intel/ARM, NixOS x86_64/ARM64). Performance impact must be measured and documented for any significant changes.

Build optimization prioritizes developer experience with parallel execution and intelligent caching. Platform-specific builds target current platform for faster iteration cycles. Resource monitoring tracks build time and memory usage to prevent performance regressions.

Quality gates include pre-commit hooks, automated CI/CD validation, and manual review for complex changes. Rollback capabilities must be preserved through Nix generations and configuration backups.

## Security Requirements

Secrets management through environment variables and secure external configuration files only. All package dependencies must include integrity checks and version constraints. Security-sensitive configurations require additional review and testing.

User data externalization prevents accidental commits of personal information. SSH keys, API tokens, and credentials must never be hardcoded in configurations. Security updates take priority over feature development.

## Governance

Constitution supersedes all other development practices and guidelines. Changes to core principles require documentation of rationale, impact assessment, and migration plan. All configuration changes must verify compliance with constitutional requirements.

Complexity deviations require explicit justification and simpler alternatives analysis. Use CLAUDE.md for runtime development guidance and platform-specific best practices. Regular constitution reviews ensure continued alignment with project needs.

**Version**: 1.0.0 | **Ratified**: 2025-01-22 | **Last Amended**: 2025-01-22
