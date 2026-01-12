# Claude Code Configuration

This directory contains Claude Code commands, skills, and hooks for dotfiles development.

## Structure

```
.claude/
├── CLAUDE.md              # Project-specific instructions
├── settings.json          # Claude Code settings (writable after initial setup)
├── statusline.sh          # Custom status line
├── README.md              # This file
│
├── handoffs/              # Session handoff context
│   └── *.md               # Handoff notes for session continuity
│
└── [future extensions]
    ├── commands/          # Slash commands (/, quick actions)
    ├── skills/            # Reusable workflows (Skill tool)
    ├── hooks/             # Lifecycle hooks
    └── agents/            # Custom agent prompts
```

**Note**: Commands, skills, hooks, and agents are currently managed via external plugin:
https://github.com/baleen37/claude-plugins

Local commands can be added by creating the `commands/` directory and `.md` files.

## Commands vs Skills

**Commands** (`/command-name`): Quick, single-purpose actions
- Fast execution, minimal context
- Use for: commits, PRs, simple workflows
- Example: `/commit-push-pr`

**Skills** (invoked via Skill tool): Complex, multi-step workflows
- Enforced methodology, review checkpoints
- Use for: CI troubleshooting, PR creation, debugging
- Example: `creating-pull-requests`

## Conventions

- **Command names**: kebab-case (`commit-push-pr.md`)
- **Skill names**: kebab-case directory (`creating-pull-requests/`)
- **Skill files**: Always `SKILL.md` (not `skill.md` or name-based)
- **Descriptions**: Start with verb, specify when to use

## Best Practices

1. **Keep commands simple** - Complex workflows → skills
2. **One purpose per command** - Don't combine unrelated actions
3. **Skills enforce process** - Use TDD, debugging, etc.
4. **Document intent** - When to use, what it does
5. **Test locally** - Verify before committing
