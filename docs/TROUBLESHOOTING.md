# Troubleshooting Guide

> **Common issues and their solutions for the Nix dotfiles system**

This guide covers the most frequently encountered issues and their step-by-step solutions.

## 🚨 Quick Diagnostics

### Essential Checks

Before diving into specific issues, run these diagnostic commands:

```bash
# 1. Verify Nix installation
nix --version

# 2. Check flakes support
nix flake --help

# 3. Verify USER environment variable
echo "USER: $USER"

# 4. Quick system validation
make smoke
```

### Emergency Recovery

If your system is in a broken state:

```bash
# 1. Try to rollback (Darwin only)
nix run .#rollback

# 2. Or rebuild from clean state
nix store gc
export USER=$(whoami)
make build
sudo nix run --impure .#build-switch
```

## 🔧 Installation Issues

### Nix Installation Problems

#### Issue: "nix: command not found"

**Symptoms:**
```bash
$ nix --version
bash: nix: command not found
```

**Solutions:**

1. **Source Nix environment** (if using official installer):
   ```bash
   source ~/.nix-profile/etc/profile.d/nix.sh

   # Add to shell profile for persistence
   echo 'source ~/.nix-profile/etc/profile.d/nix.sh' >> ~/.bashrc
   ```

2. **Reinstall with Determinate Systems installer**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

3. **Check PATH**:
   ```bash
   echo $PATH | grep nix
   # Should show /nix/store/... paths
   ```

#### Issue: "experimental feature 'flakes' is disabled"

**Symptoms:**
```bash
$ nix flake show
error: experimental feature 'flakes' is disabled
```

**Solution:**
```bash
# Enable flakes in Nix configuration
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Restart shell or source environment
source ~/.bashrc  # or ~/.zshrc
```

#### Issue: macOS Command Line Tools Missing

**Symptoms:**
```bash
error: unable to download 'https://...': Problem with the SSL CA cert
```

**Solution:**
```bash
# Install XCode Command Line Tools
xcode-select --install

# Wait for installation to complete, then retry
nix --version
```

## 🌍 Environment Variable Issues

### USER Variable Problems

#### Issue: "USER variable is not set"

**Symptoms:**
```bash
$ make build
❌ ERROR: USER variable is not set. Please run: export USER=$(whoami)
```

**Solutions:**

1. **Immediate fix**:
   ```bash
   export USER=$(whoami)
   make build
   ```

2. **Persistent solution** (add to shell profile):
   ```bash
   # For Bash
   echo "export USER=\$(whoami)" >> ~/.bashrc
   source ~/.bashrc

   # For Zsh  
   echo "export USER=\$(whoami)" >> ~/.zshrc
   source ~/.zshrc

   # For Fish
   echo "set -gx USER (whoami)" >> ~/.config/fish/config.fish
   ```

3. **Alternative using impure evaluation**:
   ```bash
   nix run --impure .#build
   ```

#### Issue: USER variable incorrect in sudo context

**Symptoms:**
```bash
$ sudo make switch
USER is set to: root  # Should be your username
```

**Solution:**
```bash
# Use -E flag to preserve environment
sudo -E USER=$USER make switch

# Or use build-switch which handles this automatically
sudo nix run --impure .#build-switch
```

## 🏗️ Build Issues

### Build Failures

#### Issue: "builder for '...' failed with exit code 1"

**Diagnostic steps:**
```bash
# 1. Check detailed error trace
nix build --impure --show-trace .#darwinConfigurations.aarch64-darwin.system

# 2. Check build logs
nix log .#darwinConfigurations.aarch64-darwin.system

# 3. Clear cache and retry
nix store gc
make build
```

#### Issue: "error: hash mismatch in fixed-output derivation"

**Symptoms:**
```bash
error: hash mismatch in fixed-output derivation '/nix/store/...'
  specified: sha256:0000000000000000000000000000000000000000000000000000
     got:    sha256:1234567890abcdef...
```

**Solutions:**

1. **Update flake locks**:
   ```bash
   nix flake update
   make build
   ```

2. **Update specific input**:
   ```bash
   nix flake lock --update-input nixpkgs
   make build
   ```

3. **Rebuild lock file completely**:
   ```bash
   rm flake.lock
   nix flake lock
   make build
   ```

#### Issue: Out of disk space during build

