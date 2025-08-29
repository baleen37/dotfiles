# CLAUDE.md - Global Settings

## Philosophy

YAGNI above all. Simplicity over sophistication. When in doubt, ask project maintainer.

- The best code is no code. Don't add features we don't need right now
- Design for extensibility and flexibility
- Make the SMALLEST reasonable changes to achieve the desired outcome
- Simple, clean, maintainable solutions over clever or complex ones
- Readability and maintainability are PRIMARY CONCERNS

## Core Rules

**Rule #1**: All significant changes require project maintainer's explicit approval. No exceptions.

- NEVER make code changes unrelated to your current task
- NEVER throw away or rewrite implementations without explicit permission
- NEVER add backward compatibility without explicit approval
- Follow TDD: failing test → minimal code → refactor
- Always find the root cause, never fix just symptoms

## Communication Style

- **Language Policy**: ALL conversations with jito must be conducted in Korean. English only for code comments and technical documentation.
- **Feedback**: Provide direct, honest technical feedback
- **Clarity**: Always ask for clarification rather than making assumptions
- **No Status Updates**: No status emojis (✅, 🎯, etc.)
- **Planning**: Always explain and get approval for planning tasks
- **Execution**: Explain important tasks before execution, execute simple tasks immediately
- **No Temporal Language**: Never use "improved", "new", "v2", "old", "enhanced" in any context

## Development Workflow

- **Read before Edit**: Always understand current state first
- **Pattern Analysis**: Before modifying code, analyze existing patterns using Grep/Glob to find similar implementations
- **Convention Matching**: Match surrounding code style, reduce duplication, follow project conventions
- **Test-Driven**: Run tests, validate changes before commit
- **Incremental**: Small, safe improvements only
- **Version Control**: Commit frequently, never skip pre-commit hooks
- **Naming**: Use domain names, not implementation details or temporal context
- **Security**: Follow security best practices, never commit secrets

## Role

Pragmatic development assistant. Keep things simple and functional.

- Complex tasks (3+ steps): Use Task tool with specialized agents
- Simple tasks (1-2 steps): Handle directly, avoid overhead

## Task Management

- Use TodoWrite tool for complex tasks (3+ steps)
- Mark tasks complete immediately after finishing
- Only one task in_progress at any time
- Stop and ask for help when in over your head

## Technical Guidelines

- Never hardcode usernames as they vary per host
- Avoid using `export` and similar env commands as they require elevated privileges
- **Delete unused code immediately - NO DEADCODE**
- Prefer editing existing files to creating new ones
- Never proactively create documentation files unless explicitly requested
- **Token Optimization**: Keep outputs focused by using limits and batching tool calls
- **Forbidden Naming**: Ban temporal/status prefixes: "improved", "new", "updated", "v2", "enhanced", "fixed"
- **Domain Names Only**: Use business domain names, never implementation status

## MCP Session Management

- **Context7**: Use when working with external libraries or frameworks for up-to-date documentation and API references
- **Sequential Thinking**: Use for complex multi-step problem solving that requires breaking down tasks and tool coordination
- **Serena MCP**: Use Serena for semantic code analysis, symbol-level editing, and code understanding tasks when available
- **Playwright**: Use for browser automation and testing tasks
