# Development Plan

This document outlines a comprehensive, structured development workflow designed for quality, consistency, and maintainability. Each phase builds upon the previous one and must be completed in sequence.

<rules>
**CRITICAL: WORKFLOW MANDATE**
1. **SEQUENTIAL EXECUTION:** You **MUST** follow the phases in the exact order presented: 1 → 2 → 3 → 4 → 5.
2. **PHASE COMPLETION:** You **MUST** complete all actions and checkpoints within a phase before moving to the next.
3. **USER APPROVAL:** Critical checkpoints, especially the development plan (Phase 3), require explicit user approval before proceeding.
4. **NO SHORTCUTS:** Never bypass verification steps or quality checks. Fix issues rather than working around them.
5. **DOCUMENTATION FIRST:** Always understand existing patterns before creating new ones.
</rules>

---

## Phase 1: Understand the Request 🎯

### Actions
- [ ] **Clarify Requirements:** Extract the core objective, success criteria, and all constraints
- [ ] **Identify Scope:** Determine what's in scope vs. out of scope
- [ ] **Ask Clarifying Questions:** If anything is ambiguous, ask specific questions
- [ ] **Document Assumptions:** List any assumptions you're making about the requirements

### Tools to Use
- Direct dialogue with user
- Review of related issues, tickets, or documentation

### Checkpoint ✅
**Confirm your understanding with the user. Proceed only after explicit confirmation.**

---

## Phase 2: Analyze the Codebase 🔍

### Actions
- [ ] **Discover Project Structure:** Use `Glob` to understand directory layout and file organization
- [ ] **Find Related Code:** Use `Grep` to locate similar implementations or related functionality
- [ ] **Read Core Files:** Use `Read` to examine key configuration files, main modules, and tests
- [ ] **Understand History:** Use `git log` to see recent changes and understand evolution
- [ ] **Identify Patterns:** Document existing coding conventions, naming patterns, and architectural decisions
- [ ] **Map Dependencies:** Understand how different parts of the system interact

### Tools to Use
- `Glob` for file discovery
- `Grep` for content search
- `Read` for detailed file examination
- `Bash` for git history analysis
- `Task` for complex searches

### Quality Checks
- [ ] Do I understand the existing architecture?
- [ ] Have I identified all relevant files and dependencies?
- [ ] Do I know the project's conventions and patterns?
- [ ] Have I found similar implementations to learn from?

### Checkpoint ✅
**You have comprehensive understanding of relevant code, its context, patterns, and conventions.**

---

## Phase 3: Formulate & Propose Development Plan 📋

### Actions
- [ ] **Create Implementation Strategy:** Break down the request into logical, sequential steps
- [ ] **Identify File Changes:** List specific files to create, modify, or delete
- [ ] **Define Verification Plan:** Specify how each change will be tested and verified
- [ ] **Consider Edge Cases:** Identify potential risks, edge cases, and failure scenarios
- [ ] **Plan for Rollback:** Consider how to undo changes if something goes wrong
- [ ] **Estimate Impact:** Assess the scope of changes and potential breaking changes

### Plan Structure
```markdown
## Implementation Plan

### Overview
[Brief description of the approach]

### Steps
1. **Step Name**
   - Files to modify: `path/to/file.ext`
   - Changes: [specific description]
   - Tests: [how to verify]
   - Risks: [potential issues]

2. **Step Name**
   - ...

### Verification Strategy
- [ ] Unit tests for new functionality
- [ ] Integration tests for system interaction
- [ ] Manual testing scenarios
- [ ] Performance considerations
- [ ] Security implications

### Rollback Plan
[How to undo if things go wrong]
```

### Checkpoint ✅
**Present the detailed plan to the user and obtain explicit approval. Do not proceed without it.**

---

## Phase 4: Implement and Verify 🛠️

This phase follows a strict Test-Driven Development (TDD) cycle for each implementation step:

### 4.1. PREPARE
- [ ] **Update Todo List:** Use `TodoWrite` to track current implementation step
- [ ] **Backup Current State:** Ensure git working directory is clean
- [ ] **Verify Environment:** Run existing tests to ensure starting from good state

### 4.2. TEST-FIRST (TDD Red Phase)
- [ ] **Write Failing Test:** Create test that validates the desired functionality
- [ ] **Run Test:** Confirm it fails for the right reasons
- [ ] **Commit Test:** `git add` and `git commit` the failing test