**Symptoms:**
```bash
error: cannot link '/nix/store/...' to '/nix/store/...': No space left on device
```

**Solutions:**

1. **Clean Nix store**:
   ```bash
   nix store gc
   nix store optimise
   ```

2. **Check disk usage**:
   ```bash
   df -h /nix
   du -sh ~/.nix-*
   ```

3. **Clean old generations** (NixOS):
   ```bash
   sudo nix-collect-garbage -d
   sudo nixos-rebuild switch --flake .
   ```

### Platform-Specific Build Issues

#### macOS: Homebrew Integration Problems

**Symptoms:**
```bash
error: Homebrew is not installed or not in PATH
```

**Solutions:**

1. **Check Homebrew installation**:
   ```bash
   which brew
   brew --version
   ```

2. **Reinstall Homebrew** if missing:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

3. **Rebuild with Homebrew integration**:
   ```bash
   sudo nix run --impure .#build-switch
   ```

#### Linux: Missing System Dependencies

**Symptoms:**
```bash
error: Package 'systemd' is not available
```

**Solutions:**

1. **Check NixOS vs regular Linux**:
   ```bash
   # If on NixOS
   sudo nixos-rebuild switch --flake .

   # If on regular Linux, some packages may not be available
   # Check modules/nixos/packages.nix for NixOS-specific packages
   ```

## 🧪 Testing Issues

### Test Framework Problems

#### Issue: "test-unit command not found" on Linux

**Symptoms:**
```bash
$ nix run .#test-unit
error: flake output attribute 'apps.x86_64-linux.test-unit' does not exist
```

**Explanation:**
Extended test apps (test-unit, test-integration, test-e2e, test-perf) are only available on Darwin systems.

**Solution:**
```bash
# On Linux systems, use basic tests
nix run .#test
nix run .#test-smoke
make test-status
```

#### Issue: Tests fail with permission errors

**Symptoms:**
```bash
error: cannot create directory '/nix/store/...': Permission denied
```

**Solutions:**

1. **Fix Nix store permissions**:
   ```bash
   sudo chown -R $(whoami) /nix
   sudo chmod -R 755 /nix
   ```

2. **Use multi-user installation**:
   ```bash
   # Reinstall Nix with multi-user support
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

### CI/CD Testing Issues

#### Issue: Tests pass locally but fail in CI

**Diagnostic steps:**

1. **Run exact CI commands locally**:
   ```bash
   ./scripts/test-all-local
   ```

2. **Check platform differences**:
   ```bash
   # Ensure testing on same platform as CI
   uname -m  # Check architecture
   uname -s  # Check OS
   ```

3. **Check environment variables**:
   ```bash
   # CI might have different environment
   env | grep -E "(USER|HOME|PATH)"
   ```

## 🔐 Permission Issues

### Sudo and Administrative Access

#### Issue: "build-switch requires sudo but fails"

**Symptoms:**
```bash
$ nix run .#build-switch
error: you do not have permission to perform this operation
```

**Solution:**
```bash
# build-switch must be run with sudo from the start
sudo nix run --impure .#build-switch

# Alternative: two-step process
nix run .#build
sudo nix run .#switch
```

#### Issue: "Permission denied" during switch

**Symptoms:**
```bash
$ make switch
Permission denied (publickey).
```

**Solutions:**

1. **Check SSH key setup**:
   ```bash
   nix run .#check-keys
   ssh-add -l
   ```

2. **Regenerate SSH keys if needed**:
   ```bash
   nix run .#create-keys
   nix run .#copy-keys
   ```

3. **Use HTTPS instead of SSH** for Git operations:
   ```bash
   git config --global url."https://github.com/".insteadOf git@github.com:
   ```

## 🔄 Update and Sync Issues

### Auto-Update Problems

#### Issue: Auto-update fails silently

**Diagnostic:**
```bash
# Run auto-update with verbose output
./scripts/auto-update-dotfiles --force

# Check for local changes that might prevent updates
git status
git diff
```

#### Issue: "TTL file prevents update"

**Symptoms:**
```bash
Auto-update skipped (TTL not expired)
```

**Solutions:**

1. **Force update**:
   ```bash
   ./scripts/auto-update-dotfiles --force
   ```

2. **Reset TTL**:
   ```bash
   rm -f ~/.cache/dotfiles-update-check
   ./scripts/auto-update-dotfiles
   ```

### Configuration Conflicts

#### Issue: Claude configuration merge conflicts

**Symptoms:**
```bash
Update notice: ~/.claude/settings.json.update-notice
```

**Solution:**
```bash
# List files needing attention
./scripts/merge-claude-config --list

