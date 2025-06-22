# CLAUDE.md

> **Last Updated:** 2025-01-06  
> **Version:** 2.0  
> **For:** Claude Code (claude.ai/code)

This file provides comprehensive guidance for Claude Code when working with this Nix flake-based dotfiles repository.

## Quick Start

### TL;DR - Essential Commands
```bash
# Setup (run once)
export USER=<username>

# Daily workflow
make lint    # Always run before committing
make build   # Test your changes
make switch HOST=<host>  # Apply to system

# Emergency fixes
nix run --impure .#build-switch  # Build and switch (requires sudo)
```

### First Time Setup
1. Set user environment: `export USER=<username>`
2. Test the build: `make build`
3. Apply configuration: `make switch HOST=<host>`
4. Install global tools: `./scripts/install-setup-dev`

## Repository Overview

This is a Nix flake-based dotfiles repository for managing macOS and NixOS development environments declaratively. It supports x86_64 and aarch64 architectures on both platforms.

**Key Features:**
- Declarative environment management with Nix flakes
- Cross-platform support (macOS via nix-darwin, NixOS via nixos-rebuild)
- Comprehensive testing suite with CI/CD
- Modular architecture for easy customization
- Global command system (`bl`) for project management

## Essential Commands

### Development Workflow
```bash
# Required: Set USER environment variable (or use --impure flag)
export USER=<username>

# Core development commands (in order of frequency)
make lint           # Run pre-commit hooks (MUST pass before committing)
make smoke          # Quick flake validation without building
make test           # Run all unit and e2e tests
make build          # Build all configurations
make switch HOST=<host>  # Apply configuration to current system
make help           # Show all available Makefile targets

# Platform-specific builds
nix run .#build     # Build for current system
nix run .#switch    # Build and switch for current system
nix run .#build-switch  # Build and switch with sudo (immediate application)
```

### Testing Requirements (Follow CI Pipeline)
**Always run these commands in order before submitting changes:**
```bash
make lint   # pre-commit run --all-files  
make smoke  # nix flake check --all-systems --no-build
make build  # build all NixOS/darwin configurations
make smoke  # final flake check after build
```

### Running Individual Tests
```bash
# Run all tests for current system
nix run .#test                    # Run comprehensive test suite
nix flake check --impure          # Run flake checks

# Run specific test categories using Makefile (recommended)
make test-unit                    # Unit tests only (Darwin only)
make test-integration             # Integration tests only (Darwin only)
make test-e2e                     # End-to-end tests only (Darwin only)
make test-perf                    # Performance tests only (Darwin only)
make test-status                  # Check test framework status

# Direct nix commands for specific test categories
nix run .#test-unit               # Unit tests (Darwin only)
nix run .#test-integration        # Integration tests (Darwin only)
nix run .#test-e2e                # End-to-end tests (Darwin only)
nix run .#test-perf               # Performance tests (Darwin only)
nix run .#test-smoke              # Quick smoke tests (all platforms)

# Platform availability:
# - Darwin systems: Full test suite available
# - Linux systems: Basic tests (test, test-smoke, test-list) only
```

## Development Workflows

### 🔄 Daily Development Cycle
```bash
# 1. Start work
git checkout -b feature/my-change
export USER=<username>

# 2. Make changes
# ... edit files ...

# 3. Test changes
make lint && make build

# 4. Apply locally (optional)
make switch HOST=<host>

# 5. Commit and push
git add . && git commit -m "feat: description"
git push -u origin feature/my-change

# 6. Create PR with auto-merge
gh pr create --assignee @me
gh pr merge --auto --squash  # Enable auto-merge after CI passes
```

### 🚀 Quick Configuration Apply
```bash
# For immediate system changes (requires sudo)
nix run --impure .#build-switch

# For testing without system changes
make build
```

### 🔧 Adding New Software
```bash
# 1. Identify target platform
# All platforms: modules/shared/packages.nix
# macOS only: modules/darwin/packages.nix  
# NixOS only: modules/nixos/packages.nix
# Homebrew casks: modules/darwin/casks.nix

# 2. Edit appropriate file
# 3. Test the change
make build

# 4. Apply if successful
make switch HOST=<host>
```

