---
description: Setup Nix develop environment with direnv integration following best practices
---

The user input can be provided directly by the agent or as a command argument - you **MUST** consider it before proceeding with the prompt (if not empty).

User input:

$ARGUMENTS

## Purpose

Automate Nix development environment setup with:

- Nix flake initialization with devShells
- direnv integration with nix-direnv
- Best practices configuration (2025 standards)
- Editor integration recommendations

## Usage

```bash
/setup-nix [optional: project-path or configuration-type]
```

**Examples:**

```bash
/setup-nix                    # Setup in current directory
/setup-nix ./my-project       # Setup in specific directory
/setup-nix minimal            # Minimal configuration
/setup-nix full               # Full configuration with recommendations
```

## Process Flow

### 1. Environment Analysis

- Check current directory for existing Nix configuration
- Verify `flake.nix` existence and structure
- Check `.envrc` presence and content
- Validate direnv installation status
- Verify nix-direnv installation (recommended)
- Identify project type (if possible) for tailored configuration

### 2. Nix Flake Setup

**If flake.nix doesn't exist:**

- Create minimal flake.nix with devShells for supported systems
- Include common development dependencies:
  - Build tools (gcc, make, etc.)
  - Version control (git)
  - Shell utilities (bash, coreutils)
- Use latest nixpkgs input
- Add basic flake metadata (description, outputs)

**If flake.nix exists:**

- Analyze existing structure
- Check for devShells configuration
- If devShells missing, propose addition
- Respect existing configuration patterns
- **NEVER overwrite without explicit permission**

**Minimal devShells template:**

```nix
{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # Add your development dependencies here
          ];

          shellHook = ''
            echo "Development environment loaded"
          '';
        };
      }
    );
}
```

### 3. direnv Configuration

**Create or update `.envrc`:**

Basic configuration:

```bash
use flake
```

Advanced configuration (with nix-direnv):

```bash
# Use nix-direnv for better caching and performance
if ! has nix_direnv_version || ! nix_direnv_version 2.3.0; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.3.0/direnvrc" "sha256-Dmd+j63L84wuzgyjITIfSxSD57Tx7v51DMxVZOsiUD8="  # pragma: allowlist secret
fi

use flake

# Optional: Load .env file if present
dotenv_if_exists
```

Manual reload mode (for slower builds):

```bash
use flake --pure --no-reload
```

**Key direnv behaviors:**

- Auto-reload on flake.nix changes
- GC root management via nix-direnv (prevents re-downloads)
- Environment activation on directory entry
- Automatic cleanup on directory exit

### 4. Integration & Validation

**Execute setup:**

1. Run `direnv allow` to authorize .envrc
2. Test environment activation: `nix develop`
3. Verify packages available in shell
4. Check direnv status: `direnv status`

**Provide recommendations:**

- **nix-direnv installation** (if not present):

  ```nix
  # Add to your system configuration or home-manager
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  ```

- **Starship integration** (visual environment indication):

  ```toml
  # Add to ~/.config/starship.toml
  [nix_shell]
  disabled = false
  format = 'via [$symbol$state]($style) '
  ```

- **VSCode direnv extension**: `mkhl.direnv`
- **Doom Emacs module**: `:tools direnv`

## Key Behaviors

**Non-Destructive Updates**

- Always check existing configurations before modifying
- Request permission before overwriting files
- Preserve custom user configurations
- Create backups of modified files

**Smart Detection**

- Auto-detect project language/framework when possible
- Suggest relevant packages based on project type
- Identify common development patterns
- Adapt configuration to project needs

**Best Practices Enforcement**

- Use nix-direnv by default (faster, persistent)
- Enable GC root management (prevent dependency re-downloads)
- Configure proper file watching
- Set appropriate cache policies

**Safety Checks**

- Validate flake.nix syntax before committing
- Test direnv activation before finalizing
- Verify no sensitive data in .envrc
- Warn about remote flake security considerations

## Best Practices (2025 Standards)

### nix-direnv Benefits

**Persistent Environment Caching**

- Symlinks shell derivation to user's gcroots
- Prevents garbage collection of build dependencies
- Eliminates re-evaluation when flake.nix unchanged
- Near-instant environment activation (no startup time)

**Smart Re-evaluation**

- Only re-evaluates on actual file changes
- Watches flake.nix, flake.lock, and imported files
- Fallback to previous working environment if new version fails
- Manual reload mode for time-consuming rebuilds

### Performance Optimization

**Cache Management**

- nix-direnv maintains persistent cache
- Use `direnv reload` to force refresh
- Configure cache expiration policies
- Monitor cache size with `du -sh ~/.local/share/direnv`

**Build Optimization**

- Use `--option builders-use-substitutes true` for faster builds
- Enable `--max-jobs auto` for parallel builds
- Configure binary caches in nix.conf
- Use `--option eval-cache true` for faster evaluation

### Security Considerations

**Remote Flakes**

When using remote flakes (e.g., `github:org/repo`):

- **Arbitrary code execution risk**: shellHook allows any command
- **Package injection**: Packages can include malicious binaries
- **Mitigation**: Always examine flake contents before `direnv allow`
- Use locked flake references: `github:org/repo/commit-hash`

**Local .envrc**

- Never commit secrets to .envrc
- Use `dotenv_if_exists` for optional .env files
- Add .env to .gitignore
- Consider using secrets management tools (sops-nix, agenix)

