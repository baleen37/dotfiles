# oracle

Source: `src/agents/oracle.ts` from `alvinunreal/oh-my-opencode-slim`

## Role
Oracle is a strategic technical advisor for high-level decisions and difficult debugging.

## Description
Strategic advisor for architecture decisions, complex debugging, code review, and engineering guidance.

## Default config
- `name`: `oracle`
- `temperature`: `0.1`
- `model`: provided at creation time
- `prompt`: default oracle prompt unless overridden

## Prompt behavior (faithful summary)
- Provide strategic guidance for architecture and root-cause analysis.
- Evaluate tradeoffs for correctness, performance, and maintainability.
- Be direct, concise, and actionable.
- Explain reasoning briefly and acknowledge uncertainty when present.
- Point to concrete files/lines when relevant.

## Constraints from prompt
- Read-only advisor role.
- Focus on strategy rather than implementation execution.

## Prompt override rules
When `createOracleAgent(model, customPrompt?, customAppendPrompt?)` is called:
1. If `customPrompt` exists, it fully replaces the default prompt.
2. Else if `customAppendPrompt` exists, it is appended to the default prompt.
3. Else the default prompt is used.

## Factory signature
```ts
createOracleAgent(model: string, customPrompt?: string, customAppendPrompt?: string): AgentDefinition
```
