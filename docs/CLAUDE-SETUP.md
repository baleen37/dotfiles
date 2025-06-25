# Claude Code Setup Guide

> **Complete setup and integration guide for Claude Code with Nix dotfiles**

This guide walks you through setting up Claude Code to work seamlessly with this Nix-based dotfiles repository, unlocking powerful AI-assisted development workflows.

## 🎯 What You Get

After following this guide, you'll have:
- **Fully configured Claude Code** with dotfiles-aware commands
- **20+ specialized prompts** for common development tasks
- **Smart configuration preservation** that survives system updates
- **Context-aware AI assistance** for Nix, Git, and development workflows

## 📋 Prerequisites

### Required
- **Claude Code installed** - Get it from [claude.ai/code](https://claude.ai/code)
- **This dotfiles repository** - Already set up and working
- **Node.js 18+** - For MCP (Model Context Protocol) servers

### Check Prerequisites
```bash
# Verify Node.js version
node --version  # Should be 18.0.0 or higher

# Verify dotfiles are working
make build

# Verify Claude Code is installed
claude --version  # or check if Claude Code app is running
```

## ⚡ Quick Setup (5 minutes)

### Step 1: Apply Claude Configuration
```bash
# Apply dotfiles to get Claude configuration
export USER=$(whoami)
make switch

# Verify Claude config was applied
ls ~/.claude/
# Should show: settings.json, CLAUDE.md, commands/
```

### Step 2: Restart Claude Code
1. **Close Claude Code completely** (quit the application)
2. **Reopen Claude Code**
3. Claude will automatically discover the new configuration

### Step 3: Verify Integration
Open Claude Code and try these commands:
```
/help           # Should show custom commands
/build          # Should understand this repository
/do-plan        # Should be available for project planning
```

## 🔧 Detailed Configuration

### Settings Overview
The dotfiles automatically configure Claude Code with:

```json
{
  "mcpServers": {
    "context7": "Library documentation lookup",
    "sequential-thinking": "Enhanced reasoning capabilities"
  },
  "model": "sonnet",
  "permissions": {
    "allow": ["nix:*", "git:*", "gh:*", "make:*", ...]
  }
}
```

### MCP Servers Setup
The configuration includes two powerful MCP servers:

**Context7** - Library Documentation
- Provides up-to-date documentation for popular libraries
- Usage: Claude can automatically look up API docs, examples, etc.

**Sequential Thinking** - Enhanced Reasoning
- Enables more structured problem-solving
- Useful for complex debugging and architecture decisions

### Permissions Configuration
Pre-configured permissions for common development tools:
- **Nix commands**: `nix build`, `nix run`, `nix develop`, etc.
- **Git operations**: Full Git command access
- **GitHub CLI**: `gh pr create`, `gh issue list`, etc.
- **Build tools**: `make`, `npm`, `yarn`, `poetry`, etc.
- **System utilities**: File operations, process management

## 🚀 Available Commands

### Project Management
- `/do-plan` - Create detailed implementation plans
- `/do-issue` - Work on GitHub issues systematically  
- `/do-todo` - Execute todo items from todo.md
- `/make-github-issue` - Create well-structured GitHub issues

### Development Workflow
- `/build` - Build and test the dotfiles configuration
- `/commit` - Create semantic commit messages
- `/create-pr` - Generate comprehensive pull requests
- `/checkout` - Smart branch switching and management

### Code Quality
- `/plan-tdd` - Plan test-driven development approach
- `/brainstorm` - Explore solutions and approaches
- `/session-summary` - Summarize development sessions

### Git & Collaboration
- `/check-pr` - Review pull requests systematically
- `/fix-github-issues` - Address multiple issues efficiently
- `/create-worktree` - Manage Git worktrees for parallel development
- `/cleanup-worktree` - Clean up abandoned worktrees

### Documentation
- `/update-docs` - Maintain and update documentation
- `/update-command` - Modify Claude command prompts
- `/prompt` - Design effective AI prompts

[View all commands →](./CLAUDE-COMMANDS.md)

## 🔄 Daily Workflow Examples

### Starting a New Feature
```
User: I want to add dark mode support to the terminal configuration

Claude: I'll help you implement dark mode support. Let me use /do-plan to create a structured approach.

/do-plan

Based on your dotfiles repository, here's a comprehensive plan for adding dark mode support...
```

### Working on GitHub Issues
```
User: Work on issue #180

Claude: I'll systematically work on issue #180. Let me use /do-issue to understand the requirements and create an implementation plan.

/do-issue 180

I've analyzed issue #180: "Update documentation for Claude Code integration"...
```

### Building and Testing Changes
```
User: Test my latest changes

Claude: I'll build and test your changes using the dotfiles build system.

/build

Running comprehensive build and test process...
```

## 🛡️ Configuration Preservation

The dotfiles include a **Smart Configuration Preservation System** that protects your customizations:

### How It Works
1. **Automatic Detection** - Detects when you've modified Claude settings
2. **Safe Updates** - Preserves your changes during dotfiles updates
3. **Interactive Merging** - Helps resolve configuration conflicts
4. **Automatic Backups** - Creates timestamped backups of all changes

### Managing Updates
When dotfiles updates include new Claude settings:

```bash
# Check for pending updates
ls ~/.claude/*.new

# Merge configuration changes
./scripts/merge-claude-config

# Review what changed
./scripts/merge-claude-config --diff settings.json
```

## 🔧 Customization

### Adding Custom Commands
1. Create new command file:
```bash
# Create custom command
cat > ~/.claude/commands/my-command.md << 'EOF'
# My Custom Command

Brief description of what this command does.

## Usage
Explain how to use the command...
EOF
```

2. Restart Claude Code to load the new command

### Modifying Permissions
Edit `~/.claude/settings.json` to adjust permissions:
```json
{
  "permissions": {
    "allow": [
      "Bash(my-custom-tool:*)"
    ]
  }
}
```

### Customizing MCP Servers
Add additional MCP servers in `settings.json`:
```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@my/mcp-server"]
    }
  }
}
```

## 🚨 Troubleshooting

### Claude Code Not Finding Configuration
**Problem**: Claude Code doesn't show custom commands

**Solutions**:
```bash
# Verify configuration exists
ls ~/.claude/
# Should show: settings.json, CLAUDE.md, commands/

# Check file permissions
ls -la ~/.claude/
# All files should be readable

# Restart Claude Code completely
# Quit application and reopen
```

### MCP Server Connection Issues
**Problem**: Context7 or sequential-thinking servers not working

**Solutions**:
```bash
# Check Node.js version
node --version  # Must be 18.0.0+

# Test MCP server installation
npx -y @upstash/context7-mcp --version

# Clear npm cache if needed
npm cache clean --force
```

### Permission Denied Errors
**Problem**: Claude Code can't execute certain commands

**Solutions**:
```bash
# Check settings.json permissions section
cat ~/.claude/settings.json | jq '.permissions.allow'

# Add missing permissions to settings.json
# Restart Claude Code after changes
```

### Configuration Conflicts During Updates
**Problem**: Settings lost after dotfiles update

**Solutions**:
```bash
# Use merge tool to resolve conflicts
./scripts/merge-claude-config

# Check for backup files
ls ~/.claude/.backups/

# Restore from backup if needed
cp ~/.claude/.backups/settings.json.backup.* ~/.claude/settings.json
```

### Command Not Working as Expected
**Problem**: Custom command behaves differently than expected

**Solutions**:
```bash
# Check command file syntax
cat ~/.claude/commands/problematic-command.md

# Verify command follows prompt engineering best practices
# See docs/CLAUDE-COMMANDS.md for examples

# Test with simpler version first
# Gradually add complexity
```

## 📚 Next Steps

1. **Learn the Commands** - Explore [CLAUDE-COMMANDS.md](./CLAUDE-COMMANDS.md) for detailed command reference
2. **Try Example Workflows** - See [DEVELOPMENT-SCENARIOS.md](./DEVELOPMENT-SCENARIOS.md) for practical examples
3. **Customize Your Setup** - Add your own commands and adjust permissions
4. **Join the Community** - Share your Claude Code configurations and workflows

## 🎯 Quick Reference

### Essential Commands
| Command | Purpose | Usage |
|---------|---------|-------|
| `/build` | Build and test dotfiles | When making configuration changes |
| `/do-plan` | Create implementation plans | Starting new features or complex tasks |
| `/commit` | Generate commit messages | After making code changes |
| `/create-pr` | Create pull requests | When ready to merge changes |
| `/do-issue` | Work on GitHub issues | Systematic issue resolution |

### Key Files
| File | Purpose | When to Edit |
|------|---------|-------------|
| `~/.claude/settings.json` | Core configuration | Adding permissions/servers |
| `~/.claude/commands/*.md` | Custom commands | Creating new workflows |
| `~/.claude/CLAUDE.md` | Project instructions | Repository-specific guidance |

### Useful Scripts
| Script | Purpose | When to Use |
|--------|---------|-------------|
| `./scripts/merge-claude-config` | Resolve config conflicts | After dotfiles updates |
| `make switch` | Apply dotfiles configuration | Setting up Claude integration |
| `make build` | Test configuration changes | Before committing changes |

---

> **💡 Pro Tip**: Start with the `/build` and `/do-plan` commands to get familiar with the integration, then gradually explore more specialized commands as you develop your workflow.