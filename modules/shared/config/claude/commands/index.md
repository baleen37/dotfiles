---
name: index
description: "Generate comprehensive project documentation and knowledge base"
mcp-servers: [sequential, context7]
agents: [technical-writer]
tools: [Read, Grep, Glob, Bash, Write, TodoWrite, Task]
---

# /index - Project Documentation

**Purpose**: Create and maintain comprehensive project documentation, indexes, and knowledge bases with intelligent organization

## Usage

```bash
/index [target]              # Generate project documentation
/index api [path]            # API documentation generation
/index structure [path]      # Project structure documentation
/index readme [path]         # -> technical-writer agent
```

## Execution Strategy

- **Basic**: Project structure analysis with comprehensive documentation generation
- **API**: RESTful API documentation with request/response examples
- **Structure**: Project organization and architecture documentation
- **README**: User-facing documentation with setup and usage guides
- **Cross-Reference**: Navigation systems with intelligent linking

## MCP Integration

- **Sequential**: Multi-step documentation planning and systematic analysis
- **Context7**: Framework-specific documentation patterns and standards

## Examples

```bash
/index                       # Full project documentation
/index api src/              # API documentation
/index structure             # Project structure docs
/index readme                # README generation
```

## Agent Routing

- **technical-writer**: Comprehensive documentation projects, README generation, user guides
