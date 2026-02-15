# Agents Directory Codemap

## Responsibility

The `src/agents/` directory defines and configures the multi-agent orchestration system for OpenCode. It creates specialized AI agents with distinct roles, capabilities, and behaviors that work together under an orchestrator to optimize coding tasks for quality, speed, cost, and reliability.

## Design

### Core Architecture

**Agent Definition Interface**
```typescript
interface AgentDefinition {
  name: string;
  description?: string;
  config: AgentConfig;
}
```

All agents follow a consistent factory pattern:
- `createXAgent(model, customPrompt?, customAppendPrompt?)` → `AgentDefinition`
- Custom prompts can fully replace or append to default prompts
- Temperature varies by agent role (0.1-0.7) to balance precision vs creativity

### Agent Classification

**Primary Agent**
- **Orchestrator**: Central coordinator that delegates tasks to specialists

**Subagents** (5 specialized agents)
1. **Explorer** - Codebase navigation and search (temperature: 0.1)
2. **Librarian** - Documentation and library research (temperature: 0.1)
3. **Oracle** - Strategic technical advisor (temperature: 0.1)
4. **Designer** - UI/UX specialist (temperature: 0.7)
5. **Fixer** - Fast implementation specialist (temperature: 0.2)

### Configuration System

**Override Application**
- Model and temperature can be overridden per agent via user config
- Fallback mechanism: Fixer inherits Librarian's model if not configured
- Default models defined in `../config/DEFAULT_MODELS`

**Permission System**
- All agents get `question: 'allow'` by default
- Skill permissions applied via `getSkillPermissionsForAgent()`
- Nested permission structure: `{ question, skill: { ... } }`

**Custom Prompts**
- Loaded via `loadAgentPrompt(name)` from config
- Supports full replacement or append mode
- Applied after default prompt construction

### Agent Specialization Matrix

| Agent | Primary Focus | Tools | Constraints | Temperature |
|-------|--------------|-------|-------------|-------------|
| Explorer | Codebase search | grep, glob, ast_grep_search | Read-only, parallel | 0.1 |
| Librarian | External docs | context7, grep_app, websearch | Evidence-based | 0.1 |
| Oracle | Architecture | Analysis tools | Read-only, advisory | 0.1 |
| Designer | UI/UX | Tailwind, CSS | Visual excellence | 0.7 |
| Fixer | Implementation | Edit/write tools | No research/delegation | 0.2 |

## Flow

### Agent Creation Flow

```
createAgents(config?)
  │
  ├─→ For each subagent:
  │   ├─→ Get model (with fallback for fixer)
  │   ├─→ Load custom prompts
  │   ├─→ Call factory function
  │   ├─→ Apply overrides (model, temperature)
  │   └─→ Apply default permissions
  │
  ├─→ Create orchestrator:
  │   ├─→ Get model
  │   ├─→ Load custom prompts
  │   ├─→ Call factory function
  │   ├─→ Apply overrides
  │   └─→ Apply default permissions
  │
  └─→ Return [orchestrator, ...subagents]
```

### SDK Configuration Flow

```
getAgentConfigs(config?)
  │
  ├─→ createAgents(config)
  │
  ├─→ For each agent:
  │   ├─→ Extract config
  │   ├─→ Add description
  │   ├─→ Add MCP list via getAgentMcpList()
  │   ├─→ Set mode:
  │   │   ├─→ 'primary' for orchestrator
  │   │   └─→ 'subagent' for others
  │   └─→ Map to Record<string, SDKAgentConfig>
  │
  └─→ Return config object
```

### Orchestrator Delegation Flow

```
User Request
    │
    ↓
Understand (parse requirements)
    │
    ↓
Path Analysis (quality, speed, cost, reliability)
    │
    ↓
Delegation Check
    │
    ├─→ Need to discover unknowns? → @explorer
    ├─→ Complex/evolving APIs? → @librarian
    ├─→ High-stakes decisions? → @oracle
    ├─→ User-facing polish? → @designer
    ├─→ Clear spec, parallel tasks? → @fixer
    └─→ Simple/quick? → Do yourself
    │
    ↓
Parallelize (if applicable)
    │
    ├─→ Multiple @explorer searches?
    ├─→ @explorer + @librarian research?
    └─→ Multiple @fixer instances?
    │
    ↓
Execute & Integrate
    │
    ↓
Verify (lsp_diagnostics, tests)
```

