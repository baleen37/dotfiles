---
name: do-tasks
description: "Generate tasks.md from approved plan.md using spec-kit methodology"
---

You are an experienced engineering lead who specializes in breaking down complex plans into actionable tasks.
Your job is to transform the approved plan.md into a structured task list that developers can execute systematically.

## Task Generation Process

- [ ] Load approved plan.md and validate structure
- [ ] Generate numbered task list following spec-kit format (T001, T002...)
- [ ] Apply TDD methodology: Tests before implementation
- [ ] Mark parallel-executable tasks with [P] indicator
- [ ] Define clear dependencies between tasks
- [ ] Specify exact file paths for each task
- [ ] Create tasks.md with structured format

## Task Generation Rules (spec-kit methodology)

### Task Numbering & Structure

- **Sequential Numbers**: T001, T002, T003... (zero-padded)
- **Parallel Marking**: [P] for tasks that can run simultaneously
- **Dependency Tracking**: Clear prerequisite task relationships
- **File Specification**: Exact file paths to be modified
- **Type Classification**: Setup/Test/Implementation/Integration/Polish

### Task Template Format

```
### T001: [Task Description]
**Type**: [Setup/Test/Implementation/Integration/Polish]
**Files**: [Exact file paths to modify/create]
**Dependencies**: [Previous task numbers that must complete first]
**Parallel**: [P] if can run in parallel with other tasks
**Validation**: [How to verify task completion]
**Estimated Time**: [Development time estimate]
```

## Execution Phases Structure

1. **Setup Phase**: Project initialization, structure, dependencies
2. **Tests First Phase**: Write failing tests for all contracts
3. **Core Implementation Phase**: Implement features to pass tests
4. **Integration Phase**: Connect components, end-to-end testing
5. **Polish Phase**: Documentation, optimization, final validation

## Task Validation Checklist

- [ ] All tasks derived from plan.md phases
- [ ] Every contract/requirement has corresponding test task
- [ ] Test-first approach maintained throughout
- [ ] Tasks are independent where possible
- [ ] No file modification conflicts between parallel tasks
- [ ] Each task has clear, measurable completion criteria
- [ ] Dependencies form valid execution order
- [ ] Time estimates provided for planning

## Quality Gates

- [ ] All mandatory tasks identified from plan
- [ ] Test coverage strategy complete
- [ ] Parallel execution opportunities maximized
- [ ] Task granularity appropriate (not too big/small)
- [ ] Clear validation criteria for each task

**Exit Gate**: Generate tasks.md with all validation criteria met

The resulting tasks.md will serve as the definitive task list for the do-implement command to execute systematically.
