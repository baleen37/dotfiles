# Scripts and Tools Reference

> **Comprehensive guide to all scripts and automation tools in the dotfiles repository**

This document provides detailed information about the various scripts and tools available in this repository, their purposes, usage patterns, and integration points.

## 📁 Scripts Overview

All scripts are located in the `scripts/` directory and serve different aspects of the development and management workflow.

```
scripts/
├── auto-update-dotfiles     # Automatic dotfiles update system
├── bl                       # Command dispatcher system
├── install-setup-dev        # bl system installer
├── merge-claude-config      # Interactive configuration merger
├── setup-dev               # New project initializer
└── test-all-local          # Comprehensive local testing
```

## 🔄 Auto-Update System

### `auto-update-dotfiles`

An intelligent automatic update system with TTL-based checking and safe update mechanisms.

#### Features
- **TTL-based checking**: Only checks for updates every hour by default
- **Local change detection**: Skips updates if local modifications exist
- **Automatic application**: Runs `build-switch` for immediate application
- **Background operation**: Can run silently in background
- **Logging**: Comprehensive logging for troubleshooting

#### Usage
```bash
# Basic usage (respects TTL)
./scripts/auto-update-dotfiles

# Force check regardless of TTL
./scripts/auto-update-dotfiles --force

# Run silently (for shell integration)
./scripts/auto-update-dotfiles --silent

# Show help
./scripts/auto-update-dotfiles --help
```

#### Integration Points
- **Shell startup**: Automatically triggered via `zsh` configuration
- **Home Manager**: Integrated through `modules/shared/home-manager.nix`
- **Nix apps**: Available as `nix run .#auto-update`

#### Configuration
```bash
# Environment variables
TTL_SECONDS=3600          # Check interval (1 hour)
CACHE_DIR="$HOME/.cache"  # Cache location
DOTFILES_DIR="$HOME/dotfiles"  # Repository location
```

#### Logs and Troubleshooting
```bash
# Check logs
tail -f ~/.cache/dotfiles-update.log

# Check last update time
cat ~/.cache/dotfiles-check

# Manual TTL reset
rm ~/.cache/dotfiles-check
```

## 🎛️ bl Command System

### `bl` - Command Dispatcher

A global command system that provides consistent access to development tools across different projects.

#### Architecture
- **Dispatcher**: `~/.local/bin/bl` - Main command router
- **Commands**: `~/.bl/commands/` - Individual command implementations
- **PATH integration**: Automatically added to user PATH

#### Usage
```bash
# List all available commands
bl list

# Run a specific command
bl setup-dev my-project

# Get help for a command
bl setup-dev --help

# Install the system
bl install
```

#### Adding Custom Commands
```bash
# Create a new command
cat > ~/.bl/commands/my-command << 'EOF'
#!/usr/bin/env bash
echo "Hello from my custom command!"
EOF

chmod +x ~/.bl/commands/my-command

# Now available as
bl my-command
```

### `install-setup-dev` - bl System Installer

One-time installer for the bl command system.

#### What it does
1. Copies `bl` dispatcher to `~/.local/bin/bl`
2. Creates `~/.bl/commands/` directory
3. Installs `setup-dev` as the first command
4. Verifies PATH configuration

#### Usage
```bash
# Install bl system
./scripts/install-setup-dev

# Verify installation
bl list
which bl
```

## 🚀 Project Initialization

### `setup-dev` - New Project Creator

Creates new Nix development projects with flake.nix, direnv integration, and best practices.

#### Features
- **Flake template**: Creates basic `flake.nix` with development shell
- **direnv integration**: Automatic `.envrc` setup
- **Git patterns**: Includes Nix-specific `.gitignore`
- **Shell integration**: Optional direnv hook installation
- **Platform agnostic**: Works on macOS and NixOS

#### Usage
```bash
# Initialize current directory
./scripts/setup-dev

# Create new project
./scripts/setup-dev my-new-project

# Via nix flake app
nix run .#setup-dev my-project

# Via bl system (after installation)
bl setup-dev my-project

# Get help
./scripts/setup-dev --help
```

#### Generated Files
```
my-project/
├── flake.nix      # Nix flake with dev shell
├── .envrc         # direnv configuration
└── .gitignore     # Nix-specific patterns
```

#### Template Customization
The script generates a basic template. You can customize by:
```bash
# Edit the generated flake.nix
cd my-project
$EDITOR flake.nix

# Add more packages to buildInputs
# Customize shellHook for project setup
# Add additional flake outputs as needed
```

## 🔧 Configuration Management

### `merge-claude-config` - Interactive Configuration Merger

Advanced tool for safely merging dotfiles updates with user customizations, specifically designed for Claude configuration files.

#### Features
- **Change detection**: Uses SHA256 hashes to detect modifications
- **Interactive merging**: JSON and text file merge support
- **Backup creation**: Automatic backups before any changes
- **Selective merging**: Choose specific sections to merge
- **Conflict resolution**: Multiple merge strategies

#### Usage
```bash
# List files needing merge
./scripts/merge-claude-config --list

# Merge specific file
./scripts/merge-claude-config settings.json

# Interactive merge all files
./scripts/merge-claude-config

# View differences only
./scripts/merge-claude-config --diff CLAUDE.md

# Get help
./scripts/merge-claude-config --help
```

#### Merge Strategies

**JSON Files (settings.json):**
- Key-by-key selection
- Current value preservation
- New value adoption
- Selective key addition

