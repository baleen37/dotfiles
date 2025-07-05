# Claude Code Integration Guide

> **Complete setup and command reference for Claude Code with Nix dotfiles**

This guide covers everything from Claude Code setup to using the 20+ specialized commands configured in this dotfiles repository for AI-assisted development workflows.

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
claude --version
```

## 🚀 Quick Setup

### 1. Initial Configuration
```bash
# Build the dotfiles to configure Claude
make build && make switch HOST=your-hostname

# Verify Claude configuration
ls -la ~/.claude/
```

### 2. Test Integration
```bash
# Test a simple command
claude /help

# Test dotfiles-specific command
claude /do-plan "Add new development tool"
```

## 📋 Command Categories & Reference

### 🎯 Project Management
Plan, organize, and track development work

#### `/do-plan`
**Purpose**: Create detailed implementation plans for features or tasks
**Best for**: Starting complex features, breaking down large tasks, architectural decisions

```bash
# Examples
claude /do-plan "Add dark mode to the application"
claude /do-plan "Optimize build performance"
claude /do-plan "Refactor authentication system"
```

#### `/do-issue`
**Purpose**: Work on specific GitHub issues with full context
**Best for**: Bug fixes, feature implementations, issue resolution

```bash
# Examples
claude /do-issue 123  # Work on issue #123
claude /do-issue "fix login bug"  # Search and work on issue
```

#### `/do-todo`
**Purpose**: Manage and execute TODO items efficiently
**Best for**: Task tracking, follow-ups, maintenance work

```bash
# Examples
claude /do-todo  # Show current todos
claude /do-todo "Add unit tests for auth module"
```

### 🔧 Development Workflow
Build, test, and deploy code changes

#### `/start-feature`
**Purpose**: Start new feature development with proper branch setup
**Best for**: Beginning new features, setting up development environment

```bash
# Examples
claude /start-feature "user-authentication"
claude /start-feature "performance-optimization"
```

#### `/create-pr`
**Purpose**: Create well-formatted pull requests with comprehensive descriptions
**Best for**: Code reviews, collaboration, documentation

```bash
# Examples
claude /create-pr
claude /create-pr --draft  # Create draft PR
```

#### `/fix-pr`
**Purpose**: Address PR review feedback and resolve conflicts
**Best for**: PR iterations, addressing review comments

```bash
# Examples
claude /fix-pr 456  # Fix issues in PR #456
claude /fix-pr --conflicts  # Resolve merge conflicts
```

### 📝 Code Quality
Testing, review, and improvement processes

#### `/brainstorm`
**Purpose**: Generate ideas and explore solutions for complex problems
**Best for**: Architecture decisions, creative problem solving

```bash
# Examples
claude /brainstorm "How to improve test coverage"
claude /brainstorm "Database schema design for multi-tenant app"
```

#### `/setup`
**Purpose**: Configure development environment and tools
**Best for**: New project setup, environment configuration

```bash
# Examples
claude /setup  # General environment setup
claude /setup --project-type typescript  # Language-specific setup
```

### 🌿 Git & Collaboration
Version control and team collaboration

#### `/create-worktree`
**Purpose**: Create Git worktrees for parallel development
**Best for**: Working on multiple features, hotfixes

```bash
# Examples
claude /create-worktree feature/new-ui
claude /create-worktree hotfix/critical-bug
```

#### `/plan-gh`
**Purpose**: Plan GitHub-related workflows and automation
**Best for**: CI/CD setup, GitHub Actions, repository management

```bash
# Examples
claude /plan-gh "Setup automated testing"
claude /plan-gh "Add deployment workflow"
```

### 📚 Documentation
Create and maintain project documentation

#### `/update-docs`
**Purpose**: Update and maintain project documentation
**Best for**: Keeping docs current, improving documentation quality

```bash
# Examples
claude /update-docs  # Update all documentation
claude /update-docs --api  # Update API documentation
```

#### `/session-summary`
**Purpose**: Generate summaries of development sessions
**Best for**: Progress tracking, team communication

```bash
# Examples
claude /session-summary  # Summarize current session
claude /session-summary --detailed  # Detailed summary with changes
```

## ⚙️ Configuration Details

### Configuration Files Location
- **Main config**: `~/.claude/settings.json`
- **Commands**: `~/.claude/commands/`
- **Project config**: `modules/shared/config/claude/`

### Smart Preservation System
The dotfiles include a smart Claude settings preservation system:

- **Automatic backup**: Settings are backed up before updates
- **Selective preservation**: User modifications are detected and preserved
- **Safe updates**: New dotfiles settings are saved as `.new` files when conflicts exist
- **Interactive merge**: Use `./scripts/merge-claude-config` to integrate updates

### Customization

#### Adding Custom Commands
```bash
# Create custom command
echo "Your custom prompt here" > ~/.claude/commands/my-command.md