### 4.3. IMPLEMENT (TDD Green Phase)
- [ ] **Write Minimal Code:** Implement just enough to make the test pass
- [ ] **Follow Conventions:** Match existing code style, patterns, and conventions
- [ ] **Run Test:** Verify the test now passes
- [ ] **Run All Tests:** Ensure no regressions

### 4.4. REFACTOR (TDD Blue Phase)
- [ ] **Improve Code Quality:** Clean up implementation while keeping tests green
- [ ] **Remove Duplication:** Apply DRY principles where appropriate
- [ ] **Enhance Readability:** Improve naming, structure, and documentation
- [ ] **Run All Tests:** Verify everything still works

### 4.5. VERIFY COMPREHENSIVELY
- [ ] **Run Full Test Suite:** Execute all project tests
- [ ] **Run Linter:** Fix any style or quality issues
- [ ] **Run Type Checker:** Resolve any type errors
- [ ] **Check Documentation:** Update relevant docs if needed
- [ ] **Test Edge Cases:** Manually verify edge cases and error conditions

### 4.6. COMMIT PROGRESS
- [ ] **Review Changes:** Use `git diff` to review all modifications
- [ ] **Stage Changes:** `git add` relevant files
- [ ] **Write Clear Message:** Follow conventional commit format
- [ ] **Commit:** `git commit` with descriptive message

### 4.7. ITERATE
- [ ] **Check Plan Progress:** Update `TodoWrite` with completed step
- [ ] **Continue or Proceed:** If plan incomplete, return to step 4.1 for next step
- [ ] **Otherwise:** Proceed to Phase 5

### Quality Gates
Each step must pass:
- [ ] All tests pass (new and existing)
- [ ] Linter passes with no errors
- [ ] Type checker passes (if applicable)
- [ ] Code follows project conventions
- [ ] No regression in functionality
- [ ] Performance is acceptable
- [ ] Security considerations addressed

---

## Phase 5: Finalize and Commit 🚀

### Actions
- [ ] **Final Review:** Comprehensive review of all changes using `git status` and `git diff`
- [ ] **Run Complete Test Suite:** Final verification that everything works
- [ ] **Update Documentation:** Ensure any relevant docs are updated
- [ ] **Clean Up:** Remove any temporary files or debugging code
- [ ] **Stage All Changes:** `git add` all related changes
- [ ] **Write Comprehensive Commit Message:** Clear, descriptive message summarizing the entire change
- [ ] **Final Commit:** `git commit` with the complete changeset

### Commit Message Format
```
type(scope): brief description

Detailed explanation of what was implemented and why.
Include any breaking changes, migration notes, or
important implementation details.

- Key feature 1
- Key feature 2
- Any breaking changes

Fixes #issue-number (if applicable)
```

### Final Verification
- [ ] Working directory is clean (`git status`)
- [ ] All changes are committed
- [ ] Tests pass
- [ ] Documentation is up to date
- [ ] No temporary or debug code remains

### Checkpoint ✅
**The work is successfully committed, all quality gates pass, and the working directory is clean.**

---

## Troubleshooting Common Issues

### Test Failures
1. **Investigate Root Cause:** Never ignore test failures
2. **Fix the Issue:** Address the underlying problem, don't modify tests to pass
3. **Verify Fix:** Ensure the fix doesn't break other functionality

### Linter/Type Errors
1. **Understand the Error:** Read error messages carefully
2. **Fix Properly:** Address the actual issue, don't suppress warnings
3. **Learn from Patterns:** Use errors to improve code quality

### Build/Deployment Issues
1. **Check Dependencies:** Verify all required dependencies are available
2. **Environment Consistency:** Ensure development matches target environment
3. **Rollback Plan:** Be prepared to revert if deployment fails

### Performance Issues
1. **Measure First:** Get baseline metrics before optimizing
2. **Profile Code:** Identify actual bottlenecks, not assumed ones
3. **Test Improvements:** Verify optimizations actually help

---

## Best Practices Summary

### Code Quality
- Follow existing conventions religiously
- Write self-documenting code with clear names
- Prefer simple, readable solutions over clever ones
- Test thoroughly, including edge cases

### Git Workflow
- Commit frequently with clear messages
- Keep commits focused and atomic
- Never commit broken code
- Use meaningful branch names

### Communication
- Ask questions when uncertain
- Document important decisions
- Update relevant stakeholders on progress
- Be honest about blockers or delays

### Continuous Improvement
- Learn from each implementation
- Update this plan based on experience
- Share knowledge with team members
- Celebrate successful deliveries