### Editor Integration

**VSCode**

- Install `mkhl.direnv` extension
- Auto-activates environment in integrated terminal
- Updates PATH and environment variables
- Restarts language servers with new environment

**Emacs (Doom)**

```elisp
;; Add to init.el or packages.el
(package! direnv)

;; Add to config.el
(use-package! direnv
  :config
  (direnv-mode))
```

**Vim/Neovim**

```lua
-- Using lazy.nvim
{
  'direnv/direnv.vim',
  lazy = false,
}
```

### Monitoring & Debugging

**Check direnv status:**

```bash
direnv status          # Show current state
direnv reload          # Force environment refresh
direnv exec . env      # Show environment variables
```

**Debug nix-direnv:**

```bash
# Enable debug logging
export DIRENV_LOG_FORMAT="$(date +%Y-%m-%d\ %H:%M:%S) %s"
direnv reload
```

**Profile environment load time:**

```bash
time direnv reload
```

## Configuration Options

### Basic .envrc

```bash
# Simplest setup - just use flake
use flake
```

### Advanced .envrc

```bash
# Use nix-direnv for performance
if ! has nix_direnv_version || ! nix_direnv_version 2.3.0; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.3.0/direnvrc" "sha256-Dmd+j63L84wuzgyjITIfSxSD57Tx7v51DMxVZOsiUD8="  # pragma: allowlist secret
fi

# Use flake with specific output
use flake .#devShells.x86_64-linux.default

# Load environment variables
dotenv_if_exists

# Custom environment setup
export PROJECT_ROOT=$PWD
export DATA_DIR=$PWD/data
```

### Manual Reload Mode

```bash
# Prevent automatic reloads (useful for slow builds)
use flake --no-reload

# Reload manually with:
# direnv reload
```

### Multiple Environments

```bash
# Use different dev shells based on environment
if [ "$ENV" = "production" ]; then
  use flake .#prodShell
else
  use flake .#devShell
fi
```

### Language-Specific Configurations

**Python Project:**

```bash
use flake
layout python python3.11  # Activate virtualenv
```

**Node.js Project:**

```bash
use flake
layout node  # Setup node_modules PATH
```

**Rust Project:**

```bash
use flake
watch_file Cargo.toml Cargo.lock  # Reload on dependency changes
```

## Deliverables

After successful execution, the project will have:

**Files Created/Updated:**

- `flake.nix` - Nix flake with devShells configuration
- `.envrc` - direnv configuration with `use flake`
- `.gitignore` - Updated to exclude direnv artifacts (`.direnv/`, `.envrc.local`)

**Environment Activated:**

- Development shell loaded automatically on directory entry
- All specified packages available in PATH
- Environment variables set according to shellHook
- GC root registered (if using nix-direnv)

**Documentation Provided:**

- Summary of installed packages
- Instructions for adding more dependencies
- Editor integration recommendations
- Troubleshooting guide for common issues

**Validation Results:**

- ✅ flake.nix evaluates successfully
- ✅ direnv loads without errors
- ✅ nix develop command works
- ✅ Packages accessible in environment

## Troubleshooting

### direnv: error .envrc is blocked

**Solution:**

```bash
direnv allow
```

### nix-direnv not found

**Solution (Home Manager):**

```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;
};
```

**Solution (Manual):**

```bash
nix profile install nixpkgs#nix-direnv
```

### Environment not reloading on changes

**Cause:** nix-direnv cache not invalidated

**Solution:**

```bash
direnv reload  # Force reload
# OR
touch .envrc   # Trigger reload
```

### Slow direnv activation

**Check if nix-direnv is active:**

```bash
direnv status | grep nix-direnv
```

**If not, add to .envrc:**

```bash
if ! has nix_direnv_version || ! nix_direnv_version 2.3.0; then
  source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/2.3.0/direnvrc" "sha256-Dmd+j63L84wuzgyjITIfSxSD57Tx7v51DMxVZOsiUD8="  # pragma: allowlist secret
fi
```

### Dependencies garbage collected

**Symptom:** Need to re-download packages frequently

**Cause:** nix-direnv not managing GC roots

**Solution:** Ensure nix-direnv is properly installed and active

### flake.nix evaluation fails

**Debug:**

```bash
nix flake check          # Validate flake
nix flake show           # Show flake outputs
nix develop --show-trace # Show detailed error
```

### VSCode not picking up environment

**Solutions:**

1. Reload VSCode window: `Cmd+Shift+P` → "Reload Window"
2. Check direnv extension is installed and enabled
3. Verify `.envrc` is allowed: `direnv status`
4. Restart VSCode from terminal inside project directory

## Additional Resources

**Official Documentation:**

- [nix.dev - Automatic environment activation with direnv](https://nix.dev/guides/recipes/direnv.html)
- [nix-community/nix-direnv GitHub](https://github.com/nix-community/nix-direnv)
- [direnv - Official Site](https://direnv.net/)

**Best Practice Guides:**

- [Determinate Systems - Effortless dev environments with Nix and direnv](https://determinate.systems/blog/nix-direnv/)
- [Ian Henry - nix-direnv is a huge quality of life improvement](https://ianthehenry.com/posts/how-to-learn-nix/nix-direnv/)

**Security:**

- Always review remote flake contents before use
- Use commit hashes for flake inputs (not branches)
- Never commit secrets to .envrc or flake.nix
- Consider using secrets management (sops-nix, agenix)
