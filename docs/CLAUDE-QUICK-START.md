# Claude Code Quick Start Guide

This guide helps you get started with Claude Code in the dotfiles environment.

## Prerequisites

- Nix installed with flakes enabled
- Claude Code setup completed via `make setup-mcp`

## Basic Usage

### Code Analysis

```bash
# Comprehensive codebase analysis
claude /analyze

# Performance-focused analysis
claude /analyze --performance
```

### Code Implementation

```bash
# Implement new features
claude /implement user authentication

# API development
claude /implement api user management
```

### Code Improvements

```bash
# General improvements
claude /improve src/

# Performance optimizations
claude /improve performance api/
```

### Leverage Specialized Agents

```bash
# Use domain-specific agents via /task command
claude /task "optimize database queries"                # Uses performance-optimizer
claude /task "debug complex system issue"               # Uses root-cause-analyzer
```

## Command Reference

| Command | Purpose | Agent Routing |
|---------|---------|---------------|
| `/analyze` | Comprehensive analysis | performance-optimizer, root-cause-analyzer |
| `/implement` | Feature development | frontend-developer, backend-engineer, system-architect |
| `/improve` | Code quality improvements | performance-engineer, system-architect |

## Best Practices

1. **Start with analysis**: Use `/analyze` to understand your codebase before making changes
2. **Be specific**: Target specific paths or components for focused improvements
3. **Use agents**: Leverage specialized agents for domain-specific tasks
4. **Test changes**: Always validate improvements with your test suite

## Integration with dotfiles

The Claude Code configuration automatically syncs from `modules/shared/config/claude/` to `~/.claude` when you run system builds, providing seamless integration with your development workflow.
