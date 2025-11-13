---
name: testing-claude-commands-with-subagents
description: Use when validating Claude Code slash commands before deployment - applies pressure testing scenarios to verify commands work reliably, handle edge cases, and resist user confusion or misuse
---

# Testing Claude Commands With Subagents

## Overview

**Testing commands is verifying they work reliably under real-world pressure and edge cases.**

Commands seem simple but can fail in subtle ways: ambiguous arguments, missing context, permission errors, or user confusion. Testing with subagents simulates real usage patterns.

**Core principle:** If you didn't watch an agent struggle with the command, you don't know if it's robust enough for production.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development and superpowers:testing-skills-with-subagents. This skill adapts those patterns specifically to slash commands.

## When to Test Commands

**Test commands that:**
- Have complex argument handling
- Require specific tool permissions
- Execute automated workflows
- Are used by multiple team members
- Have safety or security implications
- Integrate with external systems

**Don't extensively test:**
- Simple prompt commands
- Skill wrappers (test the skill instead)
- Commands with obvious behavior

## TDD Mapping for Command Testing

| TDD Phase | Command Testing | What You Do |
|-----------|----------------|-------------|
| **RED** | Baseline scenarios | Run command without it existing, watch agent fail |
| **Verify RED** | Capture confusion | Document where agents get confused or make mistakes |
| **GREEN** | Write command | Address specific confusion points from baseline |
| **Verify GREEN** | Pressure test | Run scenarios WITH command, verify success |
| **REFACTOR** | Handle edge cases | Test ambiguous inputs, missing permissions, etc. |
| **Stay GREEN** | Re-verify | Test again, ensure still works under pressure |

## RED Phase: Baseline Testing (Watch It Fail)

**Goal:** Run task WITHOUT the command - document exactly how agents struggle.

### Test Scenarios

#### 1. Manual Task Attempt
```bash
# Test without command: "Create a feature branch for user authentication"
# Expected RED behavior:
# - Agent forgets to switch from main
# - Creates poorly named branch
# - Doesn't verify git status
# - Makes common mistakes
```

#### 2. Ambiguous Instructions
```bash
# Test vague request: "Set up a new project"
# Expected confusion:
# - Agent asks many clarifying questions
# - Makes assumptions about project type
# - Misses important setup steps
```

#### 3. Time Pressure Scenarios
```bash
# Add urgency: "Quick! Before the meeting, create a PR for this hotfix"
# Expected failures:
# - Skips important steps
# - Makes sloppy commit messages
# - Forgets to add reviewers
```

**Document specific failures verbatim:**
- Exact questions agents ask
- Mistakes they commonly make
- Points where they get stuck
- Wrong assumptions they make

## GREEN Phase: Write Command to Address RED

**Write command that specifically addresses baseline failures:**

If baseline showed agents forget to check git status:
```markdown
---
description: Create feature branch with proper git state verification
allowed-tools: Bash(git:*), Read, Write
---

## Context
- Current branch: !`git branch --show-current`
- Git status: !`git status --porcelain`
- Working directory clean: !`git diff-index --quiet HEAD -- && echo "clean" || echo "dirty"`

## Task
Create feature branch for: $ARGUMENTS

Steps:
1. Verify clean working directory
2. Switch to main branch
3. Pull latest changes
4. Create feature branch with proper naming
5. Verify branch creation
```

## Pressure Test Scenarios

### 1. Ambiguous Arguments
```bash
# Test: /create-branch
# (no arguments provided)

Expected success:
- Command detects missing arguments
- Provides helpful usage instructions
- Suggests proper argument format
```

### 2. Invalid Context
```bash
# Test: /create-branch "user auth"
# (while in dirty working directory)

Expected success:
- Command detects uncommitted changes
- Offers to stash or commit
- Provides clear error recovery path
```

### 3. Time Pressure
```bash
# Test: "Hurry, create branch for emergency fix before everyone gets on call"
# Command should: /create-branch emergency-hotfix-2025-11-13

Expected success:
- Still follows all safety checks
- Doesn't skip verification steps
- Maintains quality under pressure
```

### 4. Multiple Users
```bash
# Test with different agent personalities:
- Cautious agent (should work)
- Impatient agent (should still work)
- Detail-oriented agent (should appreciate thoroughness)
```

## REFACTOR Phase: Handle Edge Cases

### Common Edge Cases to Test

#### Missing Permissions
```bash
# Test command when tools aren't allowed
# Should provide clear error message about missing permissions
```

#### Invalid Git State
```bash
# Test when:
- Not in a git repository
- On detached HEAD
- Remote doesn't exist
- Network is unavailable
```

#### Special Characters in Arguments
```bash
# Test: /create-branch "feature/bug fix #123"
# Should handle spaces, slashes, special chars properly
```

#### Race Conditions
```bash
# Test: Two agents running command simultaneously
# Should handle conflicts gracefully
```

## Subagent Test Templates

### Test 1: Baseline Confusion
```markdown
You're helping a developer who says: "I need to work on user login functionality"

Help them set up a feature branch. Do NOT use any slash commands - do everything manually.

Document any confusion or uncertainty you encounter.
```

### Test 2: Command Under Pressure
```markdown
You're in a hurry before a重要 meeting. The stakeholder says: "We need to push the payment integration fix NOW!"

Create a branch and get ready for the fix. Use the /create-branch command if available.

Report any frustrations or delays in the process.
```

### Test 3: Edge Case Testing
```markdown
Test this command thoroughly:

/create-branch "test/weird@chars#123"

Try to break it. Find any scenarios where it might fail or confuse users.

Report all issues you discover.
```

## Success Criteria

**Command passes testing when:**
- Handles missing arguments gracefully
- Works with various argument formats
- Provides clear error messages
- Maintains safety checks under pressure
- Integrates well with git workflows
- Different agent personalities can use it successfully
- Edge cases don't cause confusing errors

## Common Failure Patterns

### Permission Confusion
```
Agent: "I can't run git status"
Problem: Missing allowed-tools in frontmatter
Fix: Add Bash(git status:*) to permissions
```

### Argument Ambiguity
```
Agent: "What format should the branch name be?"
Problem: No argument hints or examples
Fix: Add argument-hint to frontmatter, include examples
```

### Context Missing
```
Agent: "I don't know if the working directory is clean"
Problem: Command doesn't provide necessary context
Fix: Add bash commands to show git state
```

## Integration Testing

**Test with other commands:**
- Does it work after other commands have changed git state?
- Can it be used in sequences with other commands?
- Does it interfere with other workflows?

**Test with skills:**
- If wrapping a skill, does the skill work correctly?
- Does the command add value beyond using the skill directly?

## Documentation Quality

**Verify command documentation:**
- Description appears correctly in /help
- Usage examples are clear and accurate
- Error messages are helpful
- Integration points are documented

## Continuous Validation

**After command is deployed:**
- Monitor actual usage patterns
- Collect user feedback
- Watch for common failure modes in real usage
- Update command based on real-world feedback

## Testing Checklist

- [ ] Baseline scenarios run without command (RED)
- [ ] Specific confusion points documented
- [ ] Command addresses documented failures
- [ ] Pressure scenarios handled successfully
- [ ] Edge cases tested and handled
- [ ] Error messages are helpful and actionable
- [ ] Multiple agent personalities can use it
- [ ] Integration with other tools works
- [ ] Documentation is accurate and complete
- [ ] Real-world usage validates assumptions
