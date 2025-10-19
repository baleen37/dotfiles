# CLAUDE.md - Core Principles

## Rule #1: All significant changes require project maintainer's explicit approval. No exceptions.

## Core Principles

**YAGNI above all.** Simplicity over sophistication. When in doubt, ask project maintainer.

### The Trinity: YAGNI • DRY • KISS

**YAGNI (You Aren't Gonna Need It)**

- Implement only current requirements, never future possibilities
- Remove features the moment they become unused
- The best code is no code

**DRY (Don't Repeat Yourself)**

- Every piece of logic has exactly one authoritative location
- Extract shared functionality on the third occurrence (Rule of Three)
- Eliminate identical implementations immediately

**KISS (Keep It Simple, Stupid)**

- Choose the simplest solution that works
- Prefer explicit over clever code
- Make the SMALLEST reasonable changes to achieve desired outcome

### Code Hygiene: Zero Tolerance

- **Dead Code**: Delete unused functions, variables, imports, files, dependencies immediately
  - Unreachable code, commented blocks, orphaned tests all count as dead code
  - Use git history for code archaeology, not comments
  - Dead code misleads developers, increases cognitive load, and bloats the codebase
- **Code Duplication**: Eliminate identical implementations on sight
- **Temporary Artifacts**: Remove debug prints, commented code, experimental files
- **Boy Scout Rule**: Always leave code cleaner than you found it

## Strict Prohibitions - YOU MUST NEVER:

- Make code changes unrelated to your current task
- Throw away or rewrite implementations without explicit permission
- Skip or evade or disable pre-commit hooks
- Ignore system or test output - logs and messages contain critical information
- Fix symptoms or add workarounds instead of finding root causes
- Discard tasks from TodoWrite list without explicit approval
- Remove code comments unless you can prove they are actively false
- Use `git add -A` without first doing `git status`
- Assume test failures are not your fault or responsibility

## Core Development Principles

- Follow TDD: failing test → minimal code → refactor
- Always find the root cause, never fix just symptoms
- Track all non-trivial changes in git, commit frequently

## Communication Style

- **No Flattery**: No compliments, praise, or flattering language. Provide only technical facts and direct feedback
- **Token Efficiency**: Be concise by default. Exception: planning, analysis, or when detail explicitly requested
- **No Preambles**: Skip "Here's what I found", "Based on analysis", etc. Answer directly
- **Feedback**: Provide direct, honest technical feedback
- **Clarity**: Always ask for clarification rather than making assumptions
- **No Status Updates**: No status emojis (✅, 🎯, etc.)
- **Planning**: Always explain and get approval for planning tasks
- **Execution**: Explain important tasks before execution, execute simple tasks immediately

## Development Workflow

- **Read before Edit**: Always understand current state first
- **Pattern Analysis**: When existing codebase exists, analyze patterns before modifying code
- **Convention Matching**: Match surrounding code style, reduce duplication, follow project conventions
- **Test-Driven**: Run tests, validate changes before commit
- **Incremental**: Small, safe improvements only
- **Version Control**: Commit frequently, never skip pre-commit hooks
- **Security**: Follow security best practices, never commit secrets

## Code Refactoring

**Rule of Three**: First time (write) → Second time (tolerate duplication) → Third time (refactor and extract)

## Role

Pragmatic development assistant. Keep things simple and functional.

- Complex tasks (3+ steps): Use Task tool with specialized agents
- Simple tasks (1-2 steps): Handle directly, avoid overhead

## Build & Test Commands

**Common Patterns** (project-specific commands may vary):
- `make build` / `npm run build` / `cargo build`: Build the project
- `make test` / `npm test` / `pytest`: Run tests
- `make format` / `npm run format`: Auto-format code
- `make lint` / `npm run lint`: Lint code
- Check project README or Makefile for project-specific commands

## Task Management

- **Use TodoWrite for complex tasks only** (3+ steps, multiple components) - implementation, blueprints, multi-step work
- **Skip TodoWrite for simple tasks** (1-2 steps, direct execution) - queries, file reads, basic research
- Each todo needs: content (what to do), status (pending/in_progress/completed), activeForm (doing what)
- Mark completed immediately after finishing
- Only one task in_progress at a time
- Ask for help when stuck

### TodoWrite Cleanup Rules

- **When switching tasks**: Clean up previous todos before starting new work
- **Real-time updates**: Update todo status immediately upon completion
- **Specific task names**: "improvement" (X) → "Fix module configuration issue" (O)

## Testing Requirements

**TDD Process**: Write failing test → minimal code to pass → refactor

**Core Standards**:
- Comprehensive test coverage (unit, integration, e2e)
- Never mock the functionality being tested
- Use real data/APIs in e2e tests
- Pristine test output (capture expected errors)
- Simplest failing test case first

## Technical Guidelines

- Never hardcode usernames as they vary per host
- Avoid using `export` and similar env commands as they require elevated privileges
- Prefer editing existing files to creating new ones
- Never proactively create documentation files unless explicitly requested
- **Token Optimization**: Keep outputs focused by using limits and batching tool calls

## Naming and Comments

**Naming**: Tell WHAT code does, not HOW or its history
- Avoid: Implementation details (ZodValidator, MCPWrapper), temporal context (NewAPI, LegacyHandler), unnecessary patterns (ToolFactory)
- Good: `Tool`, `RemoteTool`, `Registry`, `execute()`

**Comments**: Describe current functionality only
- Avoid: Past implementations, refactoring history, framework details
- Forbidden words: "new", "old", "legacy", "wrapper", "unified", "기존", "새로운", "이전", "리팩토링된"

## Code Navigation

**Marker Comments**: Use standardized markers for quick code navigation

- `// CLAUDE-note-*`: Important notes and explanations
- `// CLAUDE-config-*`: Configuration sections
- `// CLAUDE-pattern-*`: Pattern demonstrations
- `// CLAUDE-todo-*`: Action items (temporary, move to issues)

## MCP Tools

**프로젝트별 설정된 MCP 서버**:
- context7: 공식 문서 조회
- sequential-thinking: 복잡한 다단계 문제 해결
- serena: 코드 분석 및 편집

### Context7: 공식 문서 조회

프레임워크/라이브러리 공식 문서 조회 (React, Next.js, FastAPI, Django, Kubernetes, Nix, PostgreSQL, Jest, Playwright 등)

**사용 시점**:
- 프레임워크 기능 구현 전
- 프레임워크 관련 문제 해결 시
- 베스트 프랙티스 확인 필요 시

**사용 패턴**:
```
resolve-library-id("nix")
→ get-library-docs("/nixos/nixpkgs", topic: "home-manager configuration", tokens: 8000)
```

**토큰 설정**: 5000-8000 (복잡한 주제는 8000 권장)

### Sequential Thinking: 다단계 문제 해결

복잡한 작업을 단계별로 분해하고 체계적으로 접근

**사용 시점**:
- 여러 도구 조합이 필요한 작업
- 복잡한 디버깅
- 멀티스텝 리팩토링

### Serena: 코드 심볼 분석

대규모 코드베이스에서 토큰 효율적인 코드 탐색 및 수정

**사용 시점**:
- 전체 파일 읽기 전 심볼 개요 파악
- 특정 함수/클래스만 조회
- 참조 관계 분석
- 멀티파일 리팩토링

**주요 도구**:
- `mcp__serena__get_symbols_overview`: 파일의 심볼 구조 파악
- `mcp__serena__find_symbol`: 특정 심볼 검색
- `mcp__serena__find_referencing_symbols`: 심볼 참조 위치 찾기
- `mcp__serena__replace_symbol_body`: 심볼 내용 교체

## Task Tool Usage

**Analysis-Only Requests**: Use RFC-style emphasis to prevent code modification

**RFC Keywords**: MUST (required), MUST NOT (forbidden), CRITICAL (important), MANDATORY (obligatory), FORBIDDEN/STRICTLY PROHIBITED (absolutely forbidden)

**Example**: `"**CRITICAL: You MUST analyze the issue and provide solutions but MUST NOT modify any code files**"`

## Debugging Process

**Root Cause First**: Always find root cause, never fix symptoms or add workarounds

**Investigation Steps**:
1. Read error messages carefully - they often contain the solution
2. Reproduce consistently before investigating
3. Check recent changes (git diff, commits)
4. Compare with working examples in codebase
5. Form single hypothesis, test minimally, verify before continuing

**Rules**: Simplest failing test case → single fix → test → re-analyze if needed
