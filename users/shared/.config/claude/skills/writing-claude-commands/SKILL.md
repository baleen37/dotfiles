---
name: writing-claude-commands
description: Use when creating Claude Code slash commands - enforces simplicity over comprehensiveness, prevents over-engineering by redirecting complex workflows to skills
---

# Writing Claude Commands

## Overview

**Commands are THIN entry points, not comprehensive systems.**

A command is a 5-15 line prompt that either:
1. Gives simple, direct instructions, OR
2. Delegates to a skill for complex work

**The Simplicity Test:** If your command is longer than 20 lines, you're building a skill, not a command.

**REQUIRED BACKGROUND:** You MUST understand superpowers:test-driven-development before using this skill.

## When to Create Commands vs Skills

| Signal | Command | Skill |
|--------|---------|-------|
| Line count | 5-20 lines | 50+ lines |
| **Steps** | **1-3** | **4+** |
| Decision points | 0-1 | Multiple |
| Checklists | Never | Often |
| Personas | Never | Sometimes |
| Output templates | Simple/none | Structured |

**The Step Rule (most important):** Count the numbered steps. 4+ steps = skill, period. You cannot "simplify" 9 steps into a command by writing them on fewer lines.

**If you're tempted to add:** OWASP lists, severity matrices, phase-by-phase processes, report templates, or comprehensive checklists → **STOP. Create a skill instead.**

## Command Patterns

### Pattern 1: Direct Instruction (Most Common)
```markdown
---
description: Review code for security vulnerabilities
---

Examine this code for SQL injection, XSS, auth bypasses, and input validation issues.
Report findings with file:line and severity.
```
**3 lines. Done.**

### Pattern 2: Skill Wrapper (For Complex Tasks)
```markdown
---
description: Comprehensive security analysis with OWASP coverage
---

Use and follow the security-review skill exactly as written.
```
**1 line. The skill has the complexity, not the command.**

### Pattern 3: Tool Permission Setup
```markdown
---
allowed-tools: Bash(git:*)
description: Quick git status check
---

Run git status and summarize changes.
```
**2 lines.**

## Creating a Command

1. **Identify the need**: What repetitive task needs a shortcut?
2. **Check complexity**: Does it need 4+ steps or checklists? → Create a skill first, then a 1-line wrapper command
3. **Write minimal prompt**: 5-15 lines max
4. **Add tool permissions**: If command uses Bash/Read/Write, add `allowed-tools`
5. **Test**: Run the command, verify it works

## Frontmatter Reference

```yaml
---
description: What this command does (max 100 chars, third person)  # REQUIRED
allowed-tools: Bash(git:*), Read, Edit                              # If using tools
argument-hint: [branch-name]                                        # If taking args
---
```

## Anti-Patterns (Real Examples from Testing)

### Over-Engineered Security Command (101 lines)
```markdown
# BAD - This is a SKILL disguised as a command
---
description: Comprehensive security analysis for OWASP Top 10...
---

You are a senior security engineer...  # ❌ Persona

## Scope of Analysis
1. **OWASP Top 10 Vulnerabilities:**
   - A01:2021 - Broken Access Control
   - A02:2021 - Cryptographic Failures
   [... 8 more items ...]              # ❌ Comprehensive checklist

## Review Process
1. **Scan Phase:** ...
2. **Analysis Phase:** ...
3. **Validation Phase:** ...
4. **Documentation Phase:** ...        # ❌ Multi-phase workflow

## Output Format
### Executive Summary
### Critical Findings (Severity: CRITICAL)
- **Title:** ...
- **Location:** ...
[... 20 more lines ...]               # ❌ Detailed output template
```

### Correct Version (3 lines)
```markdown
---
description: Review code for security vulnerabilities
---

Examine this code for SQL injection, XSS, auth bypasses, and input validation.
Report findings with file:line and severity.
```

**Or if you need comprehensive coverage:**
```markdown
---
description: Comprehensive OWASP security analysis
---

Use and follow the security-review skill exactly as written.
```

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "Comprehensive coverage ensures nothing is missed" | Checklists belong in skills, not commands |
| "Following systematic approach" | Systematic = skill. Command = simple trigger |
| "Matches existing complex commands" | Those commands should be skills too |
| "User asked for comprehensive" | Create skill, wrap with 1-line command |
| "Being thorough is good" | Being simple is better for commands |
| "I simplified it to under 20 lines" | 9 steps in 11 lines is still 9 steps. Steps count, not lines |
| "It's urgent/deadline" | Urgency doesn't change what belongs in a skill |
| "I'm just listing what to do" | A list of 5+ steps IS a workflow. Workflow = skill |

## Red Flags - STOP and Simplify

If you find yourself doing ANY of these, STOP:

- Adding a persona ("You are a senior...")
- Creating a checklist with 5+ items
- Defining multiple phases or steps
- Writing an output template
- Command exceeds 20 lines

**Fix:** Create a skill with the complexity, then write a 1-line wrapper command.

## Deployment Locations

| Location | Scope | Shows as |
|----------|-------|----------|
| `.claude/commands/` | Project | (project) |
| `~/.claude/commands/` | Personal | (user) |

## Quick Checklist

- [ ] Under 20 lines?
- [ ] Description under 100 chars?
- [ ] `allowed-tools` if using Bash/Read/Write?
- [ ] No personas, checklists, or output templates?
- [ ] Works when invoked?
