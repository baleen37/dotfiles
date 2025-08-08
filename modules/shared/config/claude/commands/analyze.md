---
name: analyze
description: "Code quality, security, and performance analysis with intelligent MCP and agent routing"
mcp-servers: [sequential, context7]
agents: [security-auditor, performance-optimizer]
tools: [Read, Bash, Grep, Glob, Write, Task]
---

# /analyze - Code Analysis

**Purpose**: Analyze code quality, security vulnerabilities, and performance issues with intelligent specialist routing

## Usage

```bash
/analyze [path]               # General code quality analysis
/analyze security [path]      # -> security-auditor agent
/analyze performance [path]   # -> performance-optimizer agent
```

## Execution Strategy

- **Basic**: Code quality checks (linting, structure, duplication)
- **Security**: Delegates to security-auditor agent for vulnerability assessment
- **Performance**: Delegates to performance-optimizer agent for bottleneck analysis
- **Complex Analysis**: Automatically routes to appropriate specialist agents

## MCP Integration

- **Sequential**: Multi-step analysis workflows
- **Context7**: Framework-specific best practices and patterns

## Examples

```bash
/analyze                     # Full project analysis
/analyze src/auth           # Directory-specific analysis
/analyze security           # Security-focused analysis
/analyze performance api/   # Performance-focused analysis
```

## Agent Routing

- **security-auditor**: Triggered by "security", vulnerability patterns, auth code
- **performance-optimizer**: Triggered by "performance", bottleneck patterns, optimization needs
- **Auto-detection**: Intelligent routing based on code patterns and analysis scope
