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

# Evaluate the complete supported platform matrix
nix flake check --no-build --all-systems --show-trace

# Build representative configuration closures without activation
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'
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
- [ ] Run `nix flake check --no-build --all-systems --show-trace` to evaluate the baseline matrix

#### 2. Development Loop

```bash
# Make your changes
# ...

# Evaluate all supported systems
nix flake check --no-build --all-systems --show-trace

# Build affected configuration closures without activation
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'

# Activate a standalone Home Manager profile when that is the intended target
make switch-home HM_USER=jito.hello
```

#### 3. Pre-Commit Workflow

**Always run these commands in order before committing:**

```bash
nix flake check --no-build --all-systems --show-trace
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'
make switch-home HM_USER=jito.hello
```

### Testing Strategy

#### Local Testing

```bash
nix flake check --no-build --all-systems --show-trace  # Evaluate all checks
nix build '.#darwinConfigurations.macbook-pro.system'
nix build '.#nixosConfigurations.vm-aarch64-utm.config.system.build.toplevel'
make switch-home HM_USER=jito.hello
nix build '.#checks.x86_64-linux.unit-mksystem'   # A single check
```

`make test` falls back to `nix flake check --no-build` wherever the container
tests cannot run, and `--no-build` only _evaluates_ checks — a false assertion is
never built and never fails. Use `make test-build` to actually run assertions.

#### Testing on Multiple Platforms

The current platform matrix is:

- **Darwin**: `aarch64-darwin`
- **NixOS**: `x86_64-linux`, `aarch64-linux`

`HM_USER` selects a standalone Home Manager profile. Permanent host system users
are declared by the `user` field in typed `dotfiles.hosts` entries.

## 📝 Contribution Guidelines

### Code Style and Standards

#### Nix Code

- **Consistent formatting**: Use `nix fmt` (the flake formatter runs treefmt)
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
   - `users/shared/packages/<category>.nix`: shared package categories
   - `users/shared/programs/<tool>.nix`: tool-specific Home Manager configuration
   - `users/shared/darwin/homebrew.nix`: Darwin Homebrew packages and casks

2. **Follow the existing pattern:**

   ```nix
   # users/shared/packages/dev.nix
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
   # users/shared/programs/my-new-module.nix
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
   # In users/shared/home-manager.nix or the appropriate parent module
   imports = [
     ./modules/shared/my-new-module.nix
   ];
   ```

3. **Test across platforms:**

   ```bash
   # Test on current platform
   nix build '.#darwinConfigurations.macbook-pro.system'

   # Test specific platforms if needed
   nix build .#darwinConfigurations.macbook-pro.system
   nix build .#nixosConfigurations.vm-x86_64-utm.config.system.build.toplevel
   ```

### Testing Contributions

#### Writing Tests

Follow the hierarchical test structure and use consistent helper patterns:

```bash
tests/
├── unit/           # One module or library, evaluated in isolation
├── integration/    # Configurations evaluated against each other
├── containers/     # NixOS VM tests (Linux + KVM)
└── lib/            # Shared assertions and fixtures
```

**Use the consistent test helper framework:**

```nix
# tests/unit/my-feature-test.nix -> checks.<system>.unit-my-feature
{ pkgs, lib, ... }:

let
  helpers = import ../lib/test-helpers.nix { inherit pkgs lib; };
  subject = import ../../users/shared/programs/my-feature.nix {
    inherit pkgs lib;
    config.modules.programs.my-feature.enable = true;
  };
in
{
  platforms = [ "any" ];   # or ["darwin"] / ["linux"]
  value = helpers.testSuite "my-feature" [
    (helpers.assertTest "some-invariant" (subject.config.content.programs.my-feature.enable)
      "why this matters, and what breaks when it does not hold"
    )
  ];
}
```

Assert over the module's real output, never over values the test defines itself —
`let x = true; in x` passes forever and covers nothing.

#### Test Helper Functions

`tests/lib/test-helpers.nix`:

- **`helpers.assertTest name condition message`**: fails the build when false
- **`helpers.testSuite name tests`**: aggregates assertions into one check

`tests/lib/common-assertions.nix` adds assertions that generate their own failure
text (`assertAttrEquals`, `assertAttrPathExists`, `assertListContains`, ...); each
takes a trailing `message`, `null` for the generated one.

#### Detailed Testing Guidelines

`tests/README.md` covers the full test contract, the `platforms` metadata, and
what is and is not worth asserting.

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
make switch
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
nix build --show-trace .#darwinConfigurations.macbook-pro.system
```

### Testing Failures

**Test discovery issues:**

```bash
# List every discovered check
nix flake show --all-systems

# A test file that fails to import shows up as a failing check named after it;
# build it to see the reason
nix build '.#checks.aarch64-darwin.unit-claude'
```

## 📋 Pull Request Process

### Before Submitting

1. **Complete the pre-commit workflow:**

   ```bash
   make lint && make test-build && nix build '.#darwinConfigurations.macbook-pro.system'
   ```

2. **Run comprehensive local tests:**

   ```bash
   make test && make test-build
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

- [ ] Local tests pass (`make test-build`)
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
