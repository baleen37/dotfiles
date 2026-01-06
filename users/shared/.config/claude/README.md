# Claude Code Configuration

This directory contains Claude Code commands, skills, and hooks for dotfiles development.

## Structure

```
.claude/
├── CLAUDE.md              # Project-specific instructions
├── settings.json          # Claude Code settings
├── statusline.sh          # Custom status line
│
├── commands/              # Slash commands (/, quick actions)
│   ├── commit-push-pr.md  # Commit, push, create PR
│   ├── create-*.md        # Creation helpers
│   ├── fix-ci.md          # CI troubleshooting
│   └── *.md               # Other commands
│
├── skills/                # Reusable workflows (Skill tool)
│   ├── creating-pull-requests/
│   │   └── SKILL.md       # Skill definition
│   ├── ci-troubleshooting/
│   ├── setup-precommit-and-ci/
│   └── */
│
├── hooks/                 # Lifecycle hooks
│   └── git-command-validator.sh
│
├── agents/                # Custom agent prompts
│   └── code-reviewer.md
│
└── handoffs/              # Session handoff context
```

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
