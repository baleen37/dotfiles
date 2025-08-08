---
name: improve
description: "Apply systematic improvements to code quality, performance, and maintainability"
mcp-servers: [sequential, context7]
agents: [performance-engineer, security-auditor, system-architect]
tools: [Read, Grep, Glob, Edit, MultiEdit, TodoWrite, Task]
---

# /improve - Code Improvement

**Purpose**: Apply systematic improvements to code quality, performance, and maintainability through intelligent analysis and targeted refactoring

## Usage

```bash
/improve [target]            # General code quality improvements
/improve performance [path]  # -> performance-engineer agent
/improve security [path]     # -> security-auditor agent
/improve architecture [path] # -> system-architect agent
```

## Execution Strategy

- **Basic**: Code quality improvements with safe refactoring
- **Performance**: Bottleneck analysis and optimization recommendations
- **Security**: Vulnerability fixes and secure coding practices
- **Architecture**: Structural improvements and design pattern application
- **Validation**: Comprehensive testing and quality verification

## MCP Integration

- **Sequential**: Multi-step improvement planning and systematic analysis
- **Context7**: Framework-specific best practices and optimization patterns

## Examples

```bash
/improve src/components      # General improvements
/improve performance api/    # Performance optimization
/improve security auth/      # Security hardening
/improve architecture core/  # Architectural refactoring
```

## Agent Routing

- **performance-engineer**: Performance bottlenecks, optimization, scalability improvements
- **security-auditor**: Security vulnerabilities, secure coding practices, data protection
- **system-architect**: Structural improvements, design patterns, architectural refactoring
