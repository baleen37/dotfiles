# Update Command

Quickly create or update Claude command files

## Overview

Create or modify command files in `modules/shared/config/claude/commands/`. Simple, fast, effective.

## Quick Start

```
/user:update-command <command-name>
```

**New command?** → Creates template → You fill it in  
**Existing command?** → Shows current content → You specify changes

## Main Workflow

### Step 1: Analyze

**What to do:**
- Check if command exists
- If exists: Read current content, identify what needs changing
- If new: Determine command purpose and structure

**Simple prompt:**
```
Working with '[command-name]' command.
Purpose: [what you want to do]

Check if it exists and suggest approach.
```

### Step 2: Execute

**For new commands:**
```
Create '[command-name]' command file.

Purpose: [what it does]
Structure: [workflow steps if multi-step, or single action]

Make it practical and easy to use.
```

**For updates:**
```
Update '[command-name]' command.

Changes needed: [specific improvements]

Keep what works, fix what doesn't.
```

### Step 3: Verify (Optional)

Quick check:
- Does it solve the problem?
- Is it easy to understand?
- Ready to commit?

## Quick Patterns

### One-liner Fix
```
Fix typo in '[command-name]': [old] → [new]
```

### Simple Command Template
```
# [Command Name]

[What it does in one sentence]

## Usage
/user:[command-name] [args]

## Workflow
1. [First step]
2. [Second step]
3. [Done]

## Example
[Show actual usage]
```

## Command Types

### Action Commands
Do one thing well (commit, build, test)

### Workflow Commands  
Multi-step process (plan, fix-pr, update-docs)

### Utility Commands
Helpers and tools (session-summary, brainstorm)

## Best Practices

✅ **DO:**
- Start with the simplest version
- Use real examples
- Make prompts self-contained
- Test with actual usage

❌ **DON'T:**
- Over-engineer simple tasks
- Create duplicate commands
- Make users think too hard
- Add steps "just in case"

## Real Examples

### Creating Simple Command
```bash
/user:update-command test-runner

# Claude checks → doesn't exist
# Claude creates:
"Create test-runner command.
Purpose: Run tests with pretty output
Single action command."

# Result: Simple, working command file
```

### Updating Complex Command
```bash
/user:update-command plan

# Claude reads current file
# You say: "Prompts are too vague, need examples"
# Claude updates with concrete examples

# Git: git add . && git commit -m "fix(claude): plan 명령어 프롬프트 개선"
```

### Quick Fix
```bash
/user:update-command commit

# You: "Fix typo: 'commiting' → 'committing'"
# Claude: Makes the fix
# Done in 30 seconds
```

## Tips

- **Start simple**: You can always add complexity later
- **Copy patterns**: Look at similar commands for inspiration  
- **Test immediately**: Try the command right after creating
- **One command, one purpose**: Don't try to do everything

## Common Issues

**"Command already exists"**  
→ Use update workflow instead

**"Too complex"**  
→ Break into multiple simpler commands

**"Prompts unclear"**  
→ Add specific examples
