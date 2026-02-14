# explorer

Source: `src/agents/explorer.ts` from `alvinunreal/oh-my-opencode-slim`

## Role
Explorer is a fast codebase navigation specialist for answering discovery questions like "Where is X?".

## Description
Fast codebase search and pattern matching for finding files, locating code patterns, and answering "where is X?" questions.

## Default config
- `name`: `explorer`
- `temperature`: `0.1`
- `model`: provided at creation time
- `prompt`: default explorer prompt unless overridden

## Prompt behavior (faithful summary)
- Focus on quick contextual search across the codebase.
- Tool guidance:
  - `grep` for text/regex patterns.
  - `glob` for filename/extension discovery.
  - `ast_grep_search` for structural AST patterns.
- Recommend parallel searches when useful.
- Return paths and relevant snippets with line numbers.
- Output shape requested by prompt:
  - `<results>`
  - `<files>` entries
  - `<answer>` concise conclusion
- Constraint: read-only search and reporting, no modifications.

## Prompt override rules
When `createExplorerAgent(model, customPrompt?, customAppendPrompt?)` is called:
1. If `customPrompt` exists, it fully replaces the default prompt.
2. Else if `customAppendPrompt` exists, it is appended to the default prompt.
3. Else the default prompt is used.

## Factory signature
```ts
createExplorerAgent(model: string, customPrompt?: string, customAppendPrompt?: string): AgentDefinition
```
