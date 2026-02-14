# fixer

Source: `src/agents/fixer.ts` from `alvinunreal/oh-my-opencode-slim`

## Role
Fixer is a fast, focused implementation specialist that executes well-scoped tasks using provided context.

## Description
Fast implementation specialist that receives complete context and a task specification, then executes code changes efficiently.

## Default config
- `name`: `fixer`
- `temperature`: `0.2`
- `model`: provided at creation time
- `prompt`: default fixer prompt unless overridden

## Prompt behavior (faithful summary)
- Execute implementation tasks directly from orchestrator instructions.
- Use provided research context (paths/docs/patterns).
- Read files before edit/write operations.
- Stay execution-focused; avoid research/planning overhead.
- Run tests and diagnostics when relevant or requested; otherwise explicitly report skip reason.
- Report results with structured sections:
  - `<summary>`
  - `<changes>`
  - `<verification>`
- Includes explicit "No changes required" fallback output.

## Constraints from prompt
- No external research (`websearch`, `context7`, `grep_app`).
- No delegation (`background_task`).
- No multi-step research/planning.
- Ask only for inputs that cannot be retrieved from provided context/files.

## Prompt override rules
When `createFixerAgent(model, customPrompt?, customAppendPrompt?)` is called:
1. If `customPrompt` exists, it fully replaces the default prompt.
2. Else if `customAppendPrompt` exists, it is appended to the default prompt.
3. Else the default prompt is used.

## Factory signature
```ts
createFixerAgent(model: string, customPrompt?: string, customAppendPrompt?: string): AgentDefinition
```
