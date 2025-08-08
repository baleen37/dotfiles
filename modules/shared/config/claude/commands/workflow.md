---
name: workflow
description: "Generate structured implementation workflows from PRDs and feature requirements"
mcp-servers: [sequential, context7, playwright]
agents: [system-architect, frontend-developer, backend-engineer]
tools: [Read, Write, Edit, MultiEdit, Bash, Grep, Glob, TodoWrite, Task, WebSearch]
---

# /workflow - Implementation Workflow Generator

**Purpose**: Analyze PRDs and feature specifications to generate comprehensive, step-by-step implementation workflows with expert guidance

## Usage

```bash
/workflow <prd-file>          # Generate workflow from PRD
/workflow frontend <feature>  # -> frontend-developer agent
/workflow backend <feature>   # -> backend-engineer agent
/workflow full-stack <feature> # -> system-architect agent
```

## Execution Strategy

- **Basic**: PRD analysis with step-by-step implementation planning
- **Frontend**: UI/UX focused workflow with component planning
- **Backend**: API and data workflow with service architecture
- **Full-Stack**: Comprehensive workflow with coordinated development
- **Dependency Mapping**: External and internal dependency analysis

## MCP Integration

- **Sequential**: Multi-step workflow planning and systematic analysis
- **Context7**: Framework-specific implementation patterns
- **Playwright**: E2E testing workflow integration

## Examples

```bash
/workflow docs/feature-prd.md          # PRD-based workflow
/workflow frontend "user dashboard"    # Frontend workflow
/workflow backend "payment API"        # Backend workflow
/workflow full-stack "chat system"     # Full-stack workflow
```

## Agent Routing

- **system-architect**: Complex full-stack workflows, system design, architecture planning
- **frontend-developer**: UI/UX workflows, component planning, client-side implementation
- **backend-engineer**: API workflows, database design, service architecture
