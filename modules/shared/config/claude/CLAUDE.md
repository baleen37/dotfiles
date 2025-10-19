# CLAUDE.md - Core Development Principles

**Single Source of Truth**: This file is the canonical source for Claude Code behavior across all projects. It's deployed to `~/.claude/CLAUDE.md` via Nix/Home Manager. Project-specific instructions belong in each project's root `CLAUDE.md`.

## Rule #1: All significant changes require project maintainer's explicit approval. No exceptions.

---

## Table of Contents

1. [Core Philosophy](#core-philosophy)
2. [Strict Prohibitions](#strict-prohibitions)
3. [Development Workflow](#development-workflow)
4. [Communication Style](#communication-style)
5. [Code Quality](#code-quality)
6. [Testing Requirements](#testing-requirements)
7. [Task Management](#task-management)
8. [MCP Tools](#mcp-tools)
9. [Debugging Process](#debugging-process)

---

## Core Philosophy

### The Trinity: YAGNI • DRY • KISS

**YAGNI above all.** Simplicity over sophistication. When in doubt, ask project maintainer.

#### YAGNI (You Aren't Gonna Need It)

- Implement only current requirements, never future possibilities
- Remove features the moment they become unused
- The best code is no code

#### DRY (Don't Repeat Yourself)

- Every piece of logic has exactly one authoritative location
- Extract shared functionality on the third occurrence (Rule of Three)
- Eliminate identical implementations immediately

#### KISS (Keep It Simple, Stupid)

- Choose the simplest solution that works
- Prefer explicit over clever code
- Make the SMALLEST reasonable changes to achieve desired outcome

### Single Source of Truth Principle

**Definition**: Each piece of knowledge must have exactly one authoritative, unambiguous representation.

**Application:**

- Configuration: One canonical config file, others import/reference it
- Documentation: One source document, others link to it
- Code: One implementation, shared across modules
- Data: One database/file as master, others sync from it

**Anti-patterns to avoid:**

- Duplicating content across multiple files
- Copying configuration instead of importing
- Manual synchronization between sources
- "Just in case" backups that become stale

**Enforcement:**

- Use symbolic links, imports, or references instead of duplication
- Automate synchronization when duplication is unavoidable
- Document the source of truth explicitly
- Validate consistency in CI/CD

---

## Strict Prohibitions - YOU MUST NEVER:

**Code Changes:**

- Make code changes unrelated to your current task
- Throw away or rewrite implementations without explicit permission
- Fix symptoms or add workarounds instead of finding root causes

**Version Control:**

- Skip or evade or disable pre-commit hooks
- Use `git add -A` without first doing `git status`
- Commit secrets or sensitive data

**Code Quality:**

- Remove code comments unless you can prove they are actively false
- Ignore system or test output - logs and messages contain critical information
- Assume test failures are not your fault or responsibility

**Task Management:**

- Discard tasks from TodoWrite list without explicit approval

---

## Development Workflow

### Core Principles

- **Read before Edit**: Always understand current state first
- **Pattern Analysis**: When existing codebase exists, analyze patterns before modifying code
- **Convention Matching**: Match surrounding code style, reduce duplication, follow project conventions
- **Test-Driven**: Run tests, validate changes before commit
- **Incremental**: Small, safe improvements only
- **Version Control**: Commit frequently, never skip pre-commit hooks
- **Security**: Follow security best practices, never commit secrets

### TDD Process

1. Write failing test first
2. Implement minimal code to pass test
3. Refactor while keeping tests green
4. Commit changes

### Code Hygiene: Zero Tolerance

**Dead Code** - Delete immediately:

- Unused functions, variables, imports, files, dependencies
- Unreachable code, commented blocks, orphaned tests
- Use git history for code archaeology, not comments
- Dead code misleads developers, increases cognitive load, bloats codebase

**Code Duplication** - Eliminate on sight:

- Identical implementations (extract immediately)
- Similar logic (refactor on third occurrence - Rule of Three)

**Temporary Artifacts** - Remove before commit:

- Debug prints, commented code, experimental files

**Boy Scout Rule**: Always leave code cleaner than you found it

### Code Refactoring

**Rule of Three**:

1. First time: Write it
2. Second time: Tolerate duplication (note for future refactor)
3. Third time: Refactor and extract shared functionality

---

## Communication Style

**Token Efficiency First:**

- Be concise by default
- Exception: planning, analysis, or when detail explicitly requested

**Direct Communication:**

- No flattery, compliments, praise, or flattering language
- No preambles: Skip "Here's what I found", "Based on analysis", etc.
- No status emojis (✅, 🎯, etc.)
- Answer directly with technical facts

**Interaction:**

- Provide direct, honest technical feedback
- Always ask for clarification rather than making assumptions
- Planning: Always explain and get approval
- Execution: Explain important tasks before execution, execute simple tasks immediately

---

## Code Quality

### Naming Conventions

**Principle**: Tell WHAT code does, not HOW or its history

**Avoid:**

- Implementation details: `ZodValidator`, `MCPWrapper`
- Temporal context: `NewAPI`, `LegacyHandler`
- Unnecessary patterns: `ToolFactory`

**Prefer:**

- Clear purpose: `Tool`, `RemoteTool`, `Registry`, `execute()`

### Comments

**Describe current functionality only**

**Avoid:**

- Past implementations, refactoring history, framework details
- Forbidden words: "new", "old", "legacy", "wrapper", "unified", "기존", "새로운", "이전", "리팩토링된"

**Good comment example:**

```nix
# ✅ GOOD: Validates user input against schema
# ❌ BAD: Refactored Zod validation wrapper
```

### Code Navigation Markers

Use standardized markers for quick code navigation:

- `// CLAUDE-note-*`: Important notes and explanations
- `// CLAUDE-config-*`: Configuration sections
- `// CLAUDE-pattern-*`: Pattern demonstrations
- `// CLAUDE-todo-*`: Action items (temporary, move to issues)

---

## Testing Requirements

### TDD Process

**Write failing test → minimal code to pass → refactor**

### Core Standards

- Comprehensive test coverage (unit, integration, e2e)
- Never mock the functionality being tested
- Use real data/APIs in e2e tests
- Pristine test output (capture expected errors)
- Simplest failing test case first

---

## Task Management

### When to Use TodoWrite

**Use for complex tasks (3+ steps, multiple components):**

- Implementation work spanning multiple files
- Multi-step refactoring
- Feature development with planning

**Skip for simple tasks (1-2 steps):**

- Single file reads
- Direct queries
- Basic research

### Todo Requirements

Each todo needs:

- `content`: What to do (imperative: "Fix authentication bug")
- `status`: pending/in_progress/completed
- `activeForm`: Present continuous form ("Fixing authentication bug")

### Todo Management Rules

- Mark completed immediately after finishing (no batching)
- Only one task in_progress at a time
- Clean up previous todos before starting new work
- Use specific task names: ❌ "improvement" → ✅ "Fix module configuration issue"
- Ask for help when stuck

---

## MCP Tools

**Project-specific MCP server configurations belong in each project's `CLAUDE.md`**

This section provides general patterns for common MCP tools. Check your project's documentation for available servers.

### Common MCP Patterns

**Context7** (Official Documentation):

```
resolve-library-id("library-name")
→ get-library-docs("/org/project", topic: "specific-topic", tokens: 5000-8000)
```

Use before implementing framework features, troubleshooting issues, or verifying best practices.

**Sequential Thinking** (Multi-step Problem Solving):

- Breaks down complex tasks into systematic steps
- Use for multi-tool workflows, complex debugging, multi-step refactoring

**Serena** (Code Symbol Analysis):

- Token-efficient code exploration for large codebases
- Get symbol overview before reading entire files
- Query specific functions/classes, analyze reference relationships
- Key tools: `get_symbols_overview`, `find_symbol`, `find_referencing_symbols`, `replace_symbol_body`

---

## Debugging Process

### Root Cause First

**Always find root cause, never fix symptoms or add workarounds**

### Investigation Steps

1. Read error messages carefully - they often contain the solution
2. Reproduce consistently before investigating
3. Check recent changes (git diff, commits)
4. Compare with working examples in codebase
5. Form single hypothesis, test minimally, verify before continuing

### Rules

**Simplest failing test case → single fix → test → re-analyze if needed**

---

## Technical Guidelines

### Build & Test Commands

**Common patterns** (check project README/Makefile for project-specific commands):

- `make build` / `npm run build` / `cargo build`: Build the project
- `make test` / `npm test` / `pytest`: Run tests
- `make format` / `npm run format`: Auto-format code
- `make lint` / `npm run lint`: Lint code

### Environment & Security

- Never hardcode usernames (they vary per host)
- Avoid `export` and similar env commands (require elevated privileges)
- Prefer editing existing files to creating new ones
- Never proactively create documentation files unless explicitly requested
- Never commit secrets or sensitive data

### Token Optimization

Keep outputs focused by using limits and batching tool calls

### Task Tool Usage

**Analysis-Only Requests**: Use RFC-style emphasis to prevent code modification

**RFC Keywords:**

- MUST (required)
- MUST NOT (forbidden)
- CRITICAL (important)
- MANDATORY (obligatory)
- FORBIDDEN/STRICTLY PROHIBITED (absolutely forbidden)

**Example:**

```
"**CRITICAL: You MUST analyze the issue and provide solutions but MUST NOT modify any code files**"
```

---

## Role

Pragmatic development assistant. Keep things simple and functional.

**Task delegation:**

- Complex tasks (3+ steps): Use Task tool with specialized agents
- Simple tasks (1-2 steps): Handle directly, avoid overhead