## Architecture Overview

### Module System Hierarchy
The codebase follows a strict modular hierarchy:

1. **Platform-specific modules** (`modules/darwin/`, `modules/nixos/`)
   - Contains OS-specific configurations (e.g., Homebrew casks, systemd services)
   - Imported only by respective platform configurations

2. **Shared modules** (`modules/shared/`)
   - Cross-platform configurations (packages, dotfiles, shell setup)
   - Can be imported by both Darwin and NixOS configurations

3. **Host configurations** (`hosts/`)
   - Individual machine configurations
   - Import appropriate platform and shared modules
   - Define host-specific settings

### Key Architectural Patterns

1. **User Resolution**: The system dynamically reads the `$USER` environment variable via `lib/get-user.nix`. Always ensure this is set or use `--impure` flag.

2. **Flake Outputs Structure**:
   ```nix
   {
     # Generated for all systems using genAttrs
     darwinConfigurations = genAttrs darwinSystems (system: ...);
     nixosConfigurations = genAttrs linuxSystems (system: ...);

     # Platform-specific apps with different availability
     apps = {
       aarch64-darwin = { build, build-switch, apply, rollback, test-unit, ... };
       x86_64-darwin = { build, build-switch, apply, rollback, test-unit, ... };
       aarch64-linux = { build, build-switch, apply, install, test, ... };
       x86_64-linux = { build, build-switch, apply, install, test, ... };
     };

     checks.{system}.{test-name} = ...;
   }
   ```

3. **Module Import Pattern**:
   ```nix
   imports = [
     ../../modules/darwin/packages.nix
     ../../modules/shared/packages.nix
     ./configuration.nix
   ];
   ```

4. **Overlay System**: Custom packages and patches are defined in `overlays/` and automatically applied to nixpkgs.

### File Organization

- `flake.nix`: Entry point defining all outputs
- `hosts/{platform}/{host}/`: Host-specific configurations
- `modules/{platform}/`: Platform-specific modules
- `modules/shared/`: Cross-platform modules
- `apps/{architecture}/`: Platform-specific shell scripts (actual availability varies by platform)
- `tests/`: Hierarchical test structure (unit/, integration/, e2e/, performance/)
- `lib/`: Shared Nix functions (especially `get-user.nix`)
- `scripts/`: Management and development tools
- `docs/`: Additional documentation (overview.md, structure.md, testing-framework.md)
- `overlays/`: Custom packages and patches

## Common Tasks

### Adding a New Package
1. **For all platforms**: Edit `modules/shared/packages.nix`
2. **For macOS only**: Edit `modules/darwin/packages.nix`
3. **For NixOS only**: Edit `modules/nixos/packages.nix`
4. **For Homebrew casks**: Edit `modules/darwin/casks.nix`

**Testing checklist:**
- [ ] `make lint` passes
- [ ] `make build` succeeds
- [ ] Package installs correctly on target platform(s)
- [ ] No conflicts with existing packages

### Adding a New Module
1. Create module file in appropriate directory
2. Import it in relevant host configurations or parent modules
3. Test on all affected platforms:
   - x86_64-darwin
   - aarch64-darwin  
   - x86_64-linux
   - aarch64-linux
4. Document any new conventions

### Creating a New Nix Project

1. **Using setup-dev script:**
   ```bash
   ./scripts/setup-dev [project-directory]  # Local execution
   nix run .#setup-dev [project-directory]  # Via flake app
   ```

2. **What it creates:**
   - Basic `flake.nix` with development shell
   - `.envrc` for direnv integration
   - `.gitignore` with Nix patterns

3. **Global installation (bl command system):**
   ```bash
   ./scripts/install-setup-dev        # Install once to enable bl commands
   bl setup-dev [project-directory]   # Use globally after installation
   bl list                            # List available commands
   ```

4. **Next steps:**
   - Customize `flake.nix` to add project-specific dependencies
   - Use `nix develop` or let direnv auto-activate the environment

## Troubleshooting & Best Practices

### 🔍 Common Issues & Solutions

