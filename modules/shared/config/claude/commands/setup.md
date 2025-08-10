---
name: setup
description: "Development environment setup with flake.nix, pre-commit hooks, and project configurations"
mcp-servers: [context7, sequential]
agents: [nix-system-expert]
tools: [Read, Write, Edit, MultiEdit, Bash, Glob, Grep, TodoWrite, Task]
---

# /setup - Development Environment Setup Automation

## Overview

Comprehensive development environment setup tool that creates or enhances existing projects with modern Nix-based development workflows.
Supports flake.nix generation, pre-commit hooks, gitignore patterns, and development shell configurations.

## Usage

```bash
/setup
```

Interactive setup wizard that guides through development environment configuration options.

## Setup Options

### Core Development Environment

**Always Applied**:
- **flake.nix creation**: Generate or enhance existing flake with devShells
- **Development dependencies**: Common tools (git, direnv, etc.)
- **Shell environment**: Optimized development shell configuration

**Interactive Selections**:
- **Language-specific toolchains**: Node.js, Python, Rust, Go, etc.
- **Development tools**: LSP servers, formatters, linters
- **Build systems**: Make, just, npm scripts, etc.

### Pre-commit Integration

**User Choice - "Enable pre-commit hooks?"**:
- **Yes**: Install and configure pre-commit-hooks.nix
  - Code formatting (prettier, black, rustfmt, gofmt)
  - Linting (eslint, flake8, clippy, golangci-lint)
  - Security checks (detect-secrets, safety)
  - Commit message validation
- **No**: Skip pre-commit setup

### Gitignore Management

**User Choice - "Add development gitignore patterns?"**:
- **Yes**: Add comprehensive development patterns
  ```gitignore
  # Nix development
  .direnv/
  shell.nix
  result
  result-*

  # Language-specific (based on selections)
  node_modules/
  .venv/
  __pycache__/
  target/
  .env
  .env.local

  # Editor/IDE
  .vscode/
  .idea/
  *.swp
  .DS_Store
  ```
- **No**: Skip gitignore modifications

### Development Shell Features

**User Choice - "Enable advanced shell features?"**:
- **Yes**: Enhanced development experience
  - Auto-activate direnv on cd
  - Custom shell prompt with project info
  - Useful aliases and functions
  - Environment variable templates
- **No**: Basic shell only

## Generated Files

### Core Files (Always Created)

**flake.nix**:
```nix
{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Conditional: pre-commit-hooks if selected
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = with nixpkgs.legacyPackages.${system}; [
          # Selected development tools
        ];

        shellHook = ''
          echo "Development environment ready!"
          # Additional setup commands
        '';
      };
    });
}
```

**.envrc** (if direnv enabled):
```bash
use flake
```

### Conditional Files

**.pre-commit-config.yaml** (if pre-commit selected):
```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      # Language-specific hooks based on selection
```

**Justfile/Makefile** (if build system selected):
Common development commands and workflows.

## Interactive Workflow

### 1. Environment Detection
```
🔍 Analyzing current directory...
   ✓ Git repository detected
   ✓ Existing package.json found
   ✓ TypeScript project detected
```

### 2. Configuration Questions
```
📋 Development Environment Setup

1. Language/Framework Support:
   [x] Node.js (detected)
   [ ] Python
   [ ] Rust
   [ ] Go

2. Enable pre-commit hooks? (y/N): y

3. Add gitignore patterns? (Y/n): y

4. Advanced shell features? (y/N): n

5. Build system preference:
   [1] npm scripts (detected)
   [2] Make
   [3] just
   [4] None
```

### 3. Generation & Setup
```
🚀 Setting up development environment...
   ✓ Generated flake.nix with Node.js support
   ✓ Configured pre-commit hooks
   ✓ Updated .gitignore
   ✓ Created .envrc

✨ Setup complete! Run: nix develop
```

## Integration Features

### Existing Project Enhancement

- **Smart Detection**: Automatically detect existing configurations
- **Non-Destructive**: Enhance rather than replace existing files
- **Backup Creation**: Automatic backup of modified files

### Language-Specific Optimizations

**Node.js Projects**:
- Package manager detection (npm/yarn/pnpm)
- TypeScript support with proper LSP
- Common development scripts integration

**Python Projects**:
- Virtual environment isolation
- Poetry/pip-tools support
- Python version management

**Rust Projects**:
- Cargo integration
- Rust analyzer configuration
- Cross-compilation support

**Go Projects**:
- Module-aware tooling
- Go version management
- Build optimization

## Safety & Validation

### Pre-Setup Checks

- **Git Status**: Ensure clean working directory
- **Existing Files**: Backup before modification
- **Nix Installation**: Verify Nix with flakes support

### Post-Setup Validation

- **Flake Check**: `nix flake check` validation
- **Shell Test**: Verify development shell activation
- **Hook Testing**: Pre-commit hook functionality test

### Error Recovery

- **Backup Restoration**: Automatic rollback on failure
- **Partial Success**: Handle incomplete setups gracefully
- **Manual Cleanup**: Clear instructions for manual fixes

## Tool Integration

**Nix Ecosystem**:
- `nixpkgs`: Package management
- `flake-utils`: Cross-platform compatibility  
- `pre-commit-hooks.nix`: Git hook integration
- `devenv`: Alternative development environment (optional)

**External Tools**:
- `direnv`: Automatic environment activation
- `git`: Version control integration
- `pre-commit`: Hook management

## Examples

### Basic Node.js Setup
```bash
/setup
# Selects: Node.js, pre-commit=yes, gitignore=yes
# Result: Ready-to-use Node.js development environment
```

### Minimal Rust Project
```bash
/setup
# Selects: Rust, pre-commit=no, gitignore=yes, basic shell
# Result: Lightweight Rust development setup
```

### Full-Stack Project
```bash
/setup
# Selects: Node.js+Python, pre-commit=yes, gitignore=yes, advanced shell
# Result: Multi-language development environment
```

## Troubleshooting

### Common Issues

**Nix Flakes Not Enabled**:
```bash
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

**Direnv Not Working**:
```bash
# Add to shell profile
eval "$(direnv hook bash)"  # or zsh
```

**Pre-commit Hooks Failing**:
```bash
pre-commit install --install-hooks
pre-commit run --all-files
```

---
*Universal • Interactive • Reliable*
