# orchestrator

Source: `src/agents/orchestrator.ts` from `alvinunreal/oh-my-opencode-slim`

## Role
Primary coding orchestrator that balances quality, speed, cost, and reliability by selectively delegating to specialists.

## Types and API

### `AgentDefinition`
```ts
interface AgentDefinition {
  name: string;
  description?: string;
  config: AgentConfig;
}
```

### Factory
```ts
createOrchestratorAgent(model: string, customPrompt?: string, customAppendPrompt?: string): AgentDefinition
```

## Default config
- `name`: `orchestrator`
- `temperature`: `0.1`
- `model`: provided at creation time
- `description`: orchestrates specialist delegation for quality/speed/cost balance
- `prompt`: default orchestrator prompt unless overridden

## Prompt structure (faithful summary)
The prompt is organized in three major sections:

1. `<Role>`
   - Defines objective: optimize outcomes through selective delegation.

2. `<Agents>`
   - Describes when to delegate (and when not) to:
     - `@explorer` (parallel discovery/search)
     - `@librarian` (official docs/API research)
     - `@oracle` (high-stakes strategy/debugging)
     - `@designer` (UI/UX polish)
     - `@fixer` (parallel execution of clear tasks)
   - Includes a delegation efficiency checklist and fixer parallelization guidance.

3. `<Workflow>` and `<Communication>`
   - Workflow sequence: understand request, analyze path, delegation check, parallelize, execute, verify.
   - Verification mentions diagnostics and requirement checks.
   - Communication constraints: ask targeted clarifying questions when needed, stay concise, avoid flattery, provide honest pushback when approach is problematic.

## Prompt override rules
When `createOrchestratorAgent(model, customPrompt?, customAppendPrompt?)` is called:
1. If `customPrompt` exists, it fully replaces the default prompt.
2. Else if `customAppendPrompt` exists, it is appended to the default prompt.
3. Else the default prompt is used.
