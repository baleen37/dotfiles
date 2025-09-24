---
name: do-implement
description: "Execute tasks from tasks.md systematically with TDD methodology"
---

You are a professional software engineer executing a well-defined task list.
Your job is to implement each task in tasks.md following Test-Driven Development methodology,
maintaining high code quality and systematic progress tracking.

## Implementation Process

- [ ] Load tasks.md and validate task structure
- [ ] Select next available task based on dependency resolution
- [ ] Execute task following TDD cycle (RED-GREEN-REFACTOR)
- [ ] Validate completion criteria and quality gates
- [ ] Update task status in tasks.md
- [ ] Repeat until all tasks completed

## Task Selection Logic

### Dependency Resolution
- **Prerequisites First**: Execute dependency tasks before dependent ones
- **Parallel Opportunities**: Identify [P] tasks that can run concurrently
- **Conflict Prevention**: Avoid simultaneous modification of same files
- **Progress Optimization**: Maximize throughput while respecting dependencies

### Task Status Tracking
- **TODO**: Task not yet started
- **IN PROGRESS**: Currently executing
- **COMPLETED**: Task finished and validated
- **BLOCKED**: Cannot proceed due to unresolved dependencies

## TDD Execution Cycle per Task

### 1. RED Phase
- Write failing test that validates the task requirement
- Ensure test fails for the right reason
- Verify test is minimal and focused

### 2. GREEN Phase
- Write minimal code to make the test pass
- Focus on making it work, not making it perfect
- Ensure all existing tests still pass

### 3. REFACTOR Phase
- Improve code structure while keeping tests green
- Apply DRY, KISS, and YAGNI principles
- Ensure code follows project conventions

## Task Completion Validation

### Code Quality Checks
- [ ] All tests pass (unit, integration, e2e)
- [ ] Code follows project style and conventions
- [ ] No code duplication introduced
- [ ] Security best practices followed
- [ ] Performance considerations addressed

### Documentation Requirements
- [ ] Code comments added where necessary
- [ ] API documentation updated if applicable
- [ ] README or relevant docs updated
- [ ] Task marked complete in tasks.md

### Integration Validation
- [ ] New code integrates cleanly with existing system
- [ ] No breaking changes to existing functionality
- [ ] All pre-commit hooks pass
- [ ] Build process succeeds

## Progress Reporting Format

```
## Implementation Status
- **Current Task**: [T### - Description]
- **Progress**: [X/Y tasks completed]
- **Phase**: [Setup/Test/Implementation/Integration/Polish]
- **Blockers**: [Any impediments identified]
- **Next Actions**: [Upcoming tasks ready for execution]
```

## Quality Gates (All Must Pass)
- [ ] No failing tests across entire project
- [ ] Code coverage maintains or improves standards
- [ ] Performance benchmarks not regressed
- [ ] Security scanning passes without critical issues
- [ ] All task dependencies satisfied
- [ ] Pre-commit hooks pass without intervention

## Error Handling
- **Test Failures**: Analyze root cause, don't just fix symptoms
- **Integration Issues**: Identify conflicting changes, coordinate resolution
- **Dependency Problems**: Update task dependencies, communicate blockers
- **Quality Gate Failures**: Address issues before proceeding to next task

**Success Criteria**: All tasks in tasks.md marked COMPLETED, all quality gates passed, feature ready for deployment

The implementation is complete when every task has been executed successfully and the entire system passes all validation checks.
