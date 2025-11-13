---
name: testing-claude-commands-with-subagents
description: Use when validating Claude Code slash commands before deployment - applies pressure testing scenarios to verify commands work reliably, handle edge cases, and resist user confusion or misuse
---

# Testing Claude Commands With Subagents

## Overview

**Testing commands IS systematically verifying they work under real-world conditions and edge cases.**

Commands seem simple but fail in predictable ways: no arguments, wrong context, permission errors, or confusing feedback. Testing requires METHODICAL approach, not random clicking.

**Core principle:** Test EVERYTHING that can realistically go wrong. Don't assume "obvious" cases work.

**Iron Rule: If you didn't test it, it's broken.**

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development and superpowers:testing-skills-with-subagents. This skill applies systematic testing to commands.

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

## MANDATORY Test Categories (Don't Skip Any)

Based on agent testing failures, ALL commands must be tested for:

### 1. Argument Testing
**Must test:**
- No arguments (`/command` with nothing after)
- Single word arguments
- Multiple word arguments
- Special characters (`!@#$%^&*()`)
- Quotes and spaces (`"feature name"`)

### 2. Context Testing
**Must test:**
- Wrong directory (not in git repo)
- Dirty working directory (uncommitted changes)
- Missing prerequisites (no network, wrong permissions)
- Conflicting state (branch already exists)

### 3. Permission Testing
**Must test:**
- Missing tools from allowed-tools
- Insufficient permissions
- Tool execution failures

### 4. Error Message Testing
**Must verify:**
- Error messages are helpful, not technical
- Users know what to do next
- No cryptic git/tool errors leak through

### 5. Pressure Testing
**Must test:**
- Time pressure scenarios
- Multiple rapid uses
- User confusion scenarios

## Testing Templates (Use These Exact Scenarios)

### Template 1: No Arguments Test
```markdown
IMPORTANT: Real scenario. Test this command now:

/command
(with no arguments after it)

What happens? Is the output clear? Does it help users understand what they should provide?
```

### Template 2: Edge Case Test
```markdown
IMPORTANT: Real scenario. Test this command now:

/command "feature/weird@name#123"

What happens with special characters and spaces?
```

### Template 3: Wrong Context Test
```markdown
IMPORTANT: Real scenario. Test this command now:

cd /tmp
/command test-branch

You're NOT in a git repository. What happens? Is the error message helpful?
```

### Template 4: Dirty State Test
```markdown
IMPORTANT: Real scenario. Test this command now:

# Create a file with changes
echo "test" > /tmp/repo/dirty.txt
cd /tmp/repo
/command test-branch

Working directory is dirty. What happens? Does it provide clear guidance?
```

## Documentation Requirements

**For each test, document:**
1. **Exact command used**
2. **Expected behavior**
3. **Actual behavior**
4. **Problem identified**
5. **Specific fix needed**

Don't write summaries. Document each test individually with specific details.

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
