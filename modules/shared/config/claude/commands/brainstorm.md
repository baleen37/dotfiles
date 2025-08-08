---
name: brainstorm
description: "Transform vague ideas into concrete requirements through codebase analysis"
mcp-servers: [sequential, context7]
agents: [system-architect, frontend-developer, backend-engineer]
tools: [Read, Grep, Glob, TodoWrite, Task]
---

# /brainstorm - Smart Requirements Discovery

**Purpose**: Convert fuzzy ideas into actionable specifications using codebase intelligence

## Usage

```bash
/brainstorm <idea>           # Smart discovery with codebase analysis
/brainstorm --brief <idea>   # Quick requirements without interaction
/brainstorm --tech <idea>    # Technical architecture focus
```

## Execution Strategy

- **Smart**: Codebase scan → intelligent questions → structured output
- **Brief**: Direct conversion to user stories and acceptance criteria
- **Technical**: Architecture decisions and implementation roadmap focus

## 2-Phase Process

### Phase 1: Codebase Intelligence

- Scan project files for tech stack, patterns, and architecture
- Detect existing tools, frameworks, and conventions
- Identify integration points and constraints
- Present findings: "Based on your codebase using [X, Y, Z], I see [patterns]"

### Phase 2: Smart Discovery

Generate structured deliverables based on complexity:

**Simple Ideas**: Direct conversion to:

- User stories with acceptance criteria
- Priority queue (P0/P1/P2)
- Next steps

**Complex Ideas**: Add strategic questions:

- Platform choice (Web/Mobile/CLI)
- Scale consideration (Personal/Department/Public)
- Priority focus (Speed/Stability/Features)

## MCP Integration

- **Sequential**: Systematic thinking through requirement analysis
- **Context7**: Tech stack validation and framework best practices

## Examples

```bash
/brainstorm "team task tracker"     # Full discovery with codebase scan
/brainstorm --tech "user auth"      # Technical implementation focus  
/brainstorm --brief "mobile idea"   # Quick spec without questions
```

## Agent Routing

- **system-architect**: Complex systems requiring architectural decisions
- **frontend-developer**: UI/UX focused ideas and component planning
- **backend-engineer**: API design, data modeling, service architecture

## Workflow

1. **Codebase Scan**: Analyze existing code → present tech stack findings
2. **Smart Discovery**: Generate appropriate output based on idea complexity
