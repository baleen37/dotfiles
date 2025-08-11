---
name: implement
description: "Feature and code implementation with intelligent agent routing and framework expertise"
mcp-servers: [context7, sequential, playwright]
agents: [frontend-developer, backend-engineer, system-architect]
tools: [Read, Write, Edit, MultiEdit, Bash, Grep, Glob, TodoWrite, Task]
---

# /implement - Feature Implementation

**Purpose**: Implement features, components, and code functionality with automatic expert activation and framework best practices

## Usage

```bash
/implement <description>         # Basic feature implementation
/implement api <description>     # -> backend-engineer agent
/implement component <description> # -> frontend-developer agent
```

## Execution Strategy

- **Basic**: Implement features using existing patterns and conventions
- **Framework-Specific**: Apply technology-specific best practices via Context7
- **Multi-file**: Coordinate complex implementations across multiple files
- **Quality Assurance**: Include testing and validation recommendations

## MCP Integration

- **Context7**: Framework documentation and best practices (React, Vue, Node.js, etc.)
- **Sequential**: Complex feature breakdown and systematic implementation
- **Playwright**: End-to-end testing and validation of implemented features

## Examples

```bash
/implement user authentication    # Basic auth implementation
/implement api user management   # Backend API with validation
/implement component UserProfile # Frontend component
```

## Agent Routing

- **frontend-developer**: UI components, client-side logic, React/Vue patterns
- **backend-engineer**: APIs, services, database integration, Node.js/Python
- **system-architect**: Complex features requiring architectural decisions