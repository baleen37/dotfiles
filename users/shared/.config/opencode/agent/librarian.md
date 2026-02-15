# librarian

Source: `src/agents/librarian.ts` from `alvinunreal/oh-my-opencode-slim`

## Role
Librarian is a research specialist for codebases and external documentation.

## Description
External documentation and library research agent used for official docs lookup, GitHub examples, and understanding library internals.

## Default config
- `name`: `librarian`
- `temperature`: `0.1`
- `model`: provided at creation time
- `prompt`: default librarian prompt unless overridden

## Prompt behavior (faithful summary)
- Perform multi-repository analysis and library research.
- Find official documentation and implementation examples.
- Provide evidence-backed answers with source links.
- Quote relevant snippets and separate official guidance from community patterns.

## Tools mentioned in prompt
- `context7` for official documentation lookup
- `grep_app` for searching GitHub repositories
- `websearch` for general documentation search

## Prompt override rules
When `createLibrarianAgent(model, customPrompt?, customAppendPrompt?)` is called:
1. If `customPrompt` exists, it fully replaces the default prompt.
2. Else if `customAppendPrompt` exists, it is appended to the default prompt.
3. Else the default prompt is used.

## Factory signature
```ts
createLibrarianAgent(model: string, customPrompt?: string, customAppendPrompt?: string): AgentDefinition
```
