# Contributing to dotfiles

> **A comprehensive guide for contributors to the Nix-based dotfiles repository**

Thank you for your interest in contributing to this project! This guide will help you understand our development workflow, coding standards, and how to make meaningful contributions.

## 🚀 Quick Start for Contributors

### Prerequisites

Before contributing, ensure you have:

1. **Nix** with flakes support installed
2. **Git** configured with your identity
3. **Basic understanding** of Nix expressions and flakes
4. **Administrative access** for testing system-level changes

### Initial Setup

```bash
# Fork and clone the repository
git clone https://github.com/<your-username>/dotfiles.git
cd dotfiles

# Set up the development environment
export USER=$(whoami)
make smoke    # Quick validation
make lint     # Check code quality
```

## 🛠️ Development Workflow

### Branch Management

- **`main`**: Production-ready code, protected branch
- **Feature branches**: `feature/description`, `fix/description`, or `docs/description`
- **Testing branches**: Use for experimental changes

```bash
# Create a new feature branch
git checkout -b feature/add-new-package
git push -u origin feature/add-new-package

# After development
git checkout main
git pull origin main
git merge feature/add-new-package
```

### Development Process

#### 1. Pre-Development Checklist
- [ ] Create a descriptive branch name
- [ ] Ensure `USER` environment variable is set
- [ ] Run `make smoke` to verify baseline functionality

#### 2. Development Loop
```bash
# Make your changes
# ...

# Test your changes
make lint           # Code quality checks
make smoke          # Quick validation
make build          # Full system build
make test           # Run test suite

# Test on target platform(s)
nix run --impure .#build-switch  # Test system integration
```

#### 3. Pre-Commit Workflow
**Always run these commands in order before committing:**
```bash
make lint     # pre-commit run --all-files  
make smoke    # nix flake check --all-systems --no-build
make build    # build all NixOS/darwin configurations
make smoke    # final flake check after build
```

### Testing Strategy

#### Local Testing
```bash
# Comprehensive local testing (matches CI)
./scripts/test-all-local

# Individual test categories
make test-unit                    # Unit tests only
make test-integration             # Integration tests only  
make test-e2e                     # End-to-end tests only
make test-perf                    # Performance tests only
```

#### Testing on Multiple Platforms
If your changes affect multiple platforms, test on:
- **macOS**: x86_64-darwin, aarch64-darwin
- **NixOS**: x86_64-linux, aarch64-linux

## 📝 Contribution Guidelines

### Code Style and Standards

#### Nix Code
- **Consistent formatting**: Use `nixpkgs-fmt` (automatically applied via pre-commit)
- **Clear attribute names**: Use descriptive, semantic naming
- **Documentation**: Add comments for complex logic
- **Platform compatibility**: Test on all supported platforms

```nix
# Good: Descriptive and well-formatted
{ pkgs, lib, ... }:
let
  # Custom packages for development workflow
  devPackages = with pkgs; [
    git
    vim
    curl
  ];
in
{
  home.packages = devPackages;
}

# Avoid: Poor formatting and unclear naming
{pkgs,...}:{home.packages=with pkgs;[git vim curl];}
```

#### Shell Scripts
- **Proper error handling**: Use `set -euo pipefail`
- **Clear functions**: Break complex logic into functions
- **Colored output**: Use consistent color schemes
- **Help messages**: Include usage information

```bash
#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
```

### Module Development

#### Adding New Packages

1. **Determine the appropriate location:**
   - `modules/shared/packages.nix`: Cross-platform packages
   - `modules/darwin/packages.nix`: macOS-specific packages
   - `modules/nixos/packages.nix`: NixOS-specific packages
   - `modules/darwin/casks.nix`: Homebrew casks

2. **Follow the existing pattern:**
   ```nix
   # modules/shared/packages.nix
   { pkgs }:

   with pkgs; [
     # Existing packages...
     
     # New package with comment
     new-package    # Brief description of what this package does
   ]
   ```

#### Creating New Modules

1. **Create the module file:**
   ```nix
   # modules/shared/my-new-module.nix
   { config, pkgs, lib, ... }:

   {
     # Module configuration
     programs.my-program = {
       enable = true;
       # ... configuration
     };
   }
   ```

2. **Import in appropriate locations:**
   ```nix
   # In host configuration or parent module
   imports = [
     ./modules/shared/my-new-module.nix
   ];
   ```

3. **Test across platforms:**
   ```bash
   # Test on current platform
   make build
   
   # Test specific platforms if needed
   nix build --impure .#darwinConfigurations.aarch64-darwin.system
   nix build --impure .#nixosConfigurations.x86_64-linux.config.system.build.toplevel
   ```

### Testing Contributions

#### Writing Tests

Follow the hierarchical test structure:

```bash
tests/
├── unit/           # Individual function/module tests
├── integration/    # Module interaction tests
├── e2e/           # Complete workflow tests
└── performance/   # Build time and resource tests
```

**Example unit test:**
```nix
# tests/unit/my-feature-unit.nix
{ pkgs }:

pkgs.runCommand "my-feature-unit-test" {} ''
  echo "Testing my feature..."
  
  # Your test logic here
  ${pkgs.my-package}/bin/my-command --version
  
  echo "Test passed!"
  touch $out
''
```