#### Build Failures
```bash
# Show detailed error trace
nix build --impure --show-trace .#darwinConfigurations.aarch64-darwin.system

# Check flake outputs
nix flake show --impure

# Validate flake structure
nix flake check --impure --no-build

# Clear build cache
nix store gc
```

#### Environment Variable Issues
```bash
# USER not set
export USER=$(whoami)

# For CI/scripts
nix run --impure .#build

# Persistent solution
echo "export USER=$(whoami)" >> ~/.bashrc  # or ~/.zshrc
```

#### Permission Issues with build-switch
```bash
# build-switch requires sudo from the start
sudo nix run --impure .#build-switch

# Alternative: use separate commands
nix run .#build
sudo nix run .#switch
```

### 🔒 Security Best Practices

1. **Never commit secrets**
   - Use `age` encryption for sensitive files
   - Store secrets in separate encrypted repository
   - Use environment variables for dynamic secrets

2. **Verify package sources**
   - Only use packages from nixpkgs or trusted overlays
   - Review custom overlays before applying

3. **Limit sudo usage**
   - Only use `build-switch` when necessary
   - Test builds without sudo first

### ⚡ Performance Optimization

1. **Build optimization**
   - Use `make smoke` for quick validation
   - Run `nix store gc` regularly to clean cache
   - Use `--max-jobs` flag for parallel builds

2. **Development workflow**
   - Use `direnv` for automatic environment activation
   - Keep separate dev shells for different projects
   - Cache frequently used packages

### 📋 Pre-commit Checklist

- [ ] `export USER=<username>` is set
- [ ] `make lint` passes without errors
- [ ] `make smoke` validates flake structure
- [ ] `make build` completes successfully
- [ ] Changes tested on target platform(s)
- [ ] Documentation updated if needed
- [ ] No secrets or sensitive information committed

## Pre-commit Hooks

This project uses pre-commit hooks to ensure code quality.

### Installation and Setup

```bash
# Install pre-commit (using pip or conda)
pip install pre-commit

# Or install with nix (recommended)
nix-shell -p pre-commit

# Install hooks
pre-commit install

# Run hooks on all files
pre-commit run --all-files
```

### Currently Configured Hooks

- **Nix Flake Check**: Runs `nix flake check --all-systems --no-build` when any `.nix` file changes
- Provides fast syntax checking and flake validation

### Usage

```bash
# Auto-runs before commit (after hooks installed)
git commit -m "your commit message"

# Manually check all files
pre-commit run --all-files

# Check specific files only
pre-commit run --files flake.nix

# Bypass hooks (not recommended)
git commit --no-verify -m "emergency commit"
```

### Troubleshooting

```bash
# Clean pre-commit cache
pre-commit clean

# Reinstall hooks
pre-commit uninstall
pre-commit install

# Disable specific hook (temporarily)
SKIP=nix-flake-check git commit -m "message"
```

## Advanced Topics

### Global Installation (bl command system)

Run `./scripts/install-setup-dev` to install the `bl` command system:
- Installs `bl` dispatcher to `~/.local/bin`
- Sets up command directory at `~/.bl/commands/`
- Installs `setup-dev` as `bl setup-dev`

**Available commands after installation:**
```bash
bl list              # List available commands
bl setup-dev my-app  # Initialize Nix project
bl setup-dev --help  # Get help
```

### Adding Custom Commands

To add new commands to the bl system:
1. Create executable script in `~/.bl/commands/`
2. Use `bl <command-name>` to run it
3. All arguments are passed through to your script

### Script Reusability

- Copy `scripts/setup-dev` to any location for standalone use
- No dependencies on dotfiles repository structure
- Includes help with `-h` or `--help` flag

## Claude Settings Preservation System

This dotfiles includes a **Smart Claude Settings Preservation System** that safely preserves user-personalized Claude settings even during system updates.

### How It Works

1. **Automatic Modification Detection**: Automatically detects user modifications via SHA256 hashing
2. **Priority-based Preservation**: Important files (`settings.json`, `CLAUDE.md`) are always preserved
3. **Safe Updates**: Provides safe updates by saving new versions as `.new` files
4. **User Notifications**: Automatically generates notifications when updates occur
5. **Merge Tool**: Supports settings integration with an interactive merge tool

### Key Features

- ✅ **Lossless Preservation**: User settings are never lost
- ✅ **Automatic Backup**: Creates automatic backups on every change
- ✅ **Interactive Merge**: Supports merging for JSON and text files
- ✅ **Custom File Protection**: Completely preserves user-added command files
- ✅ **Clean Cleanup**: Automatically cleans temporary files after merge

### Usage

#### Normal Situations (Automatic Handling)
Automatically works during system rebuilds:
```bash
nix run --impure .#build-switch
# or
make switch HOST=<host>
```

When user modifications are detected, the following files are created:
- `~/.claude/settings.json.new` - New dotfiles version
- `~/.claude/settings.json.update-notice` - Update notification

#### Manual Merge
After receiving an update notification, use the merge tool:

```bash
# Check files that need merging
./scripts/merge-claude-config --list

# Merge specific file
./scripts/merge-claude-config settings.json

# Interactive merge for all files
./scripts/merge-claude-config

# Check differences only
./scripts/merge-claude-config --diff CLAUDE.md
```

#### Advanced Usage

**JSON Settings Merge**: `settings.json` can be selectively merged by key
```bash
./scripts/merge-claude-config settings.json
# c) Keep current value
# n) Use new value  
# s) Skip
```

**Backup Management**:
```bash
# Backup file location
ls ~/.claude/.backups/

# Backups older than 30 days are automatically cleaned
```

### Troubleshooting

#### When Update Notifications are Generated
```bash
# 1. Check notification files
find ~/.claude -name "*.update-notice"

# 2. Review changes
./scripts/merge-claude-config --diff settings.json

# 3. Decide to merge or keep current version
./scripts/merge-claude-config settings.json

# 4. Clean up after completion
rm ~/.claude/*.new ~/.claude/*.update-notice
```

#### Restore from Backup
```bash
# Check backup files
ls ~/.claude/.backups/

# Restore to desired backup
cp ~/.claude/.backups/settings.json.backup.20240106_143022 ~/.claude/settings.json
```

### Preservation Policy

| File | Priority | Action |
|------|----------|--------|
| `settings.json` | High | Preserved when modified by user, new version saved as `.new` |
| `CLAUDE.md` | High | Preserved when modified by user, new version saved as `.new` |
| `commands/*.md` (dotfiles) | Medium | Overwrite after backup |
| `commands/*.md` (user) | High | Always preserved (files not in dotfiles) |

## Prompt Engineering Guide

### Overview
This guide provides best practices for creating effective command prompts in `modules/shared/config/claude/commands/`. Well-crafted prompts ensure consistent, high-quality outputs from Claude.

### Core Principles

1. **Be Specific and Clear**
   - Define exact outputs and formats
   - Use concrete examples
   - Avoid ambiguous instructions

2. **Structure Information Hierarchically**
   - Start with role/persona
   - Follow with objectives
   - End with constraints/warnings

3. **Use Multiple Prompting Techniques**
   - Combine different techniques for better results
   - Layer constraints and guidance
   - Build in self-correction mechanisms

### Essential Prompting Techniques

#### 1. Role-Based Prompting (Persona)
```markdown
<persona>
You are an experienced software architect with 15+ years building distributed systems.
You prioritize reliability, maintainability, and clear documentation.
</persona>
```

#### 2. Chain-of-Thought (CoT)
```markdown
<thinking_framework>
Before making decisions, think step-by-step:
1. What is the core problem?
2. What are the constraints?
3. What's the simplest solution?
4. What could go wrong?
5. How do we mitigate risks?
</thinking_framework>
```

#### 3. Few-Shot Examples
```markdown
<examples>
Good commit message: "fix: resolve race condition in auth token refresh"
Bad commit message: "fix bug"

Good branch name: "feat/user/auth-multi-factor"
Bad branch name: "new-feature"
</examples>
```