**Text Files (CLAUDE.md, commands/*.md):**
- Keep current file
- Replace with new file
- External editor merge
- Section-based merge

#### Backup Management
```bash
# Backups location
ls ~/.claude/.backups/

# Restore from backup
cp ~/.claude/.backups/settings.json.backup.20240106_143022 ~/.claude/settings.json
```

## 🧪 Testing and Quality Assurance

### `test-all-local` - Comprehensive Local Testing

Mirrors the CI/CD pipeline locally to prevent build failures and ensure code quality.

#### Test Categories
1. **Pre-commit lint checks**: Code formatting and style
2. **Smoke tests**: Quick flake validation
3. **Unit tests**: Individual component testing
4. **Integration tests**: Module interaction testing
5. **Build tests**: Full system configuration builds
6. **End-to-end tests**: Complete workflow validation

#### Usage
```bash
# Run all tests (mirrors CI)
./scripts/test-all-local

# Show help and test breakdown
./scripts/test-all-local --help
```

#### Output and Logging
```bash
# Test results with timestamps
=== TEST RESULTS SUMMARY ===
Total Tests: 7
Passed: 7
Failed: 0
Log File: test-results-20240106-143022.log
==========================
```

#### Individual Test Access
```bash
# Run specific test categories
make test-unit          # Unit tests only
make test-integration   # Integration tests only
make test-e2e           # End-to-end tests only
make test-perf          # Performance tests only
```

## 🔗 Integration Points

### Shell Integration

**Zsh Startup (`modules/shared/home-manager.nix`):**
```bash
# Auto-update trigger
if [[ -x "$HOME/dotfiles/scripts/auto-update-dotfiles" ]]; then
  (nohup "$HOME/dotfiles/scripts/auto-update-dotfiles" --silent &>/dev/null &)
fi
```

### Nix Flake Apps

Scripts are exposed as flake applications:
```bash
# Available apps
nix run .#setup-dev
nix run .#auto-update
nix run .#test
nix run .#test-unit
nix run .#test-integration
```

### CI/CD Integration

Scripts used in GitHub Actions:
- `test-all-local`: Comprehensive testing
- `auto-update-dotfiles`: Automated maintenance
- Pre-commit hooks: Code quality enforcement

## 🛠️ Development and Customization

### Script Development Guidelines

#### Error Handling
```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Proper error handling
if ! command -v nix >/dev/null 2>&1; then
    print_error "Nix not found"
    exit 1
fi
```

#### Consistent Output
```bash
# Use consistent color scheme
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[SCRIPT]${NC} $1"
}
```

#### Help and Usage
```bash
# Always include help
usage() {
    echo "Usage: $0 [OPTIONS] [ARGS]"
    echo "Description of what the script does"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help"
    # ... more options
}
```

### Adding New Scripts

#### 1. Create the Script
```bash
# Create in scripts/ directory
cat > scripts/my-new-script << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Your script here
EOF

chmod +x scripts/my-new-script
```

#### 2. Test the Script
```bash
# Test locally
./scripts/my-new-script

# Test integration
make lint
make test
```

#### 3. Add to Flake (Optional)
```nix
# In flake.nix, add to mkDarwinApps or mkLinuxApps
"my-new-script" = {
  type = "app";
  program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "my-new-script" (builtins.readFile ./scripts/my-new-script))}/bin/my-new-script";
};
```

#### 4. Add to bl System (Optional)
```bash
# Install globally
cp scripts/my-new-script ~/.bl/commands/
bl my-new-script
```

### Testing Scripts

#### Unit Testing
```nix
# tests/unit/my-script-unit.nix
{ pkgs }:

pkgs.runCommand "my-script-test" {} ''
  # Test script functionality
  ${./scripts/my-new-script} --help
  echo "Script test passed"
  touch $out
''
```

#### Integration Testing
```bash
# Test with other components
./scripts/my-new-script
make build  # Ensure no conflicts
```

## 🚨 Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Ensure scripts are executable
chmod +x scripts/*

# Check PATH for bl commands
echo $PATH | grep -q "$HOME/.local/bin" || echo "Add ~/.local/bin to PATH"
```

#### Environment Issues
```bash
# Ensure USER is set
export USER=$(whoami)

# Check Nix installation
command -v nix || echo "Install Nix"
```

#### TTL Issues (auto-update)
```bash
# Force update check
rm ~/.cache/dotfiles-check
./scripts/auto-update-dotfiles --force
```

#### bl System Issues
```bash
# Reinstall bl system
./scripts/install-setup-dev

# Check command availability
bl list

# Debug command execution
bash -x ~/.local/bin/bl setup-dev
```

### Debugging

#### Enable Verbose Output
```bash
# Most scripts support verbose flags
./scripts/merge-claude-config --verbose
./scripts/test-all-local  # Inherently verbose
```

#### Check Logs
```bash
# Auto-update logs
tail -f ~/.cache/dotfiles-update.log

# Test logs
ls test-results-*.log
```

#### Manual Testing
```bash
# Test individual components
nix run .#setup-dev test-dir
./scripts/auto-update-dotfiles --force
./scripts/merge-claude-config --list
```

## 📈 Performance Considerations

### Auto-Update Optimization
- **TTL caching**: Reduces unnecessary checks
- **Background execution**: Non-blocking operation
- **Conditional updates**: Only updates when needed

### bl System Efficiency
- **PATH integration**: Fast command resolution
- **Minimal overhead**: Simple dispatcher design
- **Local storage**: Commands stored locally for speed

### Testing Performance
- **Parallel execution**: Run tests concurrently where possible
- **Cache utilization**: Leverage Nix build cache
- **Selective testing**: Run only relevant tests during development

---

> **Note**: All scripts are designed to be self-documenting with `--help` flags. Use them for the most up-to-date usage information.
