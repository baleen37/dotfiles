---
name: writing-claude-commands
description: Use when creating Claude Code slash commands - provides systematic approach for command creation, from purpose identification to deployment, with TDD methodology and integration with superpowers ecosystem
---

# Writing Claude Commands

## Overview

**Writing Claude commands IS creating focused, minimal interfaces to specific tasks.**

Commands provide simple entry points that do exactly one thing well. They are NOT comprehensive workflow systems or complex automation tools.

**Core principle:** Commands must be SIMPLE. Each command solves ONE specific problem with MINIMAL complexity.

**Iron Rule: If you're creating a complex workflow with 6+ steps, you're building a skill, not a command.**

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill. Commands follow the same RED-GREEN-REFACTOR cycle as code and skills.

## When to Create Commands

**Create when:**
- Task is REPEATEDLY needed and can be explained in 2-3 sentences
- Task is CONSISTENTLY the same each time (no complex decision trees)
- Task is FORGETTABLE or error-prone when done manually
- Task needs specific PERMISSIONS that are tedious to set up each time

**Don't create for:**
- Complex workflows that require multiple steps or decisions
- Tasks that need adaptation based on context
- Simple operations that are already intuitive (like "list files")
- One-time operations or unique situations
- Anything that would benefit from a full skill instead

**Remember: Commands = Simple and Repeatable, Skills = Complex and Comprehensive**

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

## Common Mistakes (Based on Agent Testing)

**❌ Creating Complex Workflows (Over-Engineering)**
```markdown
# BAD: 6-step comprehensive system
## Context: [3 bash commands]
## Step 1: Pre-flight checks
## Step 2: Branch name validation
## Step 3: Base branch selection
## Step 4: Branch creation
## Step 5: Initial setup
## Step 6: Verification
```
**Reality:** This is a SKILL, not a command
**Fix:** Simplify to ONE specific task or create a skill instead

**❌ "Just Works" Mentality**
- Problem: Trying to handle every edge case creates complexity
- Reality: Commands should handle COMMON cases gracefully, fail clearly on edge cases
- Fix: Handle 80% of cases, provide helpful error for remaining 20%

**❌ Interactive Guidance Systems**
```markdown
# BAD: Complex user interaction
"Would you like to: A) Commit changes, B) Stash changes, C) Continue anyway?"
```
**Problem:** Commands are not interactive scripts
**Fix:** Make clear assumptions or provide clear error messages

**❌ Missing Tool Permissions**
- Problem: Command fails with cryptic "tool not allowed" errors
- Fix: Add explicit allowed-tools in frontmatter for EVERY tool used

**❌ Poor Argument Validation**
- Problem: No arguments = confusing empty behavior
- Fix: Add argument-hint and basic validation

**❌ No Clear Purpose**
- Problem: "Help with git operations" - too broad
- Fix: "Create feature branch from main" - specific and actionable

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
