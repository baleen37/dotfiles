# Claude Code Skills

This directory contains reusable workflow skills that enforce best practices.

## Structure

Each skill is a self-contained directory with `SKILL.md`:

```
skills/
├── SKILL.md                    # Skill definition (mandatory)
├── scripts/                    # Bash/shell scripts (optional)
│   └── *.sh                    # Executable helper scripts
├── templates/                  # Template files (optional)
│   └── *.{md,nix,yaml}         # Reusable templates
└── tools/                      # Node.js / other tools (optional)
    └── *.js                    # Tool scripts
```

## Naming Conventions

- **Directory**: `kebab-case` (e.g., `creating-pull-requests`)
- **Skill file**: `SKILL.md` (always uppercase, not skill.md)
- **Scripts**: `kebab-case.sh` (e.g., `pr-check.sh`)

## Available Skills

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `creating-pull-requests` | PR creation with --base, Conventional Commits | Creating/updating PRs |
| `ci-troubleshooting` | Systematic CI debugging | CI failures |
| `setup-precommit-and-ci` | Pre-commit hooks & CI setup | New project setup |
| `nix-direnv-setup` | Direnv for Nix flakes | Nix flake projects |
| `using-git-worktrees` | Isolated branch work | Feature development |
| `video-debugging` | Video playback issues | Media debugging |
| `web-browser` | Browser automation | Web interaction |
| `writing-claude-commands` | Creating Claude Code commands | Adding /commands |

## Skill Anatomy

A well-structured skill:

```markdown
---
name: skill-name
description: Use when... - clear trigger condition
---

# Skill Name

## Overview
Brief description of what the skill does.

## When to Use
Clear criteria for when this skill applies.

## Implementation
Step-by-step instructions for the workflow.

## Examples
Concrete usage examples.
```

## Best Practices

1. **One skill, one purpose** - Don't combine unrelated workflows
2. **Clear trigger conditions** - "Use when X happens"
3. **Enforced methodology** - Skills should guide, not just inform
4. **Idempotent** - Can be run multiple times safely
5. **Self-documenting** - SKILL.md is the single source of truth

## Creating New Skills

1. Create directory: `mkdir skills/your-skill`
2. Create `SKILL.md` with proper frontmatter
3. Add optional `scripts/`, `templates/`, or `tools/`
4. Test locally before committing
5. Document in this README

See `writing-claude-commands` skill for detailed guidance.
