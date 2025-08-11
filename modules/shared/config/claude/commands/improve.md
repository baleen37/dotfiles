---
name: improve
description: "Apply systematic improvements to code quality, performance, and maintainability"
mcp-servers: [sequential, context7]
agents: [performance-engineer, system-architect]
tools: [Read, Grep, Glob, Edit, MultiEdit, TodoWrite, Task]
---

# /improve - Code Improvement

**Purpose**: Apply systematic improvements to code quality, performance, and maintainability through intelligent analysis and targeted refactoring

## Usage

```bash
/improve [target]            # General code quality improvements
/improve performance [path]  # -> performance-engineer agent
/improve architecture [path] # -> system-architect agent
```

## Execution Strategy

- **Basic**: Code quality improvements with safe refactoring
- **Performance**: Bottleneck analysis and optimization recommendations
- **Architecture**: Structural improvements and design pattern application
- **Validation**: Comprehensive testing and quality verification

## MCP Integration

- **Sequential**: Multi-step improvement planning and systematic analysis
- **Context7**: Framework-specific best practices and optimization patterns

## Examples

```bash
/improve src/components      # General improvements
/improve performance api/    # Performance optimization
/improve architecture core/  # Architectural refactoring
```

## Agent Routing

- **performance-engineer**: Performance bottlenecks, optimization, scalability improvements
- **system-architect**: Structural improvements, design patterns, architectural refactoring