#### Test Categories

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test module interactions and dependencies
- **E2E Tests**: Test complete workflows and system behavior
- **Performance Tests**: Monitor build times and resource usage

### Documentation

#### When Documentation is Required

- **New features**: Any new functionality must be documented
- **Breaking changes**: Changes that affect existing workflows
- **Complex configurations**: Non-obvious setup procedures
- **Scripts and tools**: Usage instructions for new scripts

#### Documentation Standards

- **Clear explanations**: Write for developers unfamiliar with the project
- **Code examples**: Include practical, working examples
- **Platform differences**: Note platform-specific behavior
- **Troubleshooting**: Include common issues and solutions

## 🔄 Advanced Features

### Claude Configuration Preservation

When modifying the Claude configuration system:

1. **Understand the preservation mechanism:**
   - Uses SHA256 hashes to detect user modifications
   - Prioritizes user customizations over dotfiles updates
   - Provides interactive merge tools for conflicts

2. **Test configuration changes:**
   ```bash
   # Test the merge tool
   ./scripts/merge-claude-config --help
   ./scripts/merge-claude-config --list
   ```

3. **Document policy changes in:**
   - `modules/shared/lib/claude-config-policy.nix`
   - Update preservation behavior documentation

### Auto-Update System

When modifying the auto-update functionality:

1. **Test the TTL behavior:**
   ```bash
   # Test with different flags
   ./scripts/auto-update-dotfiles --force
   ./scripts/auto-update-dotfiles --silent
   ```

2. **Consider edge cases:**
   - Network connectivity issues
   - Local uncommitted changes
   - Permission problems with build-switch

### bl Command System

When adding new global commands:

1. **Install the system:**
   ```bash
   ./scripts/install-setup-dev
   ```

2. **Test command integration:**
   ```bash
   bl list
   bl setup-dev test-project
   ```

3. **Follow naming conventions:**
   - Use descriptive command names
   - Include help text (`--help` flag)
   - Handle error cases gracefully

## 🚨 Common Issues and Solutions

### Build Failures

**Environment variable issues:**
```bash
# Always ensure USER is set
export USER=$(whoami)
nix run --impure .#build
```

**Flake lock conflicts:**
```bash
# Update flake inputs
nix flake update
nix flake lock --update-input nixpkgs
```

**Platform-specific issues:**
```bash
# Clear nix store cache
nix store gc

# Rebuild with detailed traces
nix build --impure --show-trace .#darwinConfigurations.aarch64-darwin.system
```

### Testing Failures

**Test discovery issues:**
```bash
# Check test framework status
make test-status
nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').framework_status
```

**Claude configuration tests:**
```bash
# Test Claude config preservation
nix build --impure .#checks.$(nix eval --impure --expr 'builtins.currentSystem').claude_config_copy_unit
```

## 📋 Pull Request Process

### Before Submitting

1. **Complete the pre-commit workflow:**
   ```bash
   make lint && make smoke && make build && make smoke
   ```

2. **Run comprehensive local tests:**
   ```bash
   ./scripts/test-all-local
   ```

3. **Update documentation** if needed

4. **Test on multiple platforms** if applicable

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
- [ ] Local tests pass (`./scripts/test-all-local`)
- [ ] Pre-commit workflow complete
- [ ] Tested on target platforms: [list platforms]

## Documentation
- [ ] Documentation updated
- [ ] Breaking changes documented

## Additional Notes
Any additional information, considerations, or context
```

### Review Process

1. **Automated checks**: All CI tests must pass
2. **Code review**: At least one maintainer review required
3. **Platform testing**: Changes tested on affected platforms
4. **Documentation review**: Ensure docs are complete and accurate

## 🎯 Best Practices

### Security

- **Never commit secrets**: Use environment variables or external files
- **Validate inputs**: Sanitize user inputs in scripts
- **Use secure defaults**: Enable security features by default

### Performance

- **Optimize build times**: Use caching and parallel builds
- **Monitor resource usage**: Profile build performance
- **Lazy evaluation**: Avoid unnecessary computations

### Maintainability

- **Clear naming**: Use descriptive names for functions and variables
- **Modular design**: Break complex functionality into modules
- **Consistent patterns**: Follow established project patterns
- **Version compatibility**: Ensure compatibility with supported Nix versions

## 📚 Additional Resources

- **Nix Manual**: [https://nixos.org/manual/nix/stable/](https://nixos.org/manual/nix/stable/)
- **Nixpkgs Manual**: [https://nixos.org/manual/nixpkgs/stable/](https://nixos.org/manual/nixpkgs/stable/)
- **Home Manager Manual**: [https://nix-community.github.io/home-manager/](https://nix-community.github.io/home-manager/)
- **nix-darwin Documentation**: [https://github.com/LnL7/nix-darwin](https://github.com/LnL7/nix-darwin)

## 🤝 Getting Help

- **Documentation**: Check `CLAUDE.md` for detailed project guidelines
- **Testing**: Refer to `docs/testing-framework.md` for testing strategies
- **Architecture**: See `docs/structure.md` for system design details
- **Issues**: Open a GitHub issue for bugs or feature requests

---

> **Remember**: Quality contributions make the project better for everyone. Take time to test thoroughly and document clearly.