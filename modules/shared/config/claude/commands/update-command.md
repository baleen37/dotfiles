# Update Command

Unified workflow for creating new or updating existing Claude commands

## Overview

This command provides a systematic approach for managing Claude command files - whether creating new ones or updating existing ones. It automatically detects if a command exists and follows the appropriate workflow.

## Workflow Steps

### Step 1: Command Assessment

**Objective:** Determine if the command exists and what action is needed

**Prompt Template:**
```
I need to work with the '[command-name]' Claude command.

Purpose: [create new feature / fix bug / improve prompts / add functionality]

Please:
1. Check if modules/shared/config/claude/commands/[command-name].md exists
2. If it exists: Analyze current structure and identify improvement areas
3. If it doesn't exist: Verify this is a new command we should create
4. List any related commands that might be affected
5. Recommend the appropriate workflow (create new or update existing)
```

### Step 2: Planning Phase

**Objective:** Design the command structure or updates needed

**For New Commands - Prompt Template:**
```
Create a design for the new '[command-name]' command.

Purpose: [describe what this command will do]

Design should include:
1. Command structure following our standard pattern
2. Workflow steps with clear objectives
3. Prompt templates for each step
4. Integration points with existing commands
5. Example use cases

Ensure it follows established patterns from similar commands.
```

**For Existing Commands - Prompt Template:**
```
Design updates for the existing '[command-name]' command.

Current issues: [describe problems or needed improvements]

Update plan should include:
1. Sections to modify (with before/after comparison)
2. New features or steps to add
3. Outdated content to remove
4. Improved prompt templates
5. Impact on current users
```

### Step 3: Review and Approval

**Objective:** Validate the plan before implementation

**Prompt Template:**
```
Review the [creation/update] plan for '[command-name]' command:

1. Does it solve the stated problem/need?
2. Is it consistent with other commands?
3. Are the workflows logical and clear?
4. Will users understand how to use it?
5. Are there any risks or breaking changes?

Please approve or suggest modifications.
```

### Step 4: Implementation

**Objective:** Create or update the command file

**Prompt Template:**
```
[Create/Update] the '[command-name]' command file.

File path: modules/shared/config/claude/commands/[command-name].md

Approved plan:
[Include approved design from Step 3]

Ensure:
- Proper markdown formatting
- Clear and actionable prompts
- Consistent structure
- Helpful examples
- Complete documentation
```

### Step 5: Validation

**Objective:** Ensure the command meets quality standards

**Prompt Template:**
```
Validate the [new/updated] '[command-name]' command:

1. Test each workflow step with example scenarios
2. Verify all prompts are clear and complete
3. Check examples are realistic and helpful
4. Ensure consistency with related commands
5. Confirm it addresses the original need

Report any issues or confirm readiness.
```

## Quick Operations

### Quick Fix
For minor typos or clarifications:
```
Quick fix for '[command-name]' command:
- Issue: [typo/clarification needed]
- Fix: [specific change]

Apply this minor update to modules/shared/config/claude/commands/[command-name].md
```

### Quick Create
For simple, single-purpose commands:
```
Quick create '[command-name]' command:
- Purpose: [single clear purpose]
- Workflow: [simple 2-3 step process]

Create a streamlined command file following minimal structure.
```

## Common Patterns

### Creating New Commands

**Pattern 1: Multi-Step Workflow Command**
```
1. Analysis/Discovery phase
2. Planning/Design phase  
3. Review/Approval phase
4. Implementation phase
5. Validation/Testing phase
```

**Pattern 2: Single-Action Command**
```
1. Setup/Preparation
2. Execute action
3. Verify results
```

### Updating Existing Commands

**Pattern 1: Adding New Features**
- Insert new steps in logical order
- Update overview to mention new capability
- Add examples demonstrating new feature
- Ensure backward compatibility

**Pattern 2: Improving Clarity**
- Rewrite vague prompts with specific instructions
- Add missing context or requirements
- Include concrete examples
- Clarify expected outputs

## Decision Tree

```
Need to work with a command?
├─ Does it exist?
│  ├─ Yes → Update workflow
│  │  ├─ Major changes? → Full update process
│  │  └─ Minor fixes? → Quick fix
│  └─ No → Create workflow
│     ├─ Complex command? → Full creation process
│     └─ Simple command? → Quick create
```

## Quality Standards

### Required Elements
- Clear, descriptive title
- Brief overview explaining purpose
- Step-by-step workflow
- Objective for each step
- Prompt template for each step

### Best Practices
- Use imperative mood ("Create", "Update", "Verify")
- Keep prompts self-contained
- Include realistic examples
- Maintain consistent formatting
- Follow established patterns

### Avoid
- Vague or ambiguous instructions
- Missing context in prompts
- Inconsistent terminology
- Breaking existing workflows
- Over-engineering simple tasks

## Examples

### Example 1: Creating a New Command
```
User: "I need a command for reviewing security vulnerabilities"
Step 1: Check - security-review.md doesn't exist
Step 2: Design - Create multi-step security analysis workflow
Step 3: Review - Approve design with security checklist
Step 4: Create - Generate security-review.md
Step 5: Validate - Test with example vulnerability
```

### Example 2: Updating Existing Command
```
User: "The plan command needs better prompt examples"
Step 1: Check - plan.md exists, prompts are too generic
Step 2: Design - Enhance prompts with specific examples
Step 3: Review - Compare before/after versions
Step 4: Update - Modify plan.md with improvements
Step 5: Validate - Test improved prompts
```

## Related Commands

- **plan:** For planning complex implementations
- **fix-pr:** For addressing PR feedback
- **update-docs:** For updating documentation
- **session-summary:** For summarizing work done

## Important Notes

- Always check if a command exists before creating a new one
- Consider merging similar commands rather than creating duplicates
- Test commands with real scenarios before finalizing
- Document breaking changes prominently
- Keep commands focused on single, clear purposes
- Remember that simpler is often better
