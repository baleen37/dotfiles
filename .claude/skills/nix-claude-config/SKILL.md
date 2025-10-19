---
name: Configuring Claude Code with Nix
description: Manages Claude Code settings, commands, agents, and skills in Nix dotfiles using Home Manager symlinks. Use when adding/modifying Claude configuration in a Nix-based system.
allowed-tools: [Read, Edit, Write, Bash, Glob, Grep]
---

# Configuring Claude Code with Nix

Manages Claude Code configuration in Nix dotfiles through Home Manager symlinks from `modules/shared/config/claude/` to `~/.claude/`.

## Configuration Paths

**Source**: `modules/shared/config/claude/` (settings.json, CLAUDE.md, commands/, agents/, skills/, hooks/)
**Module**: `modules/shared/programs/claude/default.nix` (symlink configuration)
**Target**: `~/.claude/` (Claude Code reads from here)

## Symlink Strategy

**Nix Store** (immutable, requires rebuild):

- settings.json, hooks/ (built Go binaries)

**Direct Source Link** (mutable, instant updates):

- CLAUDE.md, commands/, agents/, skills/ (via `mkOutOfStoreSymlink`)

## Standard Workflow

### Instant Updates (No Rebuild)

Edit directly in `modules/shared/config/claude/`:

- CLAUDE.md, commands/, agents/, skills/

Changes appear immediately via direct source symlinks.

### Rebuild Required

Edit and run `make switch-user`:

- settings.json (Nix store for immutability)
- hooks/ (compiled Go binaries)

## Direct Source Linking

Files with instant updates use `mkOutOfStoreSymlink`:

```nix
dotfilesRoot = self.outPath;  # Flake's actual location
claudeConfigDirSource = "${dotfilesRoot}/modules/shared/config/claude";

"${claudeHomeDir}/file" = {
  source = config.lib.file.mkOutOfStoreSymlink "${claudeConfigDirSource}/file";
};
```

Uses `self.outPath` for automatic path resolution.

## Quick Tasks

**Add new command**: Create `.md` file in `commands/` - instant update

**Add new agent**: Create `.md` file in `agents/` - instant update

**Add new skill**: Create `SKILL.md` in `skills/yourskill/` - instant update

**Update settings**: Edit `settings.json` → `make switch-user`

**Update hooks**: Modify Go source → `make switch-user` (recompiles)

## Common Issues

**Symlinks not updating**: Run `make switch-user`

**File not appearing**: Verify file exists in source, rebuild with `make build-current --show-trace`

**Path issues**: Module uses `self.outPath` for automatic flake location

See [reference.md](reference.md) for detailed examples and troubleshooting.
