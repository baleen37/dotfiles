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

**Todo Tracking:**
- Create initial todos for the selected workflow
- Mark assessment task as complete
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

**Todo Tracking:**
- Break down design into subtasks
- Track each design element completion
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

**Todo Tracking:**
- Create todos for each section to modify
- Track progress on design elements
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

**Git Workflow:**
- Create feature branch: `git checkout -b feat/update-[command-name]`
- Stage work-in-progress if needed
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

**Todo Tracking:**
- Mark planning todos as complete
- Create implementation todos

**Git Workflow:**
- Commit changes: `git add -A && git commit -m "feat(claude): [action] [command-name] 명령어"`
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

**Testing Process:**
1. Copy the command to a test session
2. Run through each workflow step with real inputs
3. Verify prompts produce expected results
4. Check edge cases (missing files, errors, etc.)

**Todo Tracking:**
- Mark all implementation todos as complete
- Create follow-up tasks if issues found

**Git Workflow:**
- Final commit if changes made during validation
- Ready for PR creation if needed
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

**Step 1: Assessment**
Prompt: "I need to work with the 'security-review' Claude command.
Purpose: create new feature
Please check if it exists and recommend workflow."

Result: "security-review.md doesn't exist. Recommend creating new command."
Todos created: [Assessment ✓, Design, Review, Implementation, Validation]

**Step 2: Design**
Prompt: "Create a design for the new 'security-review' command.
Purpose: Systematic security vulnerability review
Include workflow steps and prompt templates."

Result: Multi-step security workflow designed
Todos: [Assessment ✓, Design ✓, Review, Implementation, Validation]

**Step 3: Review**
Git: `git checkout -b feat/add-security-review`
Prompt: "Review the security-review command plan. Does it cover OWASP top 10?"

**Step 4: Implementation**
Create security-review.md with approved design
Git: `git add . && git commit -m "feat(claude): security-review 명령어 추가"`

**Step 5: Validation**
Test: Run security-review on sample vulnerable code
Confirm: All vulnerabilities detected as expected
```

### Example 2: Updating Existing Command
```
User: "The plan command needs better prompt examples"

**Step 1: Assessment**
Prompt: "I need to work with the 'plan' Claude command.
Purpose: improve prompts
Analyze current structure and identify improvements."

Result: "plan.md exists. Current prompts too generic, need concrete examples."
Todos: [Analyze current ✓, Design improvements, Review changes, Update file, Test]

**Step 2: Design Updates**
Prompt: "Design updates for 'plan' command.
Issues: Prompts lack concrete examples
Show before/after comparisons."

Todos: [Analyze ✓, Design improvements (in progress), Review, Update, Test]

**Step 3: Review**
Git: `git checkout -b fix/improve-plan-prompts`
Compare proposed changes, get approval

**Step 4: Update**
Modify plan.md with enhanced prompts
Git: `git add . && git commit -m "fix(claude): plan 명령어 프롬프트 개선"`
Todos: [Analyze ✓, Design ✓, Review ✓, Update ✓, Test]

**Step 5: Validate**
Test: Use updated plan command on real project
Verify: Prompts now generate better results
Todos: [All complete ✓]
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
