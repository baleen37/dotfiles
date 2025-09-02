---
name: save-plan
description: "Simple idea → structured plan.md file creation"
tools: [Write, TodoWrite]
---

# /save-plan - Quick Plan Generation

**Purpose**: Transform simple ideas or requirements into a structured plan.md file ready for execution.

## Process

1. **Capture**: Take user's idea or requirements
2. **Structure**: Break down into clear, actionable steps  
3. **Write**: Generate plan.md file in current directory
4. **Ready**: File ready for `/do-plan` execution

## Usage

```bash
/save-plan "build user authentication system"
→ Creates plan.md with structured implementation steps

/save-plan "fix login bug with email validation"  
→ Creates plan.md with debugging and fix steps

/save-plan "add rate limiting to API endpoints"
→ Creates plan.md with feature implementation plan
```

## Output Format

**File**: `plan.md` in current working directory

**Structure**:
```markdown
# [Project/Feature Name]

## Overview
Brief description and scope

## Steps
1. [Clear, actionable step]
2. [Next logical step]
3. [Continuation...]

## Success Criteria
- [Measurable outcome]
- [Verification method]
```

## Key Principles

- **Simple → Structured**: Transform vague ideas into clear steps
- **Actionable**: Each step should be implementable
- **Sequential**: Logical order of execution
- **Complete**: Nothing missing for execution

## Integration

- **Input**: Simple idea or requirement description
- **Output**: Structured plan.md file  
- **Next Step**: Use `/do-plan` to execute the plan
- **Compatible**: Works with existing TodoWrite ecosystem

## Examples

### Simple Bug Fix
```
Input: "login form crashes when email has spaces"
Output: plan.md with debugging, reproduction, and fix steps
```

### Feature Implementation  
```
Input: "add dark mode toggle"
Output: plan.md with UI, state management, and styling steps
```

### System Enhancement
```
Input: "improve API performance"
Output: plan.md with profiling, optimization, and testing steps
```
