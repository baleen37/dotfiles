# Claude Code Configuration

This directory contains Claude Code configuration managed via Nix/Home Manager.

## Initial Setup

### Plugin Installation (One-time)

After initial setup or when adding new plugins, run the following commands once:

```bash
# Add marketplaces
claude plugin marketplace add obra/superpowers-marketplace
claude plugin marketplace add anthropics/claude-plugins-official

# Install plugins
claude plugin install superpowers@superpowers-marketplace
claude plugin install episodic-memory@superpowers-marketplace
claude plugin install typescript-lsp@claude-plugins-official
claude plugin install pyright-lsp@claude-plugins-official
claude plugin install gopls-lsp@claude-plugins-official
```

### How It Works

- **Plugin Installation**: Done manually once (commands above). Plugins persist in `~/.claude/plugins/`
- **Plugin Configuration**: Managed declaratively via `settings.json` in this repository
- **Other Config Files**: Commands, agents, skills, and hooks are symlinked from this directory

After running `home-manager switch`, only the `settings.json` and symlinks are updated. You don't need to reinstall plugins unless you want to update them or add new ones.

## Structure

```
.config/claude/
├── README.md           # This file
├── settings.json       # Main configuration (copied to ~/.claude/)
├── statusline.sh       # Status line script
├── CLAUDE.md          # Project-specific instructions
├── commands/          # Slash commands
├── agents/            # Custom agents
├── skills/            # Custom skills
└── hooks/             # Git and tool hooks
```
