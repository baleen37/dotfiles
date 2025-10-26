# Reference: Configuring Claude Code with Nix

Detailed examples and troubleshooting for the Nix Claude Config skill.

## Configuration File Structure

```text
users/baleen/
├── programs/claude.nix      # Home Manager module for Claude
└── programs/claude/         # Claude configuration source
    ├── settings.json        # Claude Code settings (via Nix store)
    ├── CLAUDE.md           # Project instructions (direct source link)
    ├── commands/           # Custom slash commands
    ├── agents/             # AI agent configurations
    ├── hooks/              # Git hooks (Go binaries)
    └── skills/             # Agent skills
```

## Complete Module Example

```nix
{ pkgs, config, ... }:

let
  dotfilesRoot = config.home.sessionVariables.DOTFILES_ROOT
    or "${config.home.homeDirectory}/dotfiles";

  claudeConfigDirSource = "${dotfilesRoot}/users/baleen/programs/claude";
  claudeHomeDir = ".claude";
in
{
  home.file = {
    # Immutable via Nix store (copied from source)
    "${claudeHomeDir}/settings.json" = {
      source = "${claudeConfigDirSource}/settings.json";
      onChange = ''echo "Claude settings.json updated"'';
    };

    # Mutable via direct source link
    "${claudeHomeDir}/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink
        "${claudeConfigDirSource}/CLAUDE.md";
    };

    # Directories (symlinked for immediate updates)
    "${claudeHomeDir}/commands".source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/commands";
    "${claudeHomeDir}/agents".source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/agents";
    "${claudeHomeDir}/skills".source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/skills";
  };
}
```

## Detailed Examples

### Adding Settings

```bash
# Edit settings
vim users/baleen/programs/claude/settings.json

# Example change
{
  "modelId": "claude-sonnet-4-5-20250929",
  "contextWindow": 200000,
  "newFeature": true
}

# Apply
make switch-user

# Verify (should see "Claude settings.json updated")
```

### Adding Custom Commands

```bash
# Create command
cat > users/baleen/programs/claude/commands/my-command.md <<'EOF'
You are a specialized assistant for...
EOF

# Apply
make switch-user

# Verify
ls -la ~/.claude/commands/my-command.md
```

### Adding Agent Configurations

```bash
# Create agent
cat > users/baleen/programs/claude/agents/my-agent.md <<'EOF'
# My Agent Configuration

[Agent instructions here]
EOF

# Apply
make switch-user

# Verify
ls -la ~/.claude/agents/my-agent.md
```

### Adding Skills

```bash
# 1. Create skill directory
mkdir -p users/baleen/programs/claude/skills/my-skill

# 2. Create SKILL.md
cat > users/baleen/programs/claude/skills/my-skill/SKILL.md <<'EOF'
---
name: My Custom Skill
description: Performs specific task in specific context
---

# Skill instructions here
EOF

# 3. Apply
make switch-user

# 4. Verify
ls -la ~/.claude/skills/my-skill/SKILL.md
cat ~/.claude/skills/my-skill/SKILL.md
```

### Editing CLAUDE.md Without Rebuild

```bash
# Edit directly (no rebuild needed!)
vim users/baleen/programs/claude/CLAUDE.md

# Changes are immediately visible
cat ~/.claude/CLAUDE.md
```

## Troubleshooting Details

### Symlinks Not Updating

**Problem**: Changes not reflected in `~/.claude/`

**Solution**:

```bash
# Rebuild Home Manager
make switch-user

# Or force rebuild with trace
home-manager switch --flake . --show-trace

# Verify symlinks
ls -la ~/.claude/
```

### DOTFILES_ROOT Not Set

**Problem**: Direct source links not working

**Solution 1** (Shell config):

```bash
# Add to ~/.zshrc or ~/.bashrc
export DOTFILES_ROOT="$HOME/dotfiles"

# Reload
source ~/.zshrc
```

**Solution 2** (Nix config):

```nix
# In Home Manager configuration
home.sessionVariables = {
  DOTFILES_ROOT = "${config.home.homeDirectory}/dotfiles";
};
```

### File Not Appearing in ~/.claude/

**Diagnostic steps**:

1. Check file exists in source:

   ```bash
   ls -la users/baleen/programs/claude/
   ```

2. Verify symlink configuration in claude.nix:

   ```bash
   cat users/baleen/programs/claude.nix
   ```

3. Check for Nix errors:

   ```bash
   make build-current
   ```

4. Rebuild with detailed trace:

   ```bash
   home-manager switch --flake . --show-trace
   ```

5. Verify target:

   ```bash
   ls -la ~/.claude/
   readlink ~/.claude/yourfile
   ```

### Permission Issues

**Problem**: Cannot write to symlinked files

**Explanation**: Files symlinked from Nix store are read-only by design.

**Solution**:

- For read-only files: Expected behavior (settings.json, commands/, etc.)
- For mutable files: Use `mkOutOfStoreSymlink` (like CLAUDE.md)

### Nix Store Path Changes

**Problem**: Symlinks point to old Nix store paths after rebuild

**Solution**: This is normal. Home Manager updates symlinks automatically:

```bash
# Before rebuild
~/.claude/settings.json -> /nix/store/abc123.../settings.json

# After rebuild
~/.claude/settings.json -> /nix/store/xyz789.../settings.json
```

No action needed - Home Manager handles this.

## Advanced Patterns

### Conditional Configuration

```nix
# Platform-specific settings
home.file."${claudeHomeDir}/settings.json" = {
  source = if pkgs.stdenv.isDarwin
    then "${claudeConfigDirNix}/settings-darwin.json"
    else "${claudeConfigDirNix}/settings-linux.json";
};
```

### Dynamic Content Generation

```nix
# Generate configuration programmatically
home.file."${claudeHomeDir}/generated.json".text = builtins.toJSON {
  user = config.home.username;
  platform = pkgs.stdenv.system;
};
```

### Combining Nix Store and Source Links

```nix
# Mix immutable and mutable files
home.file = {
  # Immutable settings
  "${claudeHomeDir}/settings.json".source = "${claudeConfigDirNix}/settings.json";

  # Mutable documentation
  "${claudeHomeDir}/README.md".source =
    config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/README.md";
};
```

## Testing Workflow

```bash
# 1. Make changes
vim users/baleen/programs/claude/settings.json

# 2. Test build (dry-run)
export USER=$(whoami)
make build-current

# 3. Apply changes
make switch-user

# 4. Verify
ls -la ~/.claude/
cat ~/.claude/settings.json

# 5. Test in Claude Code
# Open Claude Code and verify changes
```

## File Permissions Reference

| File/Directory | Permission | Reason                        |
| -------------- | ---------- | ----------------------------- |
| settings.json  | Read-only  | Nix store                     |
| hooks/         | Executable | Built Go binaries (Nix store) |
| CLAUDE.md      | Read-write | Direct source link            |
| commands/      | Read-write | Direct source link            |
| agents/        | Read-write | Direct source link            |
| skills/        | Read-write | Direct source link            |

## Related Files

- `users/baleen/programs/claude.nix` - Main Home Manager module
- `users/baleen/programs/claude/` - Configuration source directory
- `tests/unit/modules/claude-test.nix` - Unit tests for module
- `tests/e2e/claude-hooks-test.nix` - E2E tests for hooks