# Use custom command
claude /my-command
```

#### Modifying Existing Commands
```bash
# Edit command (will be preserved across dotfiles updates)
editor ~/.claude/commands/do-plan.md

# Merge updates when dotfiles change
./scripts/merge-claude-config
```

## 🔧 Advanced Usage

### Project-Specific Context
Claude commands automatically understand:
- **Nix flake structure** and package management
- **Build system** (make targets, scripts)
- **Testing framework** and test patterns
- **Git workflow** and branch structure
- **Documentation standards** and formats

### Environment Integration
```bash
# Commands work with dotfiles environment
export USER=your-username  # For Nix builds
claude /do-plan "Add new package to shared modules"

# Commands understand platform differences
claude /start-feature "darwin-specific-feature"
```

### MCP Server Setup
For advanced integrations:
```bash
# Install MCP servers (handled by dotfiles)
npm install -g @anthropic/mcp-server-filesystem
npm install -g @anthropic/mcp-server-github

# Configuration is automatic via dotfiles
```

## 🔄 Maintenance

### Regular Updates
```bash
# Update dotfiles (preserves Claude configuration)
git pull origin main
make build && make switch HOST=your-hostname

# Check for Claude configuration updates
./scripts/merge-claude-config --list
```

### Backup and Recovery
```bash
# Manual backup
cp -r ~/.claude ~/.claude.backup

# Restore from backup
cp -r ~/.claude.backup ~/.claude

# Check preserved settings
ls ~/.claude/.backups/
```

## 🆘 Troubleshooting

### Common Issues

**Issue: Commands not found**
```bash
# Solution: Rebuild dotfiles configuration
make build && make switch HOST=your-hostname
```

**Issue: Configuration conflicts after update**
```bash
# Solution: Use merge tool
./scripts/merge-claude-config
```

**Issue: MCP servers not working**
```bash
# Solution: Check Node.js version and reinstall
node --version  # Must be 18+
npm install -g @anthropic/mcp-server-*
```

### Debug Commands
```bash
# Check Claude configuration
cat ~/.claude/settings.json

# List available commands
ls ~/.claude/commands/

# Test specific command
claude /help
```

## 📚 Command Quick Reference

| Command | Purpose | Example Usage |
|---------|---------|---------------|
| `/do-plan` | Create implementation plans | `claude /do-plan "Add API endpoint"` |
| `/do-issue` | Work on GitHub issues | `claude /do-issue 123` |
| `/start-feature` | Start new feature branch | `claude /start-feature "user-auth"` |
| `/create-pr` | Create pull request | `claude /create-pr` |
| `/brainstorm` | Generate ideas | `claude /brainstorm "Performance issues"` |
| `/setup` | Environment setup | `claude /setup --typescript` |
| `/update-docs` | Update documentation | `claude /update-docs` |

For the complete list of commands and detailed usage, see the individual command files in `~/.claude/commands/`.
