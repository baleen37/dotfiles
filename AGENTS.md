# AGENTS.md - Quick Reference for AI Coding Agents

## Commands

**Build/Test**: `make format` (auto-format all), `make test` (core tests), `make test-quick` (2-3s validation)
**Single Test**: `nix build --impure .#packages.$(nix eval --impure --expr 'builtins.currentSystem' | tr -d '"').lib-functions` (replace `lib-functions` with test name)
**Lint**: `make lint-quick` (format + validation), `make lint` (full checks)
**Build System**: `export USER=$(whoami)` then `make build` (current platform) or `make switch` (apply changes)

## Code Style

**Nix Files**: nixfmt RFC 166 standard (auto-formatted), direct imports, explicit configurations, no hardcoded Nix store paths, file header comments (역할 설명)
**Imports**: `import ../path/file.nix { inherit pkgs; }` pattern, `imports = [ ./module.nix ]` for modules
**Comments**: Korean for file headers (역할/주요 기능), minimal inline comments (complex logic only), no temporal/refactoring history
**Naming**: Descriptive kebab-case files (performance-optimization.nix), camelCase variables, avoid wrapper/legacy/new prefixes
**Error Handling**: Use `assert` for validation, `throw` for fatal errors, provide clear error messages
**Testing**: TDD (write test first), use `pkgs.runCommand` for tests (no bats), test files in `tests/{unit,integration,e2e}/`
**Pre-commit**: Never bypass (`--no-verify`), run `make format` if hooks fail

## Critical Rules

- **USER variable**: Always `export USER=$(whoami)` before builds
- **No hardcoded paths**: Nix store paths change every rebuild
- **Format before commit**: `make format` auto-formats all files
- **TDD workflow**: Test first → minimal code → refactor
