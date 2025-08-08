---
name: brainstorm
description: "Interactive requirements discovery through Socratic dialogue and systematic exploration"
mcp-servers: [sequential, context7]
agents: [brainstorm-prd]
tools: [Read, Write, Edit, MultiEdit, Bash, Grep, Glob, TodoWrite, Task, WebSearch]
---

# /brainstorm - Interactive Requirements Discovery

**Purpose**: Transform ambiguous ideas into concrete specifications through interactive Socratic dialogue and structured requirement discovery

## Usage

```bash
/brainstorm <idea>           # Interactive requirements discovery
/brainstorm brief <topic>    # Generate brief only
/brainstorm prd <topic>      # -> brainstorm-prd agent for full PRD
/brainstorm technical <idea> # Technical focus exploration
```

## Execution Strategy

- **Basic**: Socratic dialogue with progressive requirement crystallization
- **Discovery**: Open-ended exploration and stakeholder identification
- **Exploration**: Deep-dive scenarios and constraint identification  
- **Convergence**: Priority crystallization and requirement finalization
- **Documentation**: Comprehensive brief and optional PRD generation

## MCP Integration

- **Sequential**: Multi-step problem decomposition and reasoning
- **Context7**: Framework expertise and pattern validation

## Examples

```bash
/brainstorm "task management app"          # Basic exploration
/brainstorm technical "distributed cache" # Technical deep-dive
/brainstorm prd "SaaS pricing tool"       # Full PRD generation
/brainstorm brief "mobile app concept"    # Brief documentation only
```

## Agent Routing

- **brainstorm-prd**: Complex project requirements, comprehensive PRD generation, business analysis
