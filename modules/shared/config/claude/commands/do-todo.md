---
name: do-todo
description: "Execute todos systematically with proper planning, implementation, and tracking"
tools: [TodoWrite, Task, Read, Write, Bash, Edit]
---

# /do-todo - Systematic Todo Execution

**Purpose**: Open todo.md and methodically work through unchecked tasks with proper planning, implementation, testing, and documentation.

## Process

### 1. Task Selection
- Open `todo.md` and find the first unchecked task
- Select one task to focus on completely

### 2. Planning Phase
- Carefully plan how to implement the selected task
- Document the plan as a detailed comment (like a GitHub issue)
- Break down complex tasks into smaller steps if needed

### 3. Implementation Phase
- Create a new branch for the work
- Write robust, well-documented code
- Include comprehensive tests and debug logging
- Verify all tests pass before proceeding

### 4. Completion Phase
- Commit changes with clear, descriptive messages
- Open pull request referencing the planning documentation
- Mark the completed item as checked in `todo.md`

### 5. Move to Next Task
- Return to step 1 and select the next unchecked task
- Repeat the cycle systematically

## Implementation Standards

### Code Quality
- **Robust implementation**: Handle edge cases and error conditions
- **Clear documentation**: Code comments and README updates
- **Consistent style**: Follow project conventions and patterns

### Testing Requirements
- **Comprehensive tests**: Unit tests for all new functionality
- **Debug logging**: Proper logging for troubleshooting
- **Test verification**: Ensure all tests pass before committing

### Documentation
- **Planning documentation**: Clear task breakdown and approach
- **Commit messages**: Descriptive and linked to planning docs
- **Progress tracking**: Keep `todo.md` updated with completion status

## Example Workflow

```bash
/do-todo
```

**Process Example**:
1. Opens `todo.md`, finds: "- [ ] Add user authentication system"
2. Plans: "Implement JWT-based auth with login/logout endpoints"
3. Creates branch: `feature/user-authentication`
4. Implements: User model, auth middleware, login routes, tests
5. Commits: "Add JWT authentication system - refs #planning-doc"
6. Updates: `todo.md` marks "- [x] Add user authentication system"
7. Moves to next unchecked item

## Key Principles

### Systematic Progression
- One task at a time, completed fully before moving on
- Proper planning prevents rushed implementations
- Each task gets appropriate attention and quality

### Quality Assurance
- Tests must pass before marking tasks complete
- Code review standards applied to all implementations
- Documentation maintained throughout the process

### Progress Tracking
- `todo.md` serves as single source of truth for project status
- Clear completion markers show what's done vs remaining
- Planning documentation provides context for future reference

## Integration with Other Commands

```bash
/plan → plan.md → extract todos → todo.md
/do-todo → systematic execution of todo items
```

The command works best when `todo.md` contains well-defined, actionable tasks from the planning phase.