#### 4. Structured Output Templates
```markdown
<output_template>
## Summary
[1-2 sentences describing the change]

## Changes
- Change 1: [specific file/function modified]
- Change 2: [specific file/function modified]

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
</output_template>
```

#### 5. Constraint-Based Instructions
```markdown
<constraints>
- NEVER modify files outside the current module
- ALWAYS run tests before committing
- MUST use existing patterns found in codebase
- Maximum 500 lines per file
</constraints>
```

#### 6. Self-Validation Checkpoints
```markdown
<validation>
Before proceeding, verify:
✓ Does this follow existing patterns?
✓ Are all edge cases handled?
✓ Is the code testable?
✓ Would a new developer understand this?
</validation>
```

#### 7. Anti-Pattern Warnings
```markdown
<anti_patterns>
❌ DO NOT create mega-functions > 50 lines
❌ AVOID nested callbacks > 3 levels deep
❌ NEVER commit sensitive data
❌ DON'T use magic numbers without constants
</anti_patterns>
```

#### 8. Progressive Disclosure
```markdown
### Quick Start
[Essential information for 80% of use cases]

### Advanced Usage
[Detailed information for complex scenarios]

### Edge Cases
[Rare but important scenarios]
```

#### 9. Interactive Decision Points
```markdown
<decision_points>
- [ ] Present technology choices → STOP for user input
- [ ] Show implementation plan → STOP for approval
- [ ] Complete implementation → STOP before deployment
</decision_points>
```

#### 10. Meta-Prompting (Self-Improvement)
```markdown
<reflection>
After completing the task:
1. What worked well?
2. What was challenging?
3. How could the process improve?
4. Document lessons learned in journal
</reflection>
```

### Advanced Techniques

#### XML-Style Semantic Structure
```markdown
<task_definition>
  <objective>Build a REST API for user management</objective>
  <requirements>
    <functional>CRUD operations, authentication, authorization</functional>
    <non_functional>< 100ms response time, 99.9% uptime</non_functional>
  </requirements>
  <constraints>
    <technical>Node.js, PostgreSQL, JWT</technical>
    <timeline>2 weeks</timeline>
  </constraints>
</task_definition>
```

#### Cognitive Load Management
- Break complex tasks into phases
- Use clear section headers
- Provide visual indicators (✓, ❌, ⚠️)
- Limit choices to 3-5 options

#### Prompt Chaining
Link multiple prompts for complex workflows:
```markdown
Step 1: Use `/plan` to create project structure
Step 2: Use `/implement` for each component
Step 3: Use `/test` to verify functionality
Step 4: Use `/document` to create docs
```

### Best Practices Checklist

- [ ] **Clear Persona**: Define expertise and approach
- [ ] **Specific Objectives**: State exact goals
- [ ] **Concrete Examples**: Show good/bad patterns
- [ ] **Structured Output**: Define expected format
- [ ] **Decision Points**: Mark where to pause for input
- [ ] **Error Prevention**: Include validation steps
- [ ] **Escape Hatches**: Provide fallback options
- [ ] **Concise Language**: Remove unnecessary words
- [ ] **Action-Oriented**: Use imperative mood
- [ ] **Measurable Success**: Define completion criteria

### Command Prompt Template

```markdown
<persona>
[Define role and expertise]
</persona>

<objective>
[State the primary goal]
</objective>

<context>
[Provide necessary background]
</context>

<approach>
[Describe the methodology]
</approach>

<steps>
1. [First action]
2. [Second action]
3. [Continue...]
</steps>

<constraints>
- [Limitation 1]
- [Limitation 2]
</constraints>

<output>
[Define expected deliverables]
</output>

<validation>
[How to verify success]
</validation>

⚠️ STOP: [When to pause for user input]
```

### Testing Your Prompts

1. **Clarity Test**: Can another person understand the intent?
2. **Completeness Test**: Are all edge cases covered?
3. **Consistency Test**: Does it produce similar outputs for similar inputs?
4. **Efficiency Test**: Is it concise without losing effectiveness?
5. **Robustness Test**: Does it handle unexpected scenarios gracefully?

## Important Notes

### Critical Development Guidelines