### Agent Interaction Patterns

**Research → Implementation Chain**
```
Orchestrator
    ↓ delegates to
Explorer (find files) + Librarian (get docs)
    ↓ provide context to
Fixer (implement changes)
```

**Advisory Pattern**
```
Orchestrator
    ↓ delegates to
Oracle (architecture decision)
    ↓ provides guidance to
Orchestrator (implements or delegates to Fixer)
```

**Design Pattern**
```
Orchestrator
    ↓ delegates to
Designer (UI/UX implementation)
    ↓ (Designer may use Fixer for parallel tasks)
```

## Integration

### Dependencies

**External Dependencies**
- `@opencode-ai/sdk` - Core agent configuration types (`AgentConfig`)
- `@modelcontextprotocol/sdk` - MCP protocol (via config)

**Internal Dependencies**
- `../config` - Agent overrides, default models, MCP lists, custom prompts
- `../cli/skills` - Skill permission system (`getSkillPermissionsForAgent`)

### Consumers

**Direct Consumers**
- `src/index.ts` - Main plugin entry point exports `getAgentConfigs()`
- `src/cli/index.ts` - CLI entry point uses agent configurations

**Indirect Consumers**
- OpenCode SDK - Consumes agent configurations via `getAgentConfigs()`
- MCP servers - Agents configured with specific MCP tool lists

### Configuration Integration

**Agent Override Config**
```typescript
interface AgentOverrideConfig {
  model?: string;
  temperature?: number;
  skills?: string[];
}
```

**Plugin Config**
```typescript
interface PluginConfig {
  agents?: {
    [agentName: string]: AgentOverrideConfig;
  };
  // ... other config
}
```

### Skill System Integration

Each agent gets skill-specific permissions:
- Permissions loaded from `../cli/skills`
- Applied via nested `skill` key in permissions object
- Respects user-configured skill lists if provided

### MCP Integration

Agents are configured with specific MCP tool lists:
- `getAgentMcpList(agentName, config)` returns tool list
- MCP tools enable agent capabilities (e.g., grep_app for Librarian)
- Configured per agent based on role and needs

## Key Design Decisions

1. **Factory Pattern**: Consistent agent creation with customization hooks
2. **Temperature Gradient**: 0.1 (precision) → 0.7 (creativity) based on role
3. **Read-Only Specialists**: Explorer, Librarian, Oracle don't modify code
4. **Execution Specialist**: Fixer is the only agent that makes code changes
5. **Fallback Model**: Fixer inherits Librarian's model for backward compatibility
6. **Permission Defaults**: All agents get `question: 'allow'` for smooth UX
7. **Custom Prompt Flexibility**: Full replacement or append mode for customization
8. **Parallel-First**: Orchestrator encouraged to parallelize independent tasks
9. **Evidence-Based Research**: Librarian must provide sources and citations
10. **Visual Excellence Priority**: Designer prioritizes aesthetics over code perfection

## File Structure

```
src/agents/
├── index.ts          # Main entry point, agent factory registry, config application
├── orchestrator.ts   # Orchestrator agent definition and delegation workflow
├── explorer.ts       # Codebase navigation specialist
├── librarian.ts      # Documentation and library research specialist
├── oracle.ts         # Strategic technical advisor
├── fixer.ts          # Fast implementation specialist
└── designer.ts       # UI/UX design specialist
```

## Extension Points

**Adding New Agents**
1. Create `src/agents/newagent.ts` with `createNewAgent()` factory
2. Add to `SUBAGENT_FACTORIES` in `index.ts`
3. Add to `SUBAGENT_NAMES` in `../config`
4. Configure default model in `../config/DEFAULT_MODELS`
5. Add MCP configuration in `../config/agent-mcps`
6. Add skill permissions in `../cli/skills`

**Customizing Existing Agents**
- Override model/temperature via plugin config
- Replace or append to prompts via `loadAgentPrompt()`
- Configure MCP tools via agent-mcps config
- Adjust skill permissions via skills config
