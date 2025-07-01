# Migration Guide

> **Comprehensive guide for migrating to the Nix dotfiles system**

This guide helps users migrate from other dotfiles systems or upgrade existing Nix configurations to this comprehensive framework.

## Migration Scenarios

### From Traditional Dotfiles

**Common sources**: Oh My Zsh, Bash configurations, manual symlink management

#### Assessment

1. **Inventory current configuration**:
   ```bash
   # List current dotfiles
   ls -la ~ | grep '^\.'
   
   # Document installed packages
   brew list > brew-packages.txt  # macOS
   apt list --installed > apt-packages.txt  # Ubuntu/Debian
   ```

2. **Identify core configurations**:
   - Shell configuration (`.zshrc`, `.bashrc`)
   - Editor settings (`.vimrc`, VS Code settings)
   - Git configuration (`.gitconfig`)
   - SSH configuration (`.ssh/config`)

#### Migration Process

1. **Backup existing configuration**:
   ```bash
   mkdir ~/dotfiles-backup
   cp -r ~/.zshrc ~/.gitconfig ~/.vimrc ~/dotfiles-backup/
   ```

2. **Install Nix dotfiles system**:
   ```bash
   git clone https://github.com/baleen37/dotfiles.git
   cd dotfiles
   export USER=$(whoami)
   make build
   ```

3. **Gradual migration approach**:
   - Start with basic installation
   - Add packages progressively
   - Migrate configurations incrementally

#### Package Translation

**Homebrew to Nix** (macOS):
```bash
# Convert Homebrew packages
brew list | while read package; do
  echo "# $package -> check nixpkgs"
done

# Common translations:
# brew: node -> nixpkgs: nodejs
# brew: python3 -> nixpkgs: python3
# brew: git -> nixpkgs: git
```

**APT to Nix** (Linux):
```bash
# Common translations:
# apt: vim -> nixpkgs: vim
# apt: curl -> nixpkgs: curl
# apt: build-essential -> nixpkgs: gcc gnumake
```

### From Other Nix Configurations

**Common sources**: home-manager standalone, custom flakes, nix-env usage

#### Compatibility Assessment

1. **Check Nix version compatibility**:
   ```bash
   nix --version
   # Requires Nix 2.4+ with flakes support
   ```

2. **Review existing configuration**:
   ```bash
   # Check for existing home-manager
   home-manager --version
   
   # List current generations
   nix-env --list-generations
   ```

#### Migration Strategy

1. **Preserve existing generations**:
   ```bash
   # Backup current generation
   nix-env --list-generations > generations-backup.txt
   ```

2. **Incremental adoption**:
   - Use alongside existing configuration initially
   - Test thoroughly before full migration
   - Migrate module by module

### From NixOS System Configuration

**Scenario**: Migrating from standalone NixOS configuration to this comprehensive system

#### Assessment

1. **Review current system configuration**:
   ```bash
   # Check current configuration location
   readlink /etc/nixos/configuration.nix
   
   # Review hardware configuration
   cat /etc/nixos/hardware-configuration.nix
   ```

2. **Identify custom modules and packages**:
   ```bash
   # List custom packages
   nix-env -qa --installed
   
   # Review system packages
   sudo nixos-rebuild dry-run
   ```

#### Migration Process

1. **Backup current configuration**:
   ```bash
   sudo cp -r /etc/nixos /etc/nixos-backup
   ```

2. **Integrate with dotfiles system**:
   - Use existing hardware configuration
   - Migrate custom modules to appropriate locations
   - Maintain system-level settings

3. **Test configuration**:
   ```bash
   # Test build without applying
   sudo nixos-rebuild dry-build --flake .#hostname
   
   # Apply when ready
   sudo nixos-rebuild switch --flake .#hostname
   ```

## Configuration Migration

### Shell Configuration

**Zsh configuration migration**:

1. **Extract custom functions and aliases**:
   ```bash
   # From .zshrc, extract:
   # - Custom aliases
   # - Functions
   # - Environment variables
   # - Plugin configurations
   ```

2. **Add to dotfiles system**:
   - Edit `modules/shared/home-manager.nix`
   - Add shell aliases and functions
   - Configure shell options

### Editor Configuration

**Vim/Neovim migration**:

1. **Plugin identification**:
   ```bash
   # List current plugins from .vimrc or init.vim
   grep -E "Plugin|Plug|call plug#" ~/.vimrc
   ```

2. **Nix package integration**:
   - Add vim plugins via `modules/shared/packages.nix`
   - Configure via Home Manager vim module

### Application Settings

**VS Code/IDE migration**:

1. **Settings export**:
   ```bash
   # Export VS Code settings
   cp ~/Library/Application\ Support/Code/User/settings.json settings-backup.json
   ```

2. **Declarative configuration**:
   - Add VS Code extensions to `modules/darwin/casks.nix`
   - Configure settings via Home Manager

## Troubleshooting Migration Issues

### Common Problems

**Conflicting configurations**:
```bash
# Check for conflicts
ls -la ~ | grep -E '\.(nix-|home-manager)'

# Remove old home-manager
nix-env -e home-manager
```

**Package not found**:
```bash
# Search nixpkgs
nix search nixpkgs package-name

# Check alternative names
nix search nixpkgs ".*keyword.*"
```

**Build failures**:
```bash
# Clear cache
nix store gc

# Rebuild with trace
nix build --impure --show-trace .#darwinConfigurations.system
```

### Recovery Procedures

**Rollback strategy**:

1. **System rollback** (NixOS):
   ```bash
   # List available generations
   sudo nixos-rebuild list-generations
   
   # Rollback to previous generation
   sudo nixos-rebuild switch --rollback
   ```

2. **Home Manager rollback**:
   ```bash
   # List home-manager generations
   home-manager generations
   
   # Activate previous generation
   /nix/store/...-home-manager-generation/activate
   ```

3. **Complete system restore**:
   ```bash
   # Restore backed up configuration
   cp -r ~/dotfiles-backup/.* ~/
   
   # Reinstall previous package manager
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

## Validation and Testing

### Post-Migration Verification

1. **Functionality testing**:
   ```bash
   # Test shell functionality
   echo $SHELL
   which zsh
   
   # Test package availability
   git --version
   vim --version
   docker --version
   ```

2. **Configuration validation**:
   ```bash
   # Verify Nix configuration
   make lint
   make build
   make test
   ```

3. **Performance verification**:
   ```bash
   # Check build times
   make build-time
   
   # Test update process
   ./scripts/auto-update-dotfiles --force
   ```

### Gradual Rollout Strategy

1. **Phase 1**: Core system (shell, git, basic tools)
2. **Phase 2**: Development tools (editors, language runtimes)
3. **Phase 3**: Specialized tools (Docker, cloud tools)
4. **Phase 4**: GUI applications and system integrations

## Best Practices

### Migration Planning

1. **Document current state**: Create inventory of packages and configurations
2. **Test in isolation**: Use separate user account or VM for testing
3. **Incremental approach**: Migrate components gradually
4. **Backup strategy**: Maintain backups throughout process
5. **Rollback plan**: Always have a recovery strategy

### Long-term Maintenance

1. **Configuration tracking**: Use git to track all changes
2. **Regular testing**: Run test suite after modifications
3. **Update management**: Use auto-update system with testing
4. **Documentation**: Keep migration notes for future reference

## Success Criteria

Migration is complete when:

- [ ] All required packages are available
- [ ] Shell configuration works correctly
- [ ] Development tools function properly
- [ ] Build and test systems pass
- [ ] System performance is acceptable
- [ ] Backup and rollback procedures tested

---

**Next Steps**: After successful migration, review [CONTRIBUTING.md](../CONTRIBUTING.md) for ongoing development guidelines and [architecture documentation](./architecture.md) for system understanding.