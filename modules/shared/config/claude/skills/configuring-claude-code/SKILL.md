---
name: Configuring Claude Code
description: Configures Claude Code commands, agents, hooks, skills, and settings. Use when setting up or customizing Claude Code behavior, creating custom workflows, or managing configuration files.
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
---

# Configuring Claude Code

Comprehensive guide for configuring Claude Code through commands, agents, hooks, skills, and settings.

## Configuration Types Overview

**Commands**: Manual slash commands (`/command-name`) for explicit invocation
**Agents**: Specialized sub-agents for complex autonomous tasks
**Hooks**: Event-triggered automation (pre/post tool use, notifications, etc.)
**Skills**: Autonomous capabilities invoked by Claude based on context
**Settings**: Permissions, environment variables, model selection

## Directory Structure

```
.claude/
├── settings.json           # Permissions, env vars, model config
├── settings.local.json     # Personal settings (not checked in)
├── CLAUDE.md              # Project instructions
├── commands/              # Slash commands (*.md)
├── agents/                # Custom agents (*.md)
├── hooks/                 # Event hooks (executable scripts)
└── skills/                # Autonomous skills (*/SKILL.md)
    └── skill-name/
        ├── SKILL.md       # Core workflow (< 500 lines)
        ├── reference.md   # Optional: detailed examples
        └── templates/     # Optional: template files
```

## 1. Commands (Slash Commands)

**Purpose**: Explicit user-invoked workflows

### File Structure

Create `.claude/commands/command-name.md`:

```markdown
---
name: Command Name
tags: [tag1, tag2]
---

Expanded prompt that Claude receives when `/command-name` is invoked.

Include specific instructions, workflows, or context.
```

### Best Practices

- **Naming**: Use kebab-case, descriptive names
- **Content**: Clear, specific instructions for the workflow
- **Invocation**: User types `/command-name` explicitly
- **Use when**: Workflow requires manual trigger or user input

### Quick Tasks

```bash
# Create new command
cat > .claude/commands/my-command.md << 'EOF'
---
name: My Command
tags: [workflow]
---

Instructions for what Claude should do when this command is invoked.
EOF
```

## 2. Agents (Sub-agents)

**Purpose**: Specialized autonomous workers for complex multi-step tasks

### File Structure

Create `.claude/agents/agent-name.md`:

```markdown
---
name: Agent Name
description: What this agent does and when to use it
---

Detailed instructions for the agent's behavior, workflows, and constraints.
```

### Best Practices

- **Specialization**: Each agent has clear, focused responsibility
- **Description**: Specific enough for Claude to know when to invoke
- **Instructions**: Comprehensive autonomous workflow
- **Use when**: Complex tasks requiring sustained autonomous work

### Agent vs Command vs Skill

**Agent**: Complex multi-step autonomous task (code review, debugging)
**Command**: Manual workflow trigger (create PR, run specific analysis)
**Skill**: Autonomous capability based on context (processing PDFs, testing workflows)

## 3. Hooks

**Purpose**: Event-triggered automation and validation

### Available Hook Types

**Tool Lifecycle**:

- `PreToolUse`: Before tool execution (validation, logging)
- `PostToolUse`: After tool execution (cleanup, notifications)

**Session Lifecycle**:

- `SessionStart`: When Claude Code session begins
- `SessionEnd`: When Claude Code session ends

**Other Events**:

- `Notification`: On system notifications
- `UserPromptSubmit`: Before user prompt sent to Claude
- `Stop`: When user stops Claude
- `SubagentStop`: When sub-agent stops
- `PreCompact`: Before context compaction

### Configuration Format

Edit `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "path/to/validation-script.sh",
            "timeout": 5000
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash(git.*)",
        "hooks": [
          {
            "type": "command",
            "command": "path/to/git-logger.sh"
          }
        ]
      }
    ]
  }
}
```

### Hook Script Interface

**Input**: JSON via stdin with event data
**Output**: Exit code (0 = success, 2 = block/error) or JSON response

Example hook script:

```bash
#!/bin/bash
# Read JSON input
input=$(cat)

# Process and validate
# ...

# Exit 0 for success, 2 to block operation
exit 0
```

### Security Best Practices

- **Validate inputs**: Never trust hook data directly
- **Quote variables**: Prevent injection attacks
- **Block path traversal**: Validate file paths
- **Use absolute paths**: Avoid PATH-based attacks
- **Avoid sensitive files**: Never log secrets

### Common Use Cases

- Logging tool usage
- Validating file operations before execution
- Adding project context to prompts
- Custom permission systems
- Cleanup or setup tasks

## 4. Skills

**Purpose**: Autonomous capabilities invoked by Claude based on context matching

### File Structure

Create `.claude/skills/skill-name/SKILL.md`:

```yaml
---
name: Skill Name (gerund form)
description: What it does and when to use it. Third person, specific.
allowed-tools: [Tool1, Tool2]
---

# Main Instructions

Core workflow and essential instructions (< 500 lines)
```

### Naming Conventions

**Use gerund form (verb + -ing)**:

- ✅ "Processing PDFs", "Analyzing Code", "Testing Workflows"
- ❌ "PDF Helper", "Code Utils", "Test Tool"

**Be specific**:

- ✅ "Configuring Claude Code"
- ❌ "Configuration Helper"

### Description Guidelines

**Third person, specific, includes when to use**:

```yaml
# Good
description: Extracts and analyzes content from PDF files. Use when working with PDF documents or needing to process PDF data.

# Bad
description: Helps with PDFs
```

### Progressive Disclosure

**SKILL.md**: Core workflow only (< 500 lines)
**reference.md**: Detailed examples, troubleshooting, advanced topics
**templates/**: Template files if needed
**scripts/**: Utility scripts for deterministic operations

Keep references one level deep (don't nest too deeply).

### Conciseness Requirements

- **Challenge every line**: "Does Claude really need this explanation?"
- **Remove common knowledge**: Claude already knows basic programming concepts
- **Focus on specifics**: What's unique about this workflow
- **Use references**: Move details to reference.md

### Validation Checklist

- [ ] Name uses gerund form
- [ ] Description is specific and third person
- [ ] SKILL.md under 500 lines
- [ ] Workflow is clear and sequential
- [ ] No unnecessary explanations
- [ ] Consistent terminology
- [ ] Appropriate allowed-tools
- [ ] Validation/feedback steps included
- [ ] Detailed content in reference.md

### Anti-Patterns to Avoid

- ❌ Deeply nested file references
- ❌ Too many options (be prescriptive)
- ❌ Common knowledge Claude already has
- ❌ Time-sensitive information
- ❌ Magic numbers without justification
- ❌ Vague names ("Helper", "Utils")
- ❌ Windows-style paths
- ❌ Punting error handling to Claude
- ❌ Assuming tool availability

## 5. Settings

**Purpose**: Configure permissions, environment, and global behavior

### Settings Hierarchy

**Precedence (highest to lowest)**:

1. Enterprise managed policies
2. Command line arguments
3. Local project settings (`.claude/settings.local.json`)
4. Shared project settings (`.claude/settings.json`)
5. User settings (`~/.claude/settings.json`)

### Common Configuration

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(git:*)"
    ],
    "deny": [
      "Read(./.env)",
      "Write(config/production/*)"
    ]
  },
  "env": {
    "PROJECT_ROOT": "/path/to/project",
    "CUSTOM_VAR": "value"
  },
  "model": "claude-sonnet-4-5",
  "plugins": {
    "mcp-server-name": {
      "enabled": true,
      "config": {}
    }
  }
}
```

### Permission Patterns

**Tool-based**:

```json
"allow": ["Read", "Write", "Edit"]
```

**Pattern matching**:

```json
"allow": ["Bash(git.*)"]
```

**Path restrictions**:

```json
"deny": ["Read(.env)", "Write(production/*)"]
```

### Environment Variables

**Available in hooks and commands**:

- `$CLAUDE_PROJECT_DIR`: Current project directory
- Custom variables defined in settings

## Configuration Workflow

### 1. Identify Configuration Type

**Need manual trigger?** → Command
**Complex autonomous task?** → Agent
**Event-based automation?** → Hook
**Context-based capability?** → Skill
**Permissions/environment?** → Settings

### 2. Create Configuration File

Follow structure for chosen type (commands/, agents/, hooks/, skills/, settings.json)

### 3. Validate

**Commands**: Test with `/command-name`
**Agents**: Verify description triggers correct invocation
**Hooks**: Test with `claude --debug` to see hook execution
**Skills**: Test by describing use case
**Settings**: Verify with `/settings` or check logs

### 4. Iterate

Refine based on actual usage, maintain conciseness, update documentation

## Common Patterns

### Command for Analysis + Agent for Implementation

```bash
# Command: /analyze-codebase (manual trigger for analysis)
# Agent: code-reviewer (autonomous detailed review)
```

### Hook for Validation + Skill for Processing

```bash
# Hook: PreToolUse validates file operations
# Skill: Processing Files handles the actual work
```

### Settings for Environment + Command for Workflow

```json
// Settings: Define project-specific env vars
// Command: /deploy uses those env vars in workflow
```

## Troubleshooting

**Configuration not loading**:

- Check file location and naming
- Verify YAML/JSON syntax
- Check settings hierarchy (local overrides shared)

**Hook not firing**:

- Use `claude --debug` for detailed logs
- Verify matcher pattern (regex)
- Check hook script permissions (executable)

**Skill not being invoked**:

- Make description more specific
- Include trigger keywords
- Test with exact use case description

**Permission denied**:

- Check settings.json allow/deny rules
- Verify settings precedence
- Check for managed policies

## Success Criteria

- Configuration files follow correct structure
- Naming follows conventions (gerund for skills, kebab-case for commands)
- Skills stay under 500 lines
- Hooks have proper security validation
- Settings permissions are explicit
- Testing confirms expected behavior

## Reference

Detailed examples, templates, and advanced patterns: [reference.md](reference.md)

## Official Documentation

- [Commands](https://docs.claude.com/en/docs/claude-code/commands)
- [Agents](https://docs.claude.com/en/docs/claude-code/agents)
- [Hooks](https://docs.claude.com/en/docs/claude-code/hooks)
- [Skills](https://docs.claude.com/en/docs/claude-code/skills)
- [Agent Skills Best Practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
- [Settings](https://docs.claude.com/en/docs/claude-code/settings)
