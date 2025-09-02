---
name: do-plan
description: "Think hard: execute plan.md systematically with meticulous TodoWrite tracking"
tools: [TodoWrite, Task, Read, Write, Edit]
---

# /do-plan - Methodical Plan Execution

**Purpose**: Think hard about each step. Execute plan.md with surgical precision, checking off each task methodically.

## Execution Philosophy

**Think Hard → Act Deliberately → Verify Thoroughly**

1. **Read plan.md completely** - understand the full scope
2. **Convert to TodoWrite checklist** - every step becomes a trackable task  
3. **Execute one-by-one** - mark in_progress → implement → mark completed
4. **Never skip ahead** - complete current task fully before next
5. **Validate each step** - test, verify, document before moving on

## Process

### Phase 1: Plan Analysis & Setup
```bash
# 1. Read plan.md file
# 2. Parse into discrete, actionable steps
# 3. Convert each step to TodoWrite task
# 4. Show complete checklist for user approval
# 5. Begin systematic execution
```

### Phase 2: Methodical Execution  
```bash
# For each TodoWrite task:
# 1. Mark as in_progress
# 2. Complexity Check: Is this step manageable? If too big → break down
# 3. Integration Check: How does this connect to previous work?
# 4. Think hard about implementation approach
# 5. Execute with appropriate tools/agents
# 6. Code Integration: Ensure new code connects with existing code
# 7. Verify completion thoroughly (functionality + integration)
# 8. Mark as completed
# 9. Move to next task
```

### Phase 3: Quality Validation
```bash
# Quality Checks (Before Next Step):
# - Run tests to ensure no regressions
# - Verify new code integrates with existing code
# - Check functionality works as expected

# Continuous Validation:
# - Test after each completed step
# - Document blockers immediately  
# - Ask for help when stuck
# - Never assume success without verification
```

## Methodical Execution Example

```
Input: plan.md with 4 steps
↓
TodoWrite Conversion:
□ Step 1: Setup project structure  
□ Step 2: Implement core functionality
□ Step 3: Add tests and validation
□ Step 4: Deploy and configure

Execution Flow:
□ → ⚠️  → ✅ (Step 1: Setup project structure)
     ↓ Test & verify
□ → ⚠️  → ✅ (Step 2: Implement core functionality)  
     ↓ Test & verify
□ → ⚠️  → ✅ (Step 3: Add tests and validation)
     ↓ Test & verify  
□ → ⚠️  → ✅ (Step 4: Deploy and configure)
     ↓ Final verification
```

## Required plan.md Structure
```markdown
# [Title]

## Steps
1. [Clear, actionable step]
2. [Next logical step]
3. [Continue...]

## Success Criteria (Optional)
- [Measurable outcome]
- [Verification method]
```

## Execution Rules

**Never Skip Steps:**
- Complete current task 100% before next
- If blocked → document blocker → ask for help
- If unclear → think harder → break down further

**Quality Checks (Before Next Step):**
- **Code Quality**: Tests pass, no critical issues
- **Integration**: New code connects with existing code

**Always Verify:**
- Run tests after each step
- Check functionality works
- Validate against success criteria
- Document what was actually completed

**Think Hard Methodology:**
- Read the step carefully
- Understand what "done" means  
- **Check complexity jump**: Is this step too big? Break it down further
- **Verify integration**: Does this build on previous work? No orphaned code
- Choose appropriate implementation approach
- Execute deliberately, not hastily
- **Integration check**: Connect with existing code, don't create islands
- Verify thoroughly before marking complete

## Integration

- **Input**: Existing plan.md file (use `/save-plan` to generate)
- **Process**: Think hard → execute methodically → verify thoroughly
- **Output**: Fully implemented solution with meticulous tracking
- **Philosophy**: Slow and steady wins the race