# Interactively resolve conflicts
./scripts/merge-claude-config settings.json

# View differences before merging
./scripts/merge-claude-config --diff settings.json
```

## 🌐 Network Issues

### Download and Connectivity Problems

#### Issue: "unable to download" errors

**Symptoms:**
```bash
error: unable to download 'https://cache.nixos.org/...':
Couldn't resolve host name
```

**Solutions:**

1. **Check internet connectivity**:
   ```bash
   ping cache.nixos.org
   curl -I https://cache.nixos.org
   ```

2. **Configure proxy** if behind corporate firewall:
   ```bash
   export https_proxy=http://proxy.company.com:8080
   export http_proxy=http://proxy.company.com:8080
   ```

3. **Use different substituter**:
   ```bash
   nix build --substituters https://cache.nixos.org
   ```

#### Issue: GitHub rate limiting

**Symptoms:**
```bash
error: unable to download 'https://api.github.com/repos/...':
HTTP error 403: rate limit exceeded
```

**Solutions:**

1. **Configure GitHub token**:
   ```bash
   export GITHUB_TOKEN=your_token_here
   git config --global github.token your_token_here
   ```

2. **Wait and retry**:
   ```bash
   # GitHub rate limits reset hourly
   sleep 3600
   make build
   ```

## 🖥️ Platform-Specific Issues

### macOS Specific

#### Issue: "code signing" errors

**Symptoms:**
```bash
error: code signing failed for '/Applications/MyApp.app'
```

**Solutions:**

1. **Allow unsigned applications**:
   ```bash
   sudo spctl --master-disable
   # Run build/switch
   sudo spctl --master-enable
   ```

2. **Clear application quarantine**:
   ```bash
   sudo xattr -rd com.apple.quarantine /Applications/MyApp.app
   ```

#### Issue: Homebrew casks fail to install

**Symptoms:**
```bash
Error: Cask 'my-app' is not available
```

**Solutions:**

1. **Update Homebrew**:
   ```bash
   brew update
   sudo nix run --impure .#build-switch
   ```

2. **Check cask availability**:
   ```bash
   brew search my-app
   brew info my-app
   ```

### Linux Specific

#### Issue: systemd services fail to start

**Symptoms:**
```bash
Failed to start my-service.service
```

**Solutions:**

1. **Check service status**:
   ```bash
   systemctl status my-service
   journalctl -u my-service
   ```

2. **Reload systemd configuration**:
   ```bash
   sudo systemctl daemon-reload
   sudo nixos-rebuild switch --flake .
   ```

#### Issue: Graphics/desktop environment issues

**Solutions:**

1. **Rebuild with graphics support**:
   ```bash
   sudo nixos-rebuild switch --flake .
   sudo reboot
   ```

2. **Check X11/Wayland configuration**:
   ```bash
   echo $XDG_SESSION_TYPE
   echo $WAYLAND_DISPLAY
   ```

## 📝 Getting Additional Help

### Diagnostic Information to Collect

When seeking help, please provide:

```bash
# System information
uname -a
nix --version

# Flake information  
nix flake show --impure
git status
git log --oneline -5

# Environment
echo "USER: $USER"
echo "PATH: $PATH"
env | grep -E "(NIX|USER|HOME)"

# Error context
# Include full error messages and stack traces
```

### Resources

- **Nix Manual**: https://nixos.org/manual/nix/stable/
- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Home Manager Manual**: https://nix-community.github.io/home-manager/
- **nix-darwin Documentation**: https://github.com/LnL7/nix-darwin

### Support Channels

1. **Documentation**: Check all README files and docs/ directory
2. **GitHub Issues**: Search existing issues before creating new ones
3. **Nix Community**:
   - Matrix: #nix:nixos.org
   - Discord: Nix/NixOS Community
   - Discourse: https://discourse.nixos.org

---

> **Remember**: Most issues can be resolved by ensuring the USER environment variable is set and running with the `--impure` flag when needed.
