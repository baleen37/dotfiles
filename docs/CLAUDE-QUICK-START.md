# Claude Code Quick Start Guide

> **Get up and running with Claude Code + Nix dotfiles in 5 minutes**

## ⚡ Super Quick Setup

### Prerequisites Check (30 seconds)

```bash
# Verify you have the essentials
claude --version    # Should show Claude Code version
node --version      # Should be 18.0.0+
whoami             # Note your username
```

### One-Command Setup (60 seconds)

```bash
# Set user and build/switch in one go
export USER=$(whoami) && make build-switch
```

**That's it!** 🎉 Claude is now configured with 20+ specialized commands.

## 🧪 Test Your Setup (30 seconds)

```bash
# Test basic functionality
claude /help

# Test advanced features  
claude /analyze "our testing system"
claude /spawn "quick documentation update"

# Verify configuration
ls -la ~/.claude/commands/ | head -5
```

## 🎯 Essential Commands to Try First

### For Development Work

```bash
claude /task "review our build performance"
claude /analyze "current test coverage"  
claude /debug "why is the build slow?"
```

### For Planning & Organization

```bash
claude /spawn "implement new feature X"
claude /brainstorm "how to improve our CI pipeline"
claude /estimate "time to add authentication"
```

### For Code Quality

```bash
claude /improve "refactor this component"
claude /test "add comprehensive test coverage"
claude /document "update API documentation"
```

## 🔧 Common First-Time Issues & Solutions

### Issue: "Commands not found"

```bash
# Solution: Rebuild symlinks
make build-switch
ls ~/.claude/commands/  # Should show 20+ .md files
```

### Issue: "Permission denied"

```bash
# Solution: Set USER variable
export USER=$(whoami)
make build-switch
```

### Issue: "Symlinks broken"

```bash  
# Solution: Check dotfiles path
pwd  # Should be in your dotfiles directory
nix run .#build-switch
```

## 📚 Next Steps

### Explore Available Commands

```bash
# See all available commands
ls ~/.claude/commands/

# Read a specific command
cat ~/.claude/commands/analyze.md
```

### Customize for Your Workflow

```bash
# Edit commands directly (changes are instant via symlinks!)
editor modules/shared/config/claude/commands/task.md

# Add your own commands
echo "Your custom prompt here" > modules/shared/config/claude/commands/my-command.md
claude /my-command  # Available immediately
```

### Learn the Advanced Features

- Read: `docs/CLAUDE-INTEGRATION.md` for complete guide
- Read: `docs/CLAUDE-SYSTEM-ARCHITECTURE.md` for technical details
- Explore: `~/.claude/agents/` for specialized AI agents

## 🆘 Quick Troubleshooting

### Problem: Claude feels slow

**Solution**: Enable MCP servers for better performance

```bash
# Check if MCP servers are running
claude /help  # Should show enhanced capabilities
```

### Problem: Commands seem outdated

**Solution**: Your symlinks might be stale

```bash
# Refresh everything
make build-switch
# Commands are now current with your dotfiles
```

### Problem: Settings keep resetting

**Solution**: This is normal! settings.json is copied (not symlinked) so Claude can modify it

```bash
# Your personal settings are preserved
# Template updates come from: modules/shared/config/claude/settings.json
```

## 🚀 Power User Tips

### Combine Commands

```bash
# Chain multiple AI operations
claude /analyze "performance issues" && claude /task "implement the top 3 optimizations"
```

### Use with Dotfiles Context

```bash
# Claude understands your dotfiles structure
claude /spawn "add a new package to shared modules"
claude /debug "why isn't my nix build working?"
```

### Leverage Specialized Agents

```bash
# Use domain-specific agents via /task command
claude /task "security review the authentication flow"  # Uses security-auditor
claude /task "optimize database queries"                # Uses performance-optimizer
```

---

**🎯 You're all set!** Claude Code is now supercharged with your dotfiles. Start with `/help` and explore the 20+ specialized commands at your disposal.

**Need help?** Check the [complete integration guide](CLAUDE-INTEGRATION.md) or [system architecture](CLAUDE-SYSTEM-ARCHITECTURE.md).