1. **Always use `--impure` flag** when running nix commands that need environment variables
2. **Module Dependencies**: When modifying modules, check both direct imports and transitive dependencies
3. **Platform Testing**: Changes to shared modules should be tested on all four platforms
4. **Configuration Application**:
   - Darwin: Uses `darwin-rebuild switch`
   - NixOS: Uses `nixos-rebuild switch`
   - Both are wrapped by platform-specific scripts in `apps/`
5. **Home Manager Integration**: User-specific configurations are managed through Home Manager

## Auto Branch Update System

This repository includes an **intelligent auto branch update system** that keeps PR branches synchronized with the main branch, enabling seamless auto-merge functionality.

### How It Works

**Problem Solved:**
- PRs become "behind" main branch when new commits are merged
- Branch protection rules prevent auto-merge until branches are up-to-date
- Manual branch updates are time-consuming and easy to forget

**Automated Solution:**
1. **Trigger**: Automatically runs when new commits are pushed to main
2. **Detection**: Scans all open PRs to find branches that are behind main
3. **Smart Update Strategy**:
   - First attempts `git merge main` (preserves commit history)
   - Falls back to `git rebase main` if merge fails (creates cleaner history)
   - If both fail, creates detailed conflict notification on PR
4. **Auto-merge Preservation**: Maintains auto-merge settings after successful updates

### Usage

**Automatic Operation:**
```bash
# No manual intervention needed - system runs automatically
git push origin main  # Triggers auto-update for all stale PRs
```

**Manual Testing:**
```bash
# Test the system locally
./scripts/test-branch-update

# Test with dry-run in GitHub Actions
gh workflow run auto-branch-update.yml -f dry_run=true
```

**Monitoring:**
- Check Actions tab for workflow execution status
- PR comments show detailed update results or conflict information
- Workflow summary provides overview of all processed PRs

### Configuration

The system is configured in `.github/workflows/auto-branch-update.yml` with:

- **Triggers**: Push to main, manual workflow_dispatch
- **Permissions**: Contents write, pull-requests write, checks read
- **Timeout**: 20 minutes for branch updates, 10 minutes for detection
- **Concurrency**: Only one update workflow runs at a time

### Conflict Resolution

When conflicts occur, the system:
1. **Automatically comments on PR** with detailed conflict information
2. **Lists conflicted files** for easy identification
3. **Provides resolution steps** for developers
4. **Preserves original branch state** (no data loss)

**Manual Resolution Process:**
```bash
# In your local repository
git checkout your-feature-branch
git merge main  # or git rebase main
# Resolve conflicts manually
git add .
git commit -m "resolve conflicts"
git push origin your-feature-branch
# Auto-merge will resume automatically
```

### Workflow Requirements

- **Ask before major changes**: Always confirm before proceeding with significant modifications
- **Enable auto-merge for PRs**: Always turn on auto-merge option when creating pull requests
  ```bash
  # Method 1: Enable during PR creation
  gh pr create --assignee @me
  gh pr merge --auto --squash

  # Method 2: Enable for existing PR
  gh pr merge --auto --squash <PR-number>

  # Method 3: Via GitHub web interface
  # Navigate to PR → Click "Enable auto-merge" → Select "Squash and merge"
  ```

  **Auto-merge Benefits:**
  - ✅ Automatically merges when all CI checks pass
  - ✅ Reduces manual monitoring of PR status  
  - ✅ Ensures consistent squash-and-merge workflow
  - ✅ Speeds up development cycle

  **Prerequisites for auto-merge:**
  - All required CI checks must pass (lint, test, build)
  - No merge conflicts
  - Branch must be up-to-date with main
  - Repository admin approval (if required)
- **No AI attribution**: Act as if Claude Code was not used - do not mention AI assistance in commits or PRs
- **sudo requirements**: `nix run .#build-switch` can only be executed with root privileges
- **Tab navigation**: Maintain tab navigation functionality in UI components
- **Claude config preservation**: User modifications to Claude settings are automatically preserved

### Legacy Information

- System uses `build-switch` command for immediate configuration application
- All builds require USER environment variable to be set
- Root privileges are required for system-level configuration changes
