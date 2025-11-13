---
name: writing-claude-commands
description: Use when creating Claude Code slash commands - provides systematic approach for command creation, from purpose identification to deployment, with TDD methodology and integration with superpowers ecosystem
---

# Writing Claude Commands

## Overview

**Writing Claude commands IS creating focused, reusable interfaces to specific workflows or automations.**

Commands provide simple entry points for complex operations by mapping intuitive names to clear instructions or underlying skills.

**Core principle:** Commands should be simple to use but precise in their purpose - each command solves one specific problem well.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill. Commands follow the same RED-GREEN-REFACTOR cycle as code and skills.

## When to Create Commands

**Create when:**
- Workflow is frequently repeated but complex to remember
- Task needs consistent execution across multiple users
- Existing skill needs simple interface for common use cases
- Operation requires specific tool permissions or context setup
- Team needs standardized approach to common operations

**Don't create for:**
- One-off operations or unique situations
- Simple tool calls that are already intuitive
- Operations that don't benefit from standardization
- Commands that would duplicate existing functionality

## Command Types

### Simple Prompt Commands
Direct instructions without complex logic:
```markdown
---
description: Review code for security vulnerabilities
---

Examine this code for:
- SQL injection vulnerabilities
- XSS attack vectors
- Authentication bypasses
- Input validation issues
```

### Skill Wrapper Commands
Thin wrappers around existing superpowers:
```markdown
---
description: Interactive design refinement using Socratic method
---

Use and follow the brainstorming skill exactly as written
```

### Workflow Automation Commands
Multi-step processes with specific context:
```markdown
---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
argument-hint: [message]
description: Create and push git commit with proper formatting
---
```

## RED-GREEN-REFACTOR for Commands

### RED: Identify Failing Command Need

Before writing the command, run the task manually and document:
- What steps are repeated each time?
- Where do people make mistakes?
- What information is always needed?
- Which tools are required?

**Example baseline:**
```
User: "Can you help me create a pull request?"
You: [Asks 5 questions about branch, title, description, reviewers, etc.]
User: [Provides information piecemeal]
You: [Manually constructs PR]
```

### GREEN: Write Minimal Command

Create command that addresses specific failures from RED phase:

```markdown
---
description: Create pull requests with proper branch management and review assignment
---

I'm using the creating-pull-requests skill to create your pull request.

[The skill handles all the systematic steps automatically]
```

### REFACTOR: Improve Command Quality

Test command with edge cases and improve:
- Add missing tool permissions
- Clarify ambiguous instructions
- Add argument hints for better UX
- Include integration points

## Command Structure

### Frontmatter Requirements

**Required fields:**
```yaml
---
description: What this command does in third person (max 100 chars)
---
```

**Optional fields:**
```yaml
---
allowed-tools: Bash(git add:*), Bash(git status:*)
argument-hint: [optional] [parameters] [here]
model: claude-3-5-sonnet-20241022
disable-model-invocation: true
---
```

### Command Content Patterns

#### Simple Commands (Direct Instructions)
```markdown
---
description: Optimize this code for performance
---

Analyze the provided code for:
- Algorithm efficiency
- Memory usage patterns
- Potential bottlenecks
- Suggest specific optimizations with examples
```

#### Skill Wrapper Commands
```markdown
---
description: Execute systematic debugging process
---

Use and follow the systematic-debugging skill exactly as written
```

#### Complex Workflow Commands
```markdown
---
allowed-tools: Bash, Read, Write, Edit
argument-hint: [feature-name]
description: Create complete feature implementation branch
---

## Context
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -5`

## Task
Create feature branch for: $ARGUMENTS

Follow this workflow:
1. Create feature branch from main
2. Set up basic file structure
3. Run tests to establish baseline
4. Report branch status and next steps
```

## Integration Points

**Pairs with:**
- **testing-claude-commands-with-subagents**: Validate command works under pressure
- **writing-skills**: Create underlying skills for complex commands
- **sharing-skills**: Distribute commands to team

**Required background:**
- Understand Claude Code slash command system
- Have specific workflow to automate
- Basic familiarity with YAML frontmatter

## Common Mistakes

**Commands that are too complex**
- Problem: Should be a skill instead
- Fix: Extract complexity to skill, keep command simple

**Missing tool permissions**
- Problem: Command fails when trying to execute bash commands
- Fix: Add explicit allowed-tools in frontmatter

**Vague descriptions**
- Problem: Users don't know what command does
- Fix: Write clear, action-oriented descriptions

**No error handling**
- Problem: Command fails silently on invalid input
- Fix: Add validation and helpful error messages

**Poor argument handling**
- Problem: Commands break with unexpected input formats
- Fix: Use argument hints and validation patterns

## Testing Checklist

- [ ] Command file created in appropriate directory
- [ ] Frontmatter includes required description field
- [ ] Description is third-person and under 100 characters
- [ ] Command works with /help discovery
- [ ] Execution produces expected results
- [ ] Tool permissions are specified and sufficient
- [ ] Arguments are handled correctly (if applicable)
- [ ] Error conditions provide helpful feedback
- [ ] Integration with other commands/skills works
- [ ] Documentation is clear and actionable

## Deployment

**Project commands:**
- Location: `.claude/commands/`
- Shared with team via git
- Appears as "(project)" in /help

**Personal commands:**
- Location: `~/.claude/commands/`
- Personal use only
- Appears as "(user)" in /help

**Shared commands (dotfiles):**
- Location: `users/shared/.config/claude/commands/`
- Managed via dotfiles system
- Distributed to team through configuration management

## Quality Standards

**Every command must:**
- Have clear purpose and scope
- Include proper frontmatter
- Handle errors gracefully
- Work reliably under normal usage
- Integrate well with existing tooling
- Follow naming conventions

**Good command characteristics:**
- Single responsibility
- Consistent interface
- Predictable behavior
- Helpful error messages
- Clear documentation
- Proper permissions